// ignore_for_file: unnecessary_this, unnecessary_cast

import 'dart:convert';

import 'package:meiyou_extensions_repo/extractors/movies_club.dart';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

final String hostUrl = 'https://pressplay.top';

class Pressplay extends BasePluginApi {
  Pressplay();

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Trending': '$hostUrl/',
        'Movies': '$hostUrl/type-movies',
        'Tv Shows': '$hostUrl/type-series',
        'Anime': '$hostUrl/type-anime',
        'Cartoons': '$hostUrl/type-cartoons',
      });

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
    final data = ListUtils.mapList(list, (e) {
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
    final url = hostUrl + a.attr('href');

    return SearchResponse(
      title: a.text(),
      url: url,
      type: ShowType.Others,
      poster: AppUtils.getBackgroundImage(e.attr('style')),
      generes: getGenresForTrending(info),
      description: info.selectFirst('.sc-desc').text(),
    );
  }

  List<String>? getGenresForTrending(ElementObject e) {
    for (var l in e.select('.sc-detail > .scd-item')) {
      if (l.text().contains('Genre:')) {
        return ListUtils.mapList(
            l.select('strong > a'), (j) => (j as ElementObject).text());
      }
    }
    return null;
  }

  @override
  Future<List<ExtractorLink>> loadLinks(String url) async {
    final decoded = ExtractorLinkData.decode(url);

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

  @override
  Future<Media?> loadMedia(ExtractorLink link) async {
    return MoviesClub(link).extract();
  }

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final media = MediaDetails();

    media.copyFromSearchResponse(searchResponse);
    final doc =
        (await AppUtils.httpRequest(url: searchResponse.url, method: 'GET'))
            .document;

    media.rating =
        StringUtils.toDoubleOrNull(doc.selectFirst('.stats > span > i').text());
    media.duration = parseDuation(doc.select('.stats > span').last.text());

    media.description = doc.selectFirst('.description').text();

    final elements = doc.select('div.elements > .row-line');
    for (var e in elements) {
      final type = StringUtils.trim(e.selectFirst('span.type').text());

      if (type == 'Genre:') {
        media.genres = AppUtils.selectMultiText(e.select('a'));
      } else if (type == 'Released:') {
        media.startDate =
            DateTime.tryParse(e.text().replaceFirst('Released:', '').trim());
      } else if (type == 'Casts:') {
        media.actorData = ListUtils.mapList(e.select('a'), (e) {
          return toActorData(e);
        });
      }
    }

    media.recommendations = ListUtils.mapList(
        doc.select('.film_list-wrap > div > div.film-poster'), (e) {
      return toSearchResponse(e);
    });

    if (media.type == ShowType.Movie) {
      media.mediaItem = await getMovie(media.url);
    } else {
      media.mediaItem = await getTv(media.url);
    }
    return media;
  }

  ActorData toActorData(ElementObject e) {
    return ActorData(name: e.text());
  }

  Future<Movie> getMovie(String url) async {
    final iframe = await extractIframe(url);

    final jsonData = (json.decode((await AppUtils.httpRequest(
            url: await extractIframe(iframe), method: 'GET'))
        .text)['simple-api'] as List)[0];

    return Movie(
        url: ExtractorLinkData(
      name: jsonData['name'],
      url: jsonData['iframe'],
      referer: iframe,
    ).encode);
  }

  Future<TvSeries> getTv(String url) async {
    final iframe = await extractIframe(url);

    final seasons = ListUtils.mapList(
        json.decode((await AppUtils.httpRequest(
                url: await extractIframe(iframe), method: 'GET'))
            .text)['simple-api'] as List, (e) {
      return PressPlaySeasonData.fromJson(e);
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
      List<PressPlaySeasonData> seasons, int number, String iframe) {
    final List<Episode> episodes = [];
    for (var i = 0; i < seasons.length; i++) {
      if (seasons[i].season == number) {
        episodes.add(Episode(
            episode: seasons[i].episode,
            data: ExtractorLinkData(
                    name: seasons[i].title,
                    url: seasons[i].iframe,
                    referer: iframe)
                .encode));
      }
    }
    return episodes;
  }

  @override
  Future<List<SearchResponse>> search(String query) {
    return parseSearchResponse('$hostUrl/search?q=${AppUtils.encode(query)}');
  }

  Future<List<SearchResponse>> parseSearchResponse(String url) async {
    final list = (await AppUtils.httpRequest(url: url, method: 'GET'))
        .document
        .select('.film_list-wrap > div');
    return ListUtils.mapList(list, (e) {
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
        poster: hostUrl + info.selectFirst('img').attr('data-src'),
        type: getType(type));
  }

  ShowType getType(String type) {
    if (type.trim() == 'Movie') {
      return ShowType.Movie;
    }
    return ShowType.TvSeries;
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
            url: '$hostUrl$apiUrl', method: 'GET', params: params))
        .json((json) {
      return StringUtils.valueToString(
          (json['simple-api'] as List)[0]['iframe']);
    });

    return iframe;
  }

  Duration? parseDuation(String s) {
    final min =
        StringUtils.toIntOrNull(StringUtils.substringBefore(s, 'min').trim());
    if (min != null) {
      return Duration(minutes: min);
    }
    return null;
  }
}

class ExtractorLinkData {
  final String name;
  final String url;
  final String referer;

  ExtractorLinkData(
      {required this.name, required this.url, required this.referer});

  String get encode => json.encode(toJson());

  factory ExtractorLinkData.decode(String jsonString) {
    return ExtractorLinkData.fromJson(json.decode(jsonString));
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'referer': referer,
    };
  }

  factory ExtractorLinkData.fromJson(dynamic json) {
    return ExtractorLinkData(
        name: json['name'], url: json['url'], referer: json['referer']);
  }
}

