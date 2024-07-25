// ignore_for_file: unnecessary_cast

import 'dart:async';

import 'package:kickassanime/src/kickassanime_extractor.dart';
import 'package:kickassanime/src/preferences.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

class KickAssAnime extends HttpSource {
  KickAssAnime();

  @override
  int get id => 2081771513481539599;

  @override
  final String name = 'KickAssAnime';

  @override
  final String lang = 'en';

  @override
  String get baseUrl => this
      .preferences
      .getString(Preferences.pref_domain_key, Preferences.pref_domain_default)!;

  String get apiUrl => '${this.baseUrl}/api/show';

  // ============================== HomePage ===================================

  @override
  List<HomePageRequest> getHomePageRequestList() {
    return [
      HomePageRequest(title: 'Popular', url: '/popular'),
      HomePageRequest(title: 'Latest Sub', url: '/recent?type=sub'),
      HomePageRequest(title: 'Latest Dub', url: '/recent?type=dub'),
      HomePageRequest(title: 'Latest Donghua', url: '/recent?type=chinese'),
    ];
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    final String url = buildString((it) {
      it as StringBuffer;
      it.write(apiUrl);
      it.write(request.url);
      it.write(request.title == 'Popular' ? '?' : '&');
      it.write('page=$page');
    });

    return GET(url);
  }

  @override
  FutureOr<HomePage> homePageParse(HomePageRequest request, Response response) {
    return response.body.json((json) {
      final bool hasNext;
      if (request.title == 'Popular') {
        final int pageCount = json['page_count'];
        final page = StringUtils.toIntOrNull(
                response.request.url.queryParameters['page']) ??
            0;
        hasNext = pageCount > page;
      } else {
        hasNext = json['hadNext'] as bool;
      }

      return HomePage.fromRequest(
        reqeust: request,
        list: mediaListFromJson(json),
        hasNextPage: hasNext,
      );
    });
  }

  List<IMedia> mediaListFromJson(dynamic json) {
    final useEnglish = this.preferences.getBool(
        Preferences.pref_use_english_key,
        Preferences.PREF_USE_ENGLISH_DEFAULT)!;
    return ListUtils.mapList(json['result'] as List, (json) {
      json as Map<String, dynamic>;
      List<String>? genres;
      if (json.containsKey('genres')) {
        genres = ListUtils.mapList(json['genres'], (it) => it.toString());
      }

      final String title;
      final String? englishTitle =
          json.containsKey('title_en') ? json['title_en'] : null;
      if (useEnglish && englishTitle != null) {
        title = englishTitle;
      } else {
        title = json['title'];
      }

      return IMedia(
        title: title,
        url: '/${json['slug']}',
        description: json['synopsis'],
        poster: '${this.baseUrl}${Poster.fromJson(json['poster'])!.poster}',
        format: getFormat(json['type']),
        genres: genres,
      );
    });
  }

  // ============================== MediaDetails ===================================

  @override
  Request mediaDetailsRequest(IMedia media) =>
      GET('${this.apiUrl}/${media.url}');

  @override
  IMedia mediaDetailsParse(Response response) {
    return response.body.json((json) {
      json as Map<String, dynamic>;
      final mediaDetails = IMedia();

      mediaDetails.title = (json['title'] as String);

      String? banner = Poster.fromJson(json["banner"])?.banner;
      if (banner != null) {
        mediaDetails.banner = (this.baseUrl + banner);
      }
      String? poster = Poster.fromJson(json["poster"])?.poster;
      if (poster != null) {
        mediaDetails.poster = (this.baseUrl + poster);
      }

      mediaDetails
        ..status = getStatus(json['status'])
        ..format = getFormat(json['type'])
        ..description = json['synopsis']
        ..addOtherTitle(json['title_original'] as String?)
        ..genres = ListUtils.mapList(json['genres'], (it) => it.toString());

      return mediaDetails;
    });
  }

  // ============================== MediaContent ===================================

  @override
  Future<List<IMediaContent>> getMediaContentList(IMedia media) async {
    print(this.apiUrl + media.url + '/language');
    final List<String> languages = await this
        .client
        .newCall(GET(this.apiUrl + media.url + '/language'))
        .execute()
        .then((Response response) =>
            response.body.json((json) => json['result']));

    final prefLang = this.preferences.getString(
        Preferences.pref_audio_lang_key, Preferences.pref_audio_lang_default)!;

    final lang = languages.firstWhere((element) => element == prefLang,
        orElse: () => Preferences.pref_audio_lang_default);

    final List<IMediaContent> episodes = [];
    final first = await getEpisodeResponse(media, 1, lang);

    episodes.addAll(first.episodes);

    for (var i = 1; i < first.total; i++) {
      final episodeResponse = await getEpisodeResponse(media, i, lang);

      episodes.addAll(episodeResponse.episodes);
    }

    return episodes;
  }

