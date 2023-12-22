// ignore_for_file: unnecessary_cast, unnecessary_this

import 'dart:convert';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

class FlixHQMirror extends BasePluginApi {
  FlixHQMirror();

  @override
  String baseUrl = 'https://flixhq.click';

  // ============================== HomePage ===================================

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Trending': '${this.baseUrl}/home',
        'Trending in India': '${this.baseUrl}/country/india',
        'Popular Movies': '${this.baseUrl}/movies',
        'Popular TV Shows': '${this.baseUrl}/tv-series',
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
              data: await parseSearchResponse('${request.data}/page/$page/')),
          page: page);
    }
  }

  Future<HomePage> getTrending(HomePageRequest request) async {
    final list = (await AppUtils.httpRequest(url: request.data, method: 'GET'))
        .document
        .select('.swiper-slide');

    final data = ListUtils.map(list, (e) => parseTrending(e));

    return HomePage(
      data: HomePageList(name: request.name, data: data),
      page: 1,
      hasNextPage: false,
    );
  }

  SearchResponse parseTrending(ElementObject e) {
    final info = e.selectFirst('.container > .info');

    final url = info.selectFirst('.actions > a').attr('href');

    final meta = info.selectFirst('.meta');

    return SearchResponse(
      title: info.selectFirst('h3.title').text(),
      url: url,
      poster: AppUtils.httpify(e.attr('data-src')),
      generes: getGenresForTrending(meta.select('span').last),
      type: ShowType.Movie,
      rating: StringUtils.toDoubleOrNull(
          meta.selectFirst('.imdb').text().replaceAll('"', '').trim()),
      description: info.selectFirst('.desc').text(),
    );
  }

  List<String>? getGenresForTrending(ElementObject e) {
    return ListUtils.map(e.select('a'), (l) => l.text());
  }

  // =========================== LoadMediaDetails ==============================

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final page =
        (await AppUtils.httpRequest(url: searchResponse.url, method: 'GET'))
            .document;

    final media = MediaDetails();

    media.copyFromSearchResponse(searchResponse);
    final info = page.selectFirst('div.info');
    final firstRow = info.selectFirst('.meta.lg');

    media.rating = StringUtils.toDoubleOrNull(
        firstRow.selectFirst('span.imdb').text().replaceAll('"', '').trim());

    media.duration =
        AppUtils.tryParseDuration(firstRow.select('span').last.text(), 'min');

    media.description = info.selectFirst('.desc.shorting > p').text();

    final elements = info.select('.meta > div');
    for (var e in elements) {
      final type = e.selectFirst('span:nth-child(1)').text().trim();

      if (type == 'Genre:') {
        media.genres = AppUtils.selectMultiText(e.select('a'));
      } else if (type == 'Stars:') {
        media.actorData =
            ListUtils.map(e.select('a'), (e) => ActorData(name: e.text()));
      }
    }

    media.recommendations =
        ListUtils.map(page.select('.filmlist.active.related > div'), (e) {
      return toSearchResponse(e);
    });

    // if (searchResponse.type == ShowType.Movie) {
    //   media.mediaItem = getMovie(searchResponse.url);
    // } else {
    //   media.mediaItem = await getTv(searchResponse.url);
    // }

    // return media;
    final List<ExtractorLink> servers = [];
    final serversNames = parseServersName(page.select('#servers > div.server'));
    final serversJson =
        getServersJson(page.selectFirst('#servers-js-extra').text());
    for (var s in serversNames) {
      final link = serversJson[s];
      if (link != null) {
        servers.add(ExtractorLink(
          name: s,
          url: link,
        ));
      }
    }

    return media;
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
    throw UnimplementedError();
  }
  // =============================== LoadMedia =================================

  @override
  Future<Media?> loadMedia(ExtractorLink link) async {
    throw UnimplementedError();
  }

  // ================================ Search ===================================

  @override
  Future<List<SearchResponse>> search(String query) {
    return parseSearchResponse(
        '${this.baseUrl}/search/${AppUtils.encode(query, "-")}');
  }

  // ================================ Helpers ==================================

  Iterable<String> parseServersName(List<ElementObject> elements) {
    return elements.map((e) => StringUtils.substringAfter(
        StringUtils.substringBeforeLast(e.attr('onclick'), ')'), '('));
  }

  Map getServersJson(String text) {
    return json.decode(StringUtils.substringAfter(
        'var Servers = ', StringUtils.substringBeforeLast(text, ';'))) as Map;
  }

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
        .select('.filmlist.md.active > div')
      ..removeLast();
    return ListUtils.map(list, (e) {
      return toSearchResponse(e);
    });
  }

  SearchResponse toSearchResponse(ElementObject e) {
    final a = e.selectFirst('a');

    return SearchResponse(
        title: e.selectFirst('.entry-title > a').text(),
        url: a.attr('href'),
        poster: a.selectFirst('img').attr('data-src'),
        type: getType(e.selectFirst('.meta > i').text().toLowerCase()));
  }

  ShowType getType(String type) {
    if (type == 'tv') {
      return ShowType.TvSeries;
    }
    return ShowType.Movie;
  }
}

BasePluginApi main() {
  return FlixHQMirror();
}
// void main(List<String> args) async {
//   // final req = FlixHQ().homePage.elementAt(1);
//   print(
//     await FlixHQ().loadMediaDetails(SearchResponse(
//       title: 'Animal',
//       url: 'https://flixhq.click/animal/',
//       poster:
//           'https://flixhq.click/wp-content/uploads/2023/12/hr9rjR3J0xBBKmlJ4n3gHId9ccx.jpg',
//       type: ShowType.Movie,
//     )),
//   );
// }
