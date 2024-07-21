// ignore_for_file: unnecessary_cast

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

  @override
  List<HomePageRequest> homePageRequests() {
    return [
      HomePageRequest(title: 'Popular', data: '${this.apiUrl}/popular'),
      HomePageRequest(
          title: 'Latest Sub', data: '${this.apiUrl}/recent?type=sub'),
      HomePageRequest(
          title: 'Latest Dub', data: '${this.apiUrl}/recent?type=dub'),
      HomePageRequest(
          title: 'Latest Donghua', data: '${this.apiUrl}/recent?type=chinese'),
    ];
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    final String url = buildString((it) {
      it as StringBuffer;
      it.write(request.data);
      it.write(request.title == 'Popular' ? '?' : '&');
      it.write('page=$page');
    });

    return GET(url);
  }

  @override
  HomePage homePageParse(HomePageRequest request, Response response) {
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
        list: previewListFromJson(json),
        hasNextPage: hasNext,
      );
    });
  }

  List<MediaPreview> previewListFromJson(dynamic json) {
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
      if (useEnglish && englishTitle != null && englishTitle.isNotEmpty) {
        title = englishTitle;
      } else {
        title = json['title'];
      }

      return MediaPreview(
        title: title,
        url: json['slug'],
        description: json['synopsis'],
        poster: '${this.baseUrl}${Poster.fromJson(json['poster'])!.poster}',
        format: getFormat(json['type']),
        generes: genres,
      );
    });
  }

  @override
  Request mediaDetailsRequest(MediaDetails mediaDetails) =>
      GET('${this.apiUrl}/${mediaDetails.url}');

  @override
  MediaDetails mediaDetailsParse(Response response) {
    return response.body.json((json) {
      json as Map<String, dynamic>;
      final mediaDetails = MediaDetails();

      mediaDetails.url =
          AppUtils.getUrlWithoutDomain(response.request.url.toString());

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

  @override
  Future<MediaContent> mediaContentParseAsync(Response response) async {
    final json = response.body.json();
    final String slug = json['slug'];
    final List<String> locales = json['locales'];

    final prefLang = this.preferences.getString(
        Preferences.pref_audio_lang_key, Preferences.pref_audio_lang_default)!;
    final lang = locales.firstWhere((element) => element == prefLang,
        orElse: () => locales.first);

    final List<Episode> episodes = [];
    final first =
        await getEpisodeRsponse(episodeListRequest(slug, 1, lang), slug);

    episodes.addAll(first.episodes);

    for (var i = 1; i < first.total; i++) {
      final episodeResponse =
          await getEpisodeRsponse(episodeListRequest(slug, i + 1, lang), slug);

      episodes.addAll(episodeResponse.episodes);
    }

    return Anime(episodes: episodes);
  }

  Request episodeListRequest(String url, int page, String lang) =>
      GET("$apiUrl/$url/episodes?ep=1&page=$page&lang=$lang");

  EpisodeResponse episodeListParse(String url, Response response) {
    return response.body.json((json) {
      final total = (json['pages'] as List).length;
      final episodes = ListUtils.mapList(json['result'] as List, (json) {
        final num number = json['episode_number'];
        return Episode(
          number: number.toInt(),
          name: json['title'],
          data: '$url/ep-$number-${json['slug'].toString()}',
          image: this.baseUrl + Poster.fromJson(json['thumbnail'])!.thumbnail,
        );
      });

      return EpisodeResponse(episodes: episodes, total: total);
    });
  }

  Future<EpisodeResponse> getEpisodeRsponse(
      Request episodeRequest, String url) {
    return this.client.newCall(episodeRequest).execute().then((response) {
      return episodeListParse(url, response);
    });
  }

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
  SearchPage searchPageParse(Response response) {
    final page =
        StringUtils.toIntOrNull(response.request.url.queryParameters['page']) ??
            1;
    return response.body.json((json) {
      return SearchPage(
          hasNextPage: json['maxPage'] > page, list: previewListFromJson(json));
    });
  }

  @override
  Request mediaLinksRequest(String url) =>
      GET('${this.apiUrl}/${url.replaceFirst("/ep-", "/episode/ep-")}');

  @override
  List<MediaLink> medialinksParse(Response response) {
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
            data: server['src'],
            extra: {'shortName': server['shortName'].toString()},
          ));
        }
      }

      return links;
    });
  }

  @override
  Future<Media?> getMedia(MediaLink link) {
    return KickAssAnimeExtractor(this.client, this.headers).extract(link);
  }

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
  final List<Episode> episodes;
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