class PressPlaySeasonData {
  final int season;
  final String iframe;
  final int episode;
  final String title;

  PressPlaySeasonData({
    required this.season,
    required this.iframe,
    required this.episode,
    required this.title,
  });

  factory PressPlaySeasonData.fromJson(dynamic json) {
    return PressPlaySeasonData(
        season: StringUtils.toInt(json['season']),
        iframe: json['iframe'],
        episode: StringUtils.toInt(json['episode']),
        title: json['name']);
  }
}

// class PressPlaySearchData {
//   final String title;
//   final String url;
//   final String? poster;
//   final String? description;
//   final double? rating;
//   final List<String>? genres;
//   final List<String>? actors;

//   PressPlaySearchData({
//     required this.title,
//     required this.url,
//     this.poster,
//     this.description,
//     this.rating,
//     this.genres,
//     this.actors,
//   });

//   factory PressPlaySearchData.fromJson(dynamic json) {
//     return PressPlaySearchData(
//       title: json['title'],
//       url: json['url'],
//       poster: json['poster'],
//       description: json['description'],
//       rating: json['rating'],
//       genres: PressPlaySearchData.mapList(json['genres']),
//       actors: PressPlaySearchData.mapList(json['actors']),
//     );
//   }

//   factory PressPlaySearchData.fromPressPlayResponse(dynamic json) {
//     return PressPlaySearchData(
//       title: json['title'] ?? json['title_en'] ?? json['title_full'] ?? '',
//       url: json['url'],
//       poster: PressPlaySearchData.fixUrl(json['poster_big'] ?? json['poster']),
//       description: json['description'],
//       rating:
//           StringUtils.toDoubleOrNull(StringUtils.valueToString(json['rating'])),
//       genres: PressPlaySearchData.mapList(json['genres_arr']),
//       actors: PressPlaySearchData.mapList(json['actors_arr']),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'title': this.title,
//       'url': this.url,
//       'poster': this.poster,
//       'description': this.description,
//       'rating': this.rating,
//       'genres': this.genres,
//       'actors': this.actors,
//     };
//   }

//   static List<String>? mapList(dynamic list) {
//     if (AppUtils.isNotNull(list)) {
//       return ListUtils.mapList(list as List, (e) {
//         return StringUtils.valueToString(e);
//       });
//     }
//     return null;
//   }

//   static String fixUrl(dynamic url) {
//     if (AppUtils.isNotNull(url)) {
//       return '$hostUrl$url';
//     }
//     return '';
//   }
// }

BasePluginApi main() {
  return Pressplay();
}
