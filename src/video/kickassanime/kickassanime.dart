// ignore_for_file: unnecessary_this, unnecessary_cast, unnecessary_string_interpolations

import 'dart:convert';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';
import 'package:meiyou_extensions_repo/extractors/kaa_extractor.dart';

class KickassAnime extends BasePluginApi {
  @override
  String get baseUrl => 'https://kaas.ro';

  // ============================== HomePage ===================================

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Top Airing': '${this.baseUrl}/api/top_airing',
        'Latest Update': '${this.baseUrl}/api/show/recent?type=all',
        'Latest Dub': '${this.baseUrl}/api/show/recent?type=dub',
        'Latest Chinese Anime': '${this.baseUrl}/api/show/recent?type=chinese',
      });

  // ============================== LoadHomePage ===============================

  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) async {
    final HomePage homePage;
    if (request.name == 'Top Airing') {
      homePage = (await AppUtils.httpRequest(url: request.data, method: 'GET'))
          .json((json) {
        return HomePage(
          data:
              HomePageList(name: request.name, data: parseSearchResponse(json)),
          page: page,
          hasNextPage: false,
        );
      });
    } else {
      homePage = (await AppUtils.httpRequest(
              url: '${request.data}&page=$page', method: 'GET'))
          .json((json) {
        return HomePage(
          data: HomePageList(
              name: request.name, data: parseSearchResponse(json['result'])),
          page: page,
          hasNextPage: json['hadNext'],
        );
      });
    }
    return homePage;
  }
  // =========================== LoadMediaDetails ==============================

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final response = await AppUtils.httpRequest(
      url: '${this.baseUrl}/api/show/${searchResponse.url}',
      method: 'GET',
    );

    final details = response.json((json) {
      final media = MediaDetails();
      media.copyFromSearchResponse(searchResponse);
      media.url = json['watch_uri'];

      media.startDate =
          DateTime.tryParse(StringUtils.valueToString(json['start_date']));
      media.endDate =
          DateTime.tryParse(StringUtils.valueToString(json['end_date']));

      media.bannerImage = AppUtils.trySync(
          () => this.baseUrl + _Poster.fromJson(json["banner"]).banner);

      media.status = getShowStatus(json['status']);

      media.duration = Duration(
        minutes: StringUtils.toInt(
            StringUtils.valueToString(json['episode_duration'])),
      );

      media.otherTitles = [json['title_en'], json['title_original']];

      return media;
    });

    details.mediaItem = await getAnime(
      searchResponse.url,
      'ja-JP',
      details.url,
    );

    return details;
  }

  Future<Anime> getAnime(String slug, String lang, String watchUri) async {
    final List<Episode> episodes = [];
    final first = await _getEpisodes(
        slug: slug, page: 1, total: null, lang: lang, watchUri: watchUri);
    episodes.addAll(first.episodes);

    for (var i = 1; i < first.total.length; i++) {
      final res = await _getEpisodes(
        slug: slug,
        page: i + 1,
        total: first.total,
        lang: lang,
        watchUri: watchUri,
      );
      episodes.addAll(res.episodes);
    }

    return Anime(episodes: episodes);
  }

  Future<_EpisodeResponse> _getEpisodes({
    required String slug,
    required int page,
    required List<int>? total,
    required String lang,
    required String watchUri,
  }) async {
    final res = (await AppUtils.httpRequest(
            url:
                '${this.baseUrl}/api/show/$slug/episodes?ep=1&page=$page&lang=$lang',
            method: 'GET',
            headers: {'referer': '${this.baseUrl}/$watchUri'}))
        .json((json) {
      return _EpisodeResponse(
        episodes: parseEpisodeList(slug, json['result']),
        total:
            total ?? ListUtils.map((json['pages'] as List), (e) => e['number']),
      );
    });

    return res;
  }

  // =============================== LoadLinks =================================

  @override
  Future<List<ExtractorLink>> loadLinks(String url) async {
    final response = await AppUtils.httpRequest(
      url:
          '${this.baseUrl}/api/show/${url.replaceFirst("/ep-", "/episode/ep-")}',
      method: 'GET',
    );

    return response.json((json) {
      return ListUtils.map(json['servers'] as List, (e) {
        return ExtractorLink(
          name: e['name'],
          url: e['src'],
          headers: {
            'shortName': StringUtils.valueToString(e['shortName']).toLowerCase()
          },
        );
      });
    });
  }

  // =============================== LoadMedia =================================

  @override
  Future<Media?> loadMedia(ExtractorLink link) async {
    return KickAssAnimeExtractor(link).extract();
  }

  // ================================ Search ===================================

  @override
  Future<List<SearchResponse>> search(String query) async {
    final response = await AppUtils.httpRequest(
        url: '${this.baseUrl}/api/fsearch',
        method: 'POST',
        headers: {
          'accept': "application/json, text/plain, */*",
          'content-type': "application/json",
          'origin': this.baseUrl,
          'referer': "${this.baseUrl}/anime"
        },
        body: json.encode({"page": 1, "query": "$query"}));

    return response.json((json) => parseSearchResponse(json['result']));
  }

  // ================================ Helpers ==================================
  List<SearchResponse> parseSearchResponse(dynamic jsonList) {
    return ListUtils.map(jsonList as List, (e) {
      return SearchResponse(
        title: e['title'],
        url: e['slug'],
        description: e["synopsis"],
        current: e["episode_number"],
        poster: this.baseUrl + _Poster.fromJson(e['poster']).poster,
        type: getType(e['type']),
        generes: ListUtils.mapNullable(
            e['genres'], (it) => StringUtils.valueToString(it)),
      );
    });
  }

  List<Episode> parseEpisodeList(String slug, dynamic json) {
    return ListUtils.map(json, (e) {
      return parseEpisode(slug, e as Map);
    });
  }

  Episode parseEpisode(String slug, Map json) {
    final int number = json['episode_number'] as int;
    return Episode(
      name: json['title'],
      data: '$slug/ep-$number-${StringUtils.valueToString(json['slug'])}',
      episode: number,
      posterImage: this.baseUrl + _Poster.fromJson(json["thumbnail"]).thumbnail,
    );
  }

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

class _EpisodeResponse {
  final List<Episode> episodes;
  final List<int> total;

  _EpisodeResponse({required this.episodes, required this.total});
}

class _Poster {
  final List<String> formats;
  final String? sm;
  final String? hq;

  _Poster({
    required this.formats,
    required this.sm,
    required this.hq,
  });

  factory _Poster.fromJson(dynamic json) => _Poster(
        formats:
            ListUtils.map(json["formats"], (e) => StringUtils.valueToString(e)),
        sm: json["sm"],
        hq: json["hq"],
      );

  String get poster => '/image/poster/${hq ?? sm ?? ''}.${formats.last}';
  String get banner => '/image/banner/${hq ?? sm ?? ''}.${formats.last}';
  String get thumbnail => '/image/thumbnail/${sm ?? hq ?? ''}.${formats.last}';
}

BasePluginApi main() {
  return KickassAnime();
}
