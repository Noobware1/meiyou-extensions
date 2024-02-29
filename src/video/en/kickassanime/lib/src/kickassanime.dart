// ignore_for_file: unnecessary_this, unnecessary_cast

import 'dart:convert';

import 'package:kickassanime/src/kickassanime_extractor.dart';
import 'package:kickassanime/src/preferences.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';

import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

class KickAssAnime extends HttpSource {
  KickAssAnime(NetworkHelper network) : super(network);

  @override
  int get id => 2081771513481539599;

  @override
  String get name => 'KickAssAnime';

  @override
  String get lang => 'en';

  @override
  String get baseUrl => this
      .preferences
      .getString(Preferences.PREF_DOMAIN_KEY, Preferences.PREF_DOMAIN_DEFAULT)!;

  String get apiUrl => '${this.baseUrl}/api/show';

  @override
  Iterable<HomePageData> get homePageList => HomePageData.fromMap({
        'Popular': '${this.apiUrl}/popular',
        'Latest Sub': '${this.apiUrl}/recent?type=sub',
        'Latest Dub': '${this.apiUrl}/recent?type=dub',
        'Latest Donghua': '${this.apiUrl}/recent?type=chinese',
      });

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    String url = request.data;
    if (request.name == 'Popular') {
      url += '?page=$page';
    } else {
      url += '&page=$page';
    }
    return GET(url);
  }

  @override
  HomePage homePageParse(int page, HomePageRequest request, Response response) {
    final json = response.body.json();
    final bool hasNext;
    if (request.name == 'Popular') {
      final int pageCount = json['page_count'];
      final page = StringUtils.toIntOrNull(
              response.request.url.queryParameters['page']) ??
          0;
      hasNext = pageCount > page;
    } else {
      hasNext = json['hadNext'] as bool;
    }

    return HomePage(
      data: HomePageList(name: request.name, data: searchListFromJson(json)),
      page: page,
      hasNextPage: hasNext,
    );
  }

  @override
  FilterList getFilterList() => FilterList([]);

  @override
  List<SearchResponse> searchParse(Response response) {
    return response.body.json((json) => searchListFromJson(json));
  }

  List<SearchResponse> searchListFromJson(dynamic json) {
    final useEnglish = this.preferences.getBool(
        Preferences.PREF_USE_ENGLISH_KEY,
        Preferences.PREF_USE_ENGLISH_DEFAULT)!;

    return ListUtils.mapList(json['result'] as List, (json) {
      final List<String>? genres = runCatching(
        () => ListUtils.mapList(json['genres'], (it) => it.toString()),
      ).getOrNull();

      final String title;
      final String englishTitle = json['title_en'];
      if (englishTitle.isNotEmpty && useEnglish) {
        title = englishTitle;
      } else {
        title = json['title'];
      }

      return SearchResponse(
          title: title,
          url: json['slug'],
          description: json['synopsis'],
          current: StringUtils.toIntOrNull(json['episode_number'].toString()),
          poster: '${this.baseUrl}${Poster.fromJson(json["poster"])!.poster}',
          type: getType(json['type']),
          generes: genres);
    });
  }

  @override
  Request searchRequest(int page, String query, FilterList filters) {
    final newHeaders = this
        .headers
        .newBuilder()
        .add("Accept", "application/json, text/plain, */*")
        .add("Host", Uri.parse(this.baseUrl).host)
        .add("Referer", "${this.baseUrl}/anime")
        .build();

    final body = RequestBody.fromString(jsonEncode({
      "query": query,
      "page": page,
    }));

    return POST("$baseUrl/api/fsearch", newHeaders, body);
  }

  @override
  MediaDetails mediaDetailsParse(Response response) {
    return response.body.json((json) {
      final MediaDetails media = MediaDetails();

      final Map<String, dynamic> data = {
        'url': json['watch_uri'] as String,
        'locales': json['locales'] as List,
      };
      media.url = jsonEncode(data);

      media.startDate =
          DateTime.tryParse(StringUtils.valueToString(json['start_date']));
      media.endDate =
          DateTime.tryParse(StringUtils.valueToString(json['end_date']));

      final banner = Poster.fromJson(json["banner"])?.banner;
      if (banner != null) {
        media.bannerImage = this.baseUrl + banner;
      }

      media.status = getShowStatus(json['status']);

      media.duration = Duration(
        milliseconds: StringUtils.toInt(json['episode_duration'].toString()),
      );
      final otherTitle = json['title_original'] as String?;
      if (otherTitle != null) {
        media.otherTitles = [otherTitle];
      }

      return media;
    });
  }

  @override
  Request mediaDetailsRequest(SearchResponse searchResponse) =>
      GET('${this.apiUrl}/${searchResponse.url}');

  @override
  Future<MediaDetails> getMediaDetails(SearchResponse searchResponse) async {
    final request = mediaDetailsRequest(searchResponse);
    final MediaDetails media = await this
        .client
        .newCall(request)
        .execute()
        .then((response) => mediaDetailsParse(response));
    media.copyFromSearchResponse(searchResponse);

    media.mediaItem = await getAnime(media);

    return media;
  }

  Request episodeListRequest(String url, int page, String lang) =>
      GET("$apiUrl$url/episodes?page=$page&lang=$lang");

  EpisodeResponse episodeListParse(String url, Response response) {
    return response.body.json((json) {
      final total = (json['pages'] as List).length;
      final episodes = ListUtils.mapList(json['result'] as List, (json) {
        final int number = json['episode_number'];
        return Episode(
          episode: number,
          name: json['title'],
          data: '$url/ep-$number-${json['slug'].toString()}',
          posterImage:
              this.baseUrl + Poster.fromJson(json['thumbnail'])!.thumbnail,
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

  Future<Anime> getAnime(MediaDetails media) async {
    final decoded = jsonDecode(media.url);
    final String url = decoded['url'];
    final List<String> locales =
        ListUtils.mapList(decoded['locales'], (e) => e.toString());
    final prefLang = this.preferences.getString(
        Preferences.PREF_AUDIO_LANG_KEY, Preferences.PREF_AUDIO_LANG_DEFAULT)!;
    final lang = locales.firstWhere((element) => element == prefLang,
        orElse: () => locales.first);

    final List<Episode> episodes = [];

    final first =
        await getEpisodeRsponse(episodeListRequest(url, 1, lang), url);

    episodes.addAll(first.episodes);

    for (var i = 1; i < first.total; i++) {
      final episodeResponse =
          await getEpisodeRsponse(episodeListRequest(url, i + 1, lang), url);

      episodes.addAll(episodeResponse.episodes);
    }

    return Anime(episodes: episodes);
  }

  @override
  MediaItem? mediaItemParse(SearchResponse searchResponse, Response response) {
    throw UnsupportedError('Not Used');
  }

  @override
  Request? mediaItemRequest(SearchResponse searchResponse, Response response) {
    throw UnsupportedError('Not Used');
  }

  @override
  List<ExtractorLink> linksParse(Response response) {
    final hosterSelection = this.preferences.getStringList(
        Preferences.PREF_HOSTER_KEY, Preferences.PREF_HOSTER_DEFAULT)!;

    return response.body.json((json) {
      final List<ExtractorLink> links = [];
      final servers = json['servers'] as List;

      for (var server in servers) {
        final String name = server['name'];
        if (hosterSelection.contains(name)) {
          links.add(ExtractorLink(
            name: name,
            url: server['src'],
            extra: {'shortName': server['shortName'].toString()},
          ));
        }
      }

      return links;
    });
  }

  @override
  Request linksRequest(String url) =>
      GET(this.apiUrl + url.replaceFirst("/ep-", "/episode/ep-"));

  @override
  Future<Video> getMedia(ExtractorLink link) {
    return KickAssAnimeExtractor(this.client, this.headers).extract(link);
  }

  @override
  Media? mediaParse(Response response) {
    throw UnsupportedError('Not Used');
  }

  @override
  Request? mediaRequest(ExtractorLink link) {
    throw UnsupportedError('Not Used');
  }

  // utils

  ShowType getType(String str) {
    if (str == 'tv') {
      return ShowType.Anime;
    } else if (str == 'ona') {
      return ShowType.Ona;
    } else if (str == 'movie') {
      return ShowType.AnimeMovie;
    } else {
      return ShowType.Anime;
    }
  }

  ShowStatus getShowStatus(String str) {
    if (str == 'currently_airing') {
      return ShowStatus.Ongoing;
    } else if (str == 'finished_airing') {
      return ShowStatus.Completed;
    } else {
      return ShowStatus.Unknown;
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
