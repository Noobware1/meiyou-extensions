// ignore_for_file: unnecessary_cast, unnecessary_this

import 'package:meiyou_extensions_repo/extractors/rabbit_stream.dart';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

class FlixHQ extends BasePluginApi {
  FlixHQ();

  //have to add corsproxy to avoid annoying handshake error
  static const String crosProxy = 'https://corsproxy.io';

  @override
  String baseUrl = '${FlixHQ.crosProxy}/?https://flixhq.to';

  // ============================== HomePage ===================================

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Trending': '${this.baseUrl}/home',
        'Trending in India': '${this.baseUrl}/country/IN',
        'Popular Movies': '${this.baseUrl}/movie',
        'Popular TV Shows': '${this.baseUrl}/tv-show',
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
    final data = ListUtils.map(list, (e) {
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
    final url = baseUrl + a.attr('href');

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
        return ListUtils.map(
            l.select('strong > a'), (j) => (j as ElementObject).text());
      }
    }
    return null;
  }

  // =========================== LoadMediaDetails ==============================

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final page =
        (await AppUtils.httpRequest(url: searchResponse.url, method: 'GET'))
            .document;

    final media = MediaDetails();

    media.copyFromSearchResponse(searchResponse);

    media.rating = StringUtils.toDoubleOrNull(
        page.selectFirst('span.item:nth-child(2)').text());

    media.duration = AppUtils.tryParseDuration(
        page.selectFirst('span.item:nth-child(3)').text(), 'min');

    media.description = page.selectFirst('.description').text();

    final elements = page.select('div.elements > .row-line');
    for (var e in elements) {
      final type = e.selectFirst('span.type').text().trim();

      if (type == 'Genre:') {
        media.genres = AppUtils.selectMultiAttr(e.select('a'), 'title');
      } else if (type == 'Released:') {
        media.startDate =
            DateTime.tryParse(e.text().replaceFirst('Released:', '').trim());
      } else if (type == 'Casts:') {
        media.actorData = ListUtils.map(e.select('a'), (e) {
          return toActorData(e);
        });
      }
    }

    media.recommendations = ListUtils.map(
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
    return Movie(
        url: '${this.baseUrl}/ajax/episode/list/${extractIdFromUrl(url)}');
  }

  Future<TvSeries> getTv(String url) async {
    final seasons = (await AppUtils.httpRequest(
            url: '${this.baseUrl}/ajax/season/list/${extractIdFromUrl(url)}',
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
            url: '${this.baseUrl}/ajax/season/episodes/$id', method: 'GET'))
        .document
        .select('ul.nav > li > a');
    return ListUtils.map(list, (e) {
      return toEpisode(e);
    });
  }

  // =============================== LoadLinks =================================

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
                  '${this.baseUrl}/ajax/get_link/${idRegex.firstMatch(e.attr("id"))?.group(1)}',
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
  // =============================== LoadMedia =================================

  @override
  Future<Media?> loadMedia(ExtractorLink link) async {
    if (link.url.contains('doki')) {
      return RabbitStream(link).extract();
    } else if (link.url.contains('rabbit')) {
      return RabbitStream(link).extract();
    }
    return null;
  }

  // ================================ Search ===================================

  @override
  Future<List<SearchResponse>> search(String query) {
    return parseSearchResponse(
        '${this.baseUrl}/search/${AppUtils.encode(query, "-")}');
  }

  // ================================ Helpers ==================================

  Episode toEpisode(ElementObject e) {
    return Episode(
        data: '${this.baseUrl}/ajax/episode/servers/${e.attr('data-id')}',
        episode: StringUtils.toNumOrNull(RegExp(r'\d+')
                .firstMatch(e.selectFirst('strong').text())
                ?.group(0) ??
            ''),
        name: e.attr('title'));
  }

  String extractIdFromUrl(String url) {
    return StringUtils.substringAfterLast(url, '-');
  }

  Future<List<SearchResponse>> parseSearchResponse(String url) async {
    final list = (await AppUtils.httpRequest(url: url, method: 'GET', headers: {
      "Referer": "${this.baseUrl}/home",
    }))
        .document
        .select('.film_list-wrap > div > div.film-poster');
    return ListUtils.map(list, (e) {
      return toSearchResponse(e);
    });
  }

  SearchResponse toSearchResponse(ElementObject e) {
    final url = e.selectFirst('a').attr('href');
    return SearchResponse(
        title: e.selectFirst('a').attr('title'),
        url: baseUrl + url,
        poster: '$crosProxy/?${e.selectFirst('img').attr('data-src')}',
        type: getType(url));
  }

  ShowType getType(String url) {
    if (url.contains('tv')) {
      return ShowType.TvSeries;
    }
    return ShowType.Movie;
  }
}

BasePluginApi main() {
  return FlixHQ();
}