  Request episodeListRequest(IMedia media, int page, String lang) =>
      GET("$apiUrl/${media.url}/episodes?ep=1&page=$page&lang=$lang");

  Future<EpisodeResponse> getEpisodeResponse(
      IMedia media, int page, String lang) {
    return client
        .newCall(episodeListRequest(media, page, lang))
        .execute()
        .then((response) => episodeListParse(media, response));
  }

  EpisodeResponse episodeListParse(IMedia media, Response response) {
    return response.body.json((json) {
      final total = (json['pages'] as List).length;
      final episodes = ListUtils.mapList(json['result'] as List, (json) {
        final num number = json['episode_number'];
        return IMediaContent(
          number: number.toInt(),
          name: json['title'],
          url: '${media.url}/ep-$number-${json['slug'].toString()}',
          image: this.baseUrl + Poster.fromJson(json['thumbnail'])!.thumbnail,
        );
      });

      return EpisodeResponse(episodes: episodes, total: total);
    });
  }

  @override
  FutureOr<List<IMediaContent>> mediaContentListParse(Response response) {
    throw UnsupportedOperationException();
  }

  // ============================== MediaLinks ===================================

  @override
  Request mediaLinkListRequest(IMediaContent content) =>
      GET('${this.apiUrl}/${content.url.replaceFirst("/ep-", "/episode/ep-")}');

  @override
  FutureOr<List<MediaLink>> mediaLinkListParse(Response response) {
    final hosterselection = this.preferences.getStringList(
        Preferences.pref_hoster_key, Preferences.pref_hoster_default)!;

    return response.body.json((json) {
      final List<MediaLink> links = [];
      final List<dynamic> servers = json['servers'];

      for (var server in servers) {
        final String name = server['name'];
        if (hosterselection.contains(name)) {
          links.add(MediaLink(
            name: name,
            url: server['src'],
            extra: {'shortName': server['shortName'].toString()},
          ));
        }
      }

      return links;
    });
  }

  // ============================== MediaAsset ===================================

  KickAssAnimeExtractor get extractor =>
      KickAssAnimeExtractor(this.client, this.headers);

  @override
  Future<MediaAsset> mediaAssetParse(MediaLink link, Response response) {
    return KickAssAnimeExtractor(this.client, this.headers)
        .extract(link, response);
  }

  // ============================== Search ===================================

  @override
  FilterList getFilterList() => FilterList([]);

  @override
  Request searchPageRequest(int page, String query, FilterList filters) {
    final newHeaders = this
        .headers
        .newBuilder()
        .add("Accept", "application/json, text/plain, */*")
        .add("Host", Uri.parse(this.baseUrl).host)
        .add("Referer", "${this.baseUrl}/anime")
        .build();

    final body = RequestBody.fromMap(
      {"query": query, "page": page},
      RequestBodyType.JSON,
    );

    return POST("$baseUrl/api/fsearch", headers: newHeaders, body: body);
  }

  @override
  FutureOr<SearchPage> searchPageParse(Response response) {
    final page =
        StringUtils.toIntOrNull(response.request.url.queryParameters['page']) ??
            1;
    return response.body.json((json) {
      return SearchPage(
          hasNextPage: json['maxPage'] > page, list: mediaListFromJson(json));
    });
  }

  // ============================== Utils ===================================

  MediaFormat getFormat(String str) {
    if (str == 'tv') {
      return MediaFormat.anime;
    } else if (str == 'ona') {
      return MediaFormat.ona;
    } else if (str == 'movie') {
      return MediaFormat.animeMovie;
    } else {
      return MediaFormat.anime;
    }
  }

  Status getStatus(String str) {
    if (str == 'currently_airing') {
      return Status.ongoing;
    } else if (str == 'finished_airing') {
      return Status.completed;
    } else {
      return Status.unknown;
    }
  }
}

class EpisodeResponse {
  final List<IMediaContent> episodes;
  final int total;

  EpisodeResponse({required this.episodes, required this.total});
}

class Poster {
  final String format;
  final String? sm;
  final String? hq;

  Poster({
    required this.format,
    required this.sm,
    required this.hq,
  });

  static Poster? fromJson(dynamic json) {
    if (AppUtils.isNotNull(json)) {
      return Poster(
        format: (json["formats"] as List).last.toString(),
        sm: json["sm"],
        hq: json["hq"],
      );
    } else {
      return null;
    }
  }

  String get poster => '/image/poster/${hq ?? sm ?? ''}.$format';
  String get banner => '/image/banner/${hq ?? sm ?? ''}.$format';
  String get thumbnail => '/image/thumbnail/${sm ?? hq ?? ''}.$format';
}
