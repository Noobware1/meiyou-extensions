// ignore_for_file: unnecessary_this

import 'dart:convert';
import 'dart:io';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';
import 'package:meiyou_extenstions/ok_http/ok_http.dart';

void main(List<String> args) async {
  final a = KickassAnime();

  print(await a.loadHomePage(
      1,
      HomePageRequest(
          name: a.homePage.first.name,
          data: a.homePage.first.data,
          horizontalImages: false)));
}

class KickassAnime extends BasePluginApi {
  @override
  String get baseUrl => 'https://kickassanime.am';

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Top Airing': '${this.baseUrl}/api/top_airing',
        'Latest Update': '${this.baseUrl}/api/show/recent?type=all',
        'Latest Dub': '${this.baseUrl}/api/show/recent?type=dub',
        'Latest Chinese Anime': '${this.baseUrl}/api/show/recent?type=chinese',
      });

  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) async {
    final res = await OKHttpClient().get(
      request.data,
      // method: 'GET',
      headers: {"Accept": "application/json, text/plain, */*"},
      verify: false,
    );
    print(res.text);
    if (request.name == 'Top Airing') {
      return HomePage(
          data: HomePageList(name: request.name, data: []),
          page: page,
          hasNextPage: false);

      // return HomePage(
      //     data: HomePageList(
      //         name: request.name, data: parseSearchResponse(res.json())),
      //     page: page);
    } else {
      return HomePage(
          data: HomePageList(name: request.name, data: []),
          page: page,
          hasNextPage: false);
    }

    // return res.json((json) {
    //   return HomePage(
    //       data:
    //           HomePageList(name: request.name, data: parseSearchResponse(json)),
    //       page: page,
    //       hasNextPage: json['hadNext']);
    // });
    ;
  }

  List<SearchResponse> parseSearchResponse(dynamic jsonList,
      [bool banner = false]) {
    final img = banner ? 'banner' : 'poster';
    return ListUtils.mapList(
      jsonList as List,
      (e) => SearchResponse(
        title: e['title'],
        url: e['url'],
        description: e["synopsis"],
        current: e["episode_number"],
        poster: this.baseUrl + _Poster.fromJson(e[img]).poster,
        type: getType(e['type']),
      ),
    );
  }

  @override
  Future<List<ExtractorLink>> loadLinks(String url) async {
    return [];
  }

  @override
  Future<Media?> loadMedia(ExtractorLink link) async {
    return null;
  }

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final details = (await AppUtils.httpRequest(
      url: '${this.baseUrl}/${searchResponse.url}',
      method: 'GET',
    ))
        .json((json) {
      final media = MediaDetails();
      media.copyFromSearchResponse(searchResponse);
      media.url = json['watch_uri'];
      media.startDate =
          DateTime.tryParse(StringUtils.valueToString(json['start_date']));
      media.endDate =
          DateTime.tryParse(StringUtils.valueToString(json['end_date']));

      media.bannerImage =
          this.baseUrl + _Poster.fromJson(json["banner"]).poster;
      media.status = getShowStatus(json['status']);
      media.duration = Duration(minutes: json['episode_duration']);

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

  Future<_EpisodeResponse> _getEpisodes(
      String slug, int page, String lang, String watchUri) async {
    final res = (await AppUtils.httpRequest(
            url:
                '${this.baseUrl}/api/show/$slug/episodes?ep=1&page=$page&lang=$lang',
            method: 'GET',
            headers: {'referer': '${this.baseUrl}/$watchUri'}))
        .json((json) {
      return _EpisodeResponse(
          episodes: parseEpisodeResponse(json['result']),
          total: ListUtils.mapList(json['pages'],
              (e) => StringUtils.toInt(StringUtils.valueToString(e))));
    });

    return res;
  }

  Future<Anime> getAnime(String slug, String lang, String watchUri) async {
    final List<Episode> episodes = [];
    final first = await _getEpisodes(slug, 1, lang, watchUri);
    episodes.addAll(first.episodes);
    for (var i = 0; i < first.total.length - 1; i++) {
      final res = await _getEpisodes(slug, i + 2, lang, watchUri);
      episodes.addAll(res.episodes);
    }

    return Anime(episodes: episodes);
  }

  List<Episode> parseEpisodeResponse(dynamic json) {
    return ListUtils.mapList(json, (e) {
      return Episode(
        name: json['title'],
        data: json['slug'],
        episode: json['episode_number'],
        posterImage: this.baseUrl + _Poster.fromJson(json["poster"]).poster,
      );
    });
  }

  @override
  Future<List<SearchResponse>> search(String query) async {
    return (await AppUtils.httpRequest(
            url: 'https://kickassanime.am/api/fsearch',
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: {'page': 1, 'query': query}))
        .json((json) {
      return parseSearchResponse(json);
    });
  }

  ShowType getType(String str) {
    if (str == 'tv') {
      return ShowType.TvSeries;
    } else if (str == 'ona') {
      return ShowType.Ona;
    } else if (str == 'movie') {
      return ShowType.Movie;
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
        formats: ListUtils.mapList(
            json["formats"], (e) => StringUtils.valueToString(e)),
        sm: json["sm"],
        hq: json["hq"],
      );

  String get poster => '/image/poster/${hq ?? sm ?? ''}.${formats.last}';
}

// BasePluginApi main() {
//   return KickassAnime();
// }
