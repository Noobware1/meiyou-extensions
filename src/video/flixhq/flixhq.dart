// ignore_for_file: unnecessary_cast

import 'package:meiyou_extensions_repo/extractors/rabbit_stream.dart';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

//have to add corsproxy to avoid annoying handshake error

const String crosProxy = 'https://corsproxy.io';

const String hostUrl = '$crosProxy/?https://flixhq.to';

class FlixHQ extends BasePluginApi {
  FlixHQ();

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Trending': '$hostUrl/home',
        'Trending in India': '$hostUrl/country/IN',
        'Popular Movies': '$hostUrl/movie',
        'Popular TV Shows': '$hostUrl/tv-show',
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
      poster: '$crosProxy/?${AppUtils.getBackgroundImage(e.attr('style'))}',
      generes: getGenresForTrending(info),
      type: getType(url),
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
    final servers = (await AppUtils.httpRequest(url: url, method: 'GET'))
        .document
        .select('ul.nav > li > a');

    final List<ExtractorLink> links = [];
    final idRegex = RegExp(r'-(\d+)');
    for (var e in servers) {
      final link = (await AppUtils.httpRequest(
              url:
                  '$hostUrl/ajax/get_link/${idRegex.firstMatch(e.attr("id"))?.group(1)}',
              method: 'GET',
              headers: {
            "X-Requested-With": "XMLHttpRequest",
          }))
          .json((j) => StringUtils.valueToString(j['link']));

      try {
        links.add(ExtractorLink(
          name: StringUtils.trimNewLines(
              e.attr('title').replaceFirst('Server', '')),
          url: link,
        ));
      } catch (e) {}
    }
    return links;
  }

  @override
  Future<Media?> loadMedia(ExtractorLink link) async {
    if (link.url.contains('doki')) {
      return RabbitStream(link).extract();
    } else if (link.url.contains('rabbit')) {
      return RabbitStream(link).extract();
    }
    return null;
  }

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final page =
        (await AppUtils.httpRequest(url: searchResponse.url, method: 'GET'))
            .document;

    final media = MediaDetails();

    media.copyFromSearchResponse(searchResponse);

    media.rating = StringUtils.toDoubleOrNull(
        page.selectFirst('span.item:nth-child(2)').text());

    media.duration =
        parseDuation(page.selectFirst('span.item:nth-child(3)').text());

    media.description = page.selectFirst('.description').text();

    final elements = page.select('div.elements > .row-line');
    for (var e in elements) {
      final type = StringUtils.trim(e.selectFirst('span.type').text());

      if (type == 'Genre:') {
        media.genres = AppUtils.selectMultiAttr(e.select('a'), 'title');
      } else if (type == 'Released:') {
        media.startDate = DateTime.tryParse(
            StringUtils.trim(e.text().replaceFirst('Released:', '')));
      } else if (type == 'Casts:') {
        media.actorData = ListUtils.mapList(e.select('a'), (e) {
          return toActorData(e);
        });
      }
    }

    media.recommendations = ListUtils.mapList(
        page.select('.film_list-wrap > div > div.film-poster'), (e) {
      return toSearchResponse(e);
    });

    if (searchResponse.type == ShowType.Movie) {
      media.mediaItem = getMovie(searchResponse.url);
    } else {
      media.mediaItem = await getTv(searchResponse.url);
    }

    return media;
  }

  ActorData toActorData(ElementObject e) {
    return ActorData(name: e.text());
  }

  Movie getMovie(String url) {
    return Movie(url: '$hostUrl/ajax/episode/list/${extractIdFromUrl(url)}');
  }

  Future<TvSeries> getTv(String url) async {
    final seasons = (await AppUtils.httpRequest(
            url: '$hostUrl/ajax/season/list/${extractIdFromUrl(url)}',
            method: 'GET',
            referer: url))
        .document
        .select('.dropdown-menu.dropdown-menu-new > a');

    final List<SeasonList> data = [];
    for (var season in seasons) {
      data.add(SeasonList(
          season: SeasonData(
            season: StringUtils.toNumOrNull(
                StringUtils.substringAfter(season.text(), 'Season ')),
          ),
          episodes: await getEpisodes(season.attr('data-id'))));
    }

    return TvSeries(data: data);
  }

  Future<List<Episode>> getEpisodes(String id) async {
    final list = (await AppUtils.httpRequest(
            url: '$hostUrl/ajax/season/episodes/$id', method: 'GET'))
        .document
        .select('ul.nav > li > a');
    return ListUtils.mapList(list, (e) {
      return toEpisode(e);
    });
  }

  Episode toEpisode(ElementObject e) {
    return Episode(
        data: '$hostUrl/ajax/episode/servers/${e.attr('data-id')}',
        episode: StringUtils.toNumOrNull(RegExp(r'\d+')
                .firstMatch(e.selectFirst('strong').text())
                ?.group(0) ??
            ''),
        name: e.attr('title'));
  }

  String extractIdFromUrl(String url) {
    return StringUtils.substringAfterLast(url, '-');
  }

  @override
  Future<List<SearchResponse>> search(String query) {
    return parseSearchResponse(
        '$hostUrl/search/${AppUtils.encode(query, "-")}');
  }

  Future<List<SearchResponse>> parseSearchResponse(String url) async {
    final list = (await AppUtils.httpRequest(url: url, method: 'GET', headers: {
      "Referer": "$hostUrl/home",
    }))
        .document
        .select('.film_list-wrap > div > div.film-poster');
    return ListUtils.mapList(list, (e) {
      return toSearchResponse(e);
    });
  }

  SearchResponse toSearchResponse(ElementObject e) {
    final url = e.selectFirst('a').attr('href');
    return SearchResponse(
        title: e.selectFirst('a').attr('title'),
        url: hostUrl + url,
        poster: '$crosProxy/?${e.selectFirst('img').attr('data-src')}',
        type: getType(url));
  }

  ShowType getType(String url) {
    if (url.contains('tv')) {
      return ShowType.TvSeries;
    }
    return ShowType.Movie;
  }

  Duration? parseDuation(String s) {
    final min = StringUtils.toIntOrNull(
        StringUtils.trim(StringUtils.substringBefore(s, 'min')));
    if (min == null) {
      return null;
    }
    return Duration(minutes: min);
  }
}

BasePluginApi main() {
  return FlixHQ();
}
