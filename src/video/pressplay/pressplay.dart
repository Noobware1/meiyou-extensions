// ignore_for_file: unnecessary_this, unnecessary_cast

import 'dart:convert';

import 'package:meiyou_extensions_repo/extractors/movies_club.dart';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

class Pressplay extends BasePluginApi {
  Pressplay();

  @override
  String get baseUrl => 'https://pressplay.top';

  // ============================== HomePage ===================================

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Trending': '${this.baseUrl}/',
        'Movies': '${this.baseUrl}/type-movies',
        'Tv Shows': '${this.baseUrl}/type-series',
        'Anime': '${this.baseUrl}/type-anime',
        'Cartoons': '${this.baseUrl}/type-cartoons',
      });

  // ============================== LoadHomePage ===============================

  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) async {
    if (request.name == 'Trending') {
      return getTrending(request);
    } else {
      return HomePage(
          data: HomePageList(
              name: request.name,
              data: await parseSearchResponse('${request.data}?page=$page')),
          page: page);
    }
  }

  Future<HomePage> getTrending(HomePageRequest request) async {
    final list = (await AppUtils.httpRequest(url: request.data, method: 'GET'))
        .document
        .select('.swiper-slide');
    final data = ListUtils.map<ElementObject, SearchResponse>(list, (e) {
      return parseTrending(e);
    });

    return HomePage(
        data: HomePageList(name: request.name, data: data),
        page: 1,
        hasNextPage: false);
  }

  SearchResponse parseTrending(ElementObject e) {
    final info = e.selectFirst('.container > .slide-caption');
    final a = info.selectFirst('.film-title > a');

    return SearchResponse(
      title: a.text(),
      url: a.attr('href'),
      type: ShowType.Others,
      poster: this.baseUrl + AppUtils.getBackgroundImage(e.attr('style')),
      generes: getGenresForTrending(info),
      description: info.selectFirst('.sc-desc').text(),
    );
  }

  List<String>? getGenresForTrending(ElementObject e) {
    for (var l in e.select('.sc-detail > .scd-item')) {
      if (l.text().contains('Genre:')) {
        return ListUtils.map(
            l.select('strong > a'), (j) => (j as ElementObject).text());
      }
    }
    return null;
  }

  // =========================== LoadMediaDetails ==============================

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final media = MediaDetails();

    media.copyFromSearchResponse(searchResponse);

    final doc =
        (await AppUtils.httpRequest(url: media.url, method: 'GET')).document;

    media.rating =
        StringUtils.toDoubleOrNull(doc.selectFirst('.stats > span > i').text());

    media.duration = AppUtils.tryParseDuration(
        doc.select('.stats > span').last.text(), 'min');

    media.description = doc.selectFirst('.description').text();

    final elements = doc.select('div.elements > .row-line');
    for (var e in elements) {
      final type = e.selectFirst('span.type').text().trim();

      if (type == 'Genre:') {
        media.genres = AppUtils.selectMultiText(e.select('a'));
      } else if (type == 'Released:') {
        media.startDate =
            DateTime.tryParse(e.text().replaceFirst('Released:', '').trim());
      } else if (type == 'Casts:') {
        media.actorData = ListUtils.map(e.select('a'), (e) {
          return toActorData(e);
        });
      }
    }

    media.recommendations =
        ListUtils.map(doc.select('.film_list-wrap > div'), (e) {
      return toSearchResponse(e);
    });

    if (media.type == ShowType.Movie) {
      media.mediaItem = await getMovie(media.url);
    } else {
      media.mediaItem = await getTv(media.url);
    }
    return media;
  }

  Future<Movie> getMovie(String url) async {
    final iframe = await extractIframe(url);

    final jsonData = (await AppUtils.httpRequest(
            url: await extractIframe(iframe), method: 'GET'))
        .json((j) {
      return parseJsonResponse(j);
    });

    return Movie(
      url: _ExtractorLinkData(
        name: jsonData['name'],
        url: jsonData['iframe'],
        referer: iframe,
      ).encode,
    );
  }

  Future<TvSeries> getTv(String url) async {
    final iframe = await extractIframe(url);

    final seasons = ListUtils.map(
        json.decode((await AppUtils.httpRequest(
                url: await extractIframe(iframe), method: 'GET'))
            .text)['simple-api'] as List, (e) {
      return _PressPlaySeasonData.fromJson(e);
    });

    final List<int> trueSeasonsNumber = [];

    for (var i = 0; i < seasons.length; i++) {
      final value = seasons[i].season;
      if (!trueSeasonsNumber.contains(value)) {
        trueSeasonsNumber.add(value);
      }
    }

    trueSeasonsNumber.sort((a, b) => NumUtils.compareTo(a, b));

    final List<SeasonList> data = [];
    for (var number in trueSeasonsNumber) {
      data.add(SeasonList(
          season: SeasonData(season: number),
          episodes: getEpisodes(seasons, number, iframe)));
    }

    return TvSeries(data: data);
  }

  List<Episode> getEpisodes(
      List<_PressPlaySeasonData> seasons, int number, String iframe) {
    final List<Episode> episodes = [];
    for (var i = 0; i < seasons.length; i++) {
      if (seasons[i].season == number) {
        episodes.add(Episode(
            episode: seasons[i].episode,
            data: _ExtractorLinkData(
                    name: seasons[i].title,
                    url: seasons[i].iframe,
                    referer: iframe)
                .encode));
      }
    }
    return episodes;
  }

  // =============================== LoadLinks =================================

  @override
  Future<List<ExtractorLink>> loadLinks(String url) async {
    final decoded = _ExtractorLinkData.decode(url);

    final link = (await AppUtils.httpRequest(
            url: decoded.url, method: 'GET', referer: decoded.referer))
        .document
        .selectFirst('iframe.vidframe')
        .attr('src');

    final host = Uri.parse(decoded.url).host;

    return [
      ExtractorLink(url: link, name: decoded.name, referer: 'https://$host/')
    ];
  }

  // =============================== LoadMedia =================================

  @override
  Future<Media?> loadMedia(ExtractorLink link) {
    return MoviesClub(link).extract();
  }

  // ================================ Search ===================================

  @override
  Future<List<SearchResponse>> search(String query) {
    return parseSearchResponse(
        '${this.baseUrl}/search?q=${AppUtils.encode(query)}');
  }

  // ================================ Helpers ==================================

  Future<List<SearchResponse>> parseSearchResponse(String url) async {
    final list = (await AppUtils.httpRequest(url: url, method: 'GET'))
        .document
        .select('.film_list-wrap > div');
    return ListUtils.map(list, (e) {
      return toSearchResponse(e);
    });
  }

  SearchResponse toSearchResponse(ElementObject e) {
    final info = e.selectFirst('div.film-poster');
    final type =
        info.selectFirst('.film-detail > div > .float-right.fdi-type').text();
    final url = info.selectFirst('a').attr('href');
    return SearchResponse(
      title: info.selectFirst('a').attr('title'),
      url: url,
      poster: this.baseUrl + info.selectFirst('img').attr('data-src'),
      type: getType(type),
    );
  }

  ActorData toActorData(ElementObject e) {
    return ActorData(name: e.text());
  }

  dynamic parseJsonResponse(dynamic j) {
    return (j['simple-api'] as List)[0];
  }

  ShowType getType(String type) {
    final trimed = type.trim();
    if (trimed == 'Movie') {
      return ShowType.Movie;
    } else {
      return ShowType.TvSeries;
    }
  }

  //Why just why????
  Future<String> extractIframe(String url) async {
    final doc = (await AppUtils.httpRequest(url: url, method: 'GET')).document;

    const playerQueryApi = 'data-cinemaplayer-query-api';

    final player = doc.selectFirst('div#cinemaplayer');
    final apiUrl = player.attr('data-cinemaplayer-api');
    if (apiUrl.contains('json')) {
      return apiUrl;
    }
    final id = player.attr('$playerQueryApi-id');
    final imdbId = player.attr('$playerQueryApi-imdb_id');
    final tmdbId = player.attr('$playerQueryApi-tmdb_id');
    final movieId = player.attr('$playerQueryApi-movie_id');
    final type = player.attr('$playerQueryApi-type');
    final title = player.attr('$playerQueryApi-title');
    final year = player.attr('$playerQueryApi-year');
    final season = player.attr('$playerQueryApi-season');
    final ip = player.attr('$playerQueryApi-ip');
    final hash = player.attr('$playerQueryApi-hash');
    final episode = player.attr('$playerQueryApi-episode');

    final params = {
      'hash': hash,
      'ip': ip,
      'episode': episode,
      'season': season,
      'year': year,
      'title': title,
      'type': type,
      'movie_id': movieId,
      'tmdb_id': tmdbId,
      'imdb_id': imdbId,
      'id': id,
    };

    final iframe = (await AppUtils.httpRequest(
            url: '${this.baseUrl}$apiUrl', method: 'GET', params: params))
        .json((j) {
      return StringUtils.valueToString(parseJsonResponse(j)['iframe']);
    });

    return iframe;
  }
}

class _ExtractorLinkData {
  final String name;
  final String url;
  final String referer;

  _ExtractorLinkData(
      {required this.name, required this.url, required this.referer});

  String get encode => json.encode(toJson());

  factory _ExtractorLinkData.decode(String jsonString) {
    return _ExtractorLinkData.fromJson(json.decode(jsonString));
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'referer': referer,
    };
  }

  factory _ExtractorLinkData.fromJson(dynamic json) {
    return _ExtractorLinkData(
        name: json['name'], url: json['url'], referer: json['referer']);
  }
}

class _PressPlaySeasonData {
  final int season;
  final String iframe;
  final int episode;
  final String title;

  _PressPlaySeasonData({
    required this.season,
    required this.iframe,
    required this.episode,
    required this.title,
  });

  factory _PressPlaySeasonData.fromJson(dynamic json) {
    return _PressPlaySeasonData(
        season: StringUtils.toInt(json['season']),
        iframe: json['iframe'],
        episode: StringUtils.toInt(json['episode']),
        title: json['name']);
  }
}

BasePluginApi main() {
  return Pressplay();
}
