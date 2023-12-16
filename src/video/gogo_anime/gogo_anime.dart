// ignore_for_file: unnecessary_cast, unnecessary_this

import 'package:meiyou_extensions_repo/extractors/gogo_cdn.dart';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

class GogoAnime extends BasePluginApi {
  GogoAnime();

  @override
  String get baseUrl => 'https://anitaku.to';

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Recently Released': '1',
        'Popular Anime': '2',
        'Anime Movies': '3',
        'Seasonal Anime': '4',
      });

  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) async {
    return HomePage(
        data: HomePageList(
            name: request.name, data: await getHomePageListData(page, request)),
        page: 1);
  }

  Future<List<SearchResponse>> getHomePageListData(
      int page, HomePageRequest request) async {
    if (request.data == '1') {
      return getRecentPage(page);
    } else if (request.data == '2') {
      return getPopularPage(page);
    } else if (request.data == '3') {
      return getMoviesPage(page);
    } else {
      return getSeasonal(page);
    }
  }

  Future<List<SearchResponse>> getPopularPage(int page) {
    return parseHomePage('${this.baseUrl}/popular.html?page=$page');
  }

  Future<List<SearchResponse>> getMoviesPage(int page) {
    return parseHomePage('${this.baseUrl}/anime-movies.html?aph=&page=$page');
  }

  Future<List<SearchResponse>> getRecentPage(int page) async {
    return ListUtils.mapList(
        (await AppUtils.httpRequest(
                url:
                    'https://ajax.gogo-load.com/ajax/page-recent-release-ongoing.html?page=$page',
                method: 'GET'))
            .document
            .select(".added_series_body.popular > ul > li"), (e) {
      return parseRecentPage(e);
    });
  }

  SearchResponse parseRecentPage(ElementObject e) {
    final a = e.selectFirst('a');
    final img = RegExp(r"""background:\surl\(['|"](.*)['|"]\)""")
            .firstMatch(a.selectFirst('div').attr('style'))
            ?.group(1) ??
        '';

    return SearchResponse(
        title: e.select('a')[1].text().trim(),
        url: this.baseUrl + a.attr('href'),
        generes: getGeneres(e.select('.genres > a')),
        poster: img,
        type: ShowType.Anime);
  }

  Future<List<SearchResponse>> getSeasonal(int page) {
    return parseHomePage('${this.baseUrl}/new-season.html?page=$page');
  }

  Future<List<SearchResponse>> parseHomePage(String url) async {
    return ListUtils.mapList(
        (await AppUtils.httpRequest(url: url, method: 'GET'))
            .document
            .select("div > ul.items > li"), (e) {
      return toHomePageList(e);
    });
  }

  SearchResponse toHomePageList(ElementObject e) {
    final a = e.selectFirst('p.name > a');
    return SearchResponse(
        title: a.text(),
        url: this.baseUrl + a.attr('href'),
        poster: e.selectFirst('div.img > a > img').attr('src'),
        type: ShowType.Anime);
  }

  List<String> getGeneres(List<ElementObject> elements) {
    return ListUtils.mapList<String, ElementObject>(elements, (it) {
      return (it as ElementObject).attr('title');
    });
  }

  @override
  Future<List<SearchResponse>> search(String query) async {
    final doc = (await AppUtils.httpRequest(
            url:
                '${this.baseUrl}/search.html?keyword=${AppUtils.encode(query)}',
            method: 'GET'))
        .document;

    return ListUtils.mapList(doc.select('.items > li'), (it) {
      return toSearchResponse(it);
    });
  }

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final animePage =
        (await AppUtils.httpRequest(url: searchResponse.url, method: 'GET'))
            .document;
    final media = MediaDetails();
    media.name = searchResponse.title;

    final body = animePage.selectFirst('div.anime_info_body_bg');

    media.posterImage = body.selectFirst('img').attr('src');

    for (var e in body.select('p.type')) {
      final header = e.selectFirst('span').text().trim();

      if (header == 'Plot Summary:') {
        media.description = e.text().replaceFirst('Plot Summary:', '').trim();
      } else if (header == 'Type:') {
        media.type = getType(e.selectFirst('a').attr('title'));
      } else if (header == 'Genre:') {
        media.genres = AppUtils.selectMultiAttr(e.select('a'), 'title');
      } else if (header == 'Released:') {
        media.startDate = AppUtils.toDateTime(
            StringUtils.toInt(e.text().replaceFirst('Released:', '').trim()));
      } else if (header == 'Status:') {
        media.status = getStatus(e.text().replaceFirst('Status:', ''));
      } else if (header == 'Other name:') {
        media.otherTitles =
            e.text().replaceFirst('Other name:', '').trim().split(';');
      }
    }
    final epEnd =
        animePage.select('ul#episode_page > li > a').last.attr('ep_end');

    final id = animePage
        .selectFirst('.anime_info_episodes_next > #movie_id')
        .attr('value');

    final alias = animePage
        .selectFirst('.anime_info_episodes_next >.alias_anime')
        .attr('value');

    media.mediaItem = Anime(
        episodes: ListUtils.mapList(
            (await AppUtils.httpRequest(
                    url:
                        'https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=$epEnd&id=$id&alias=$alias',
                    method: 'GET'))
                .document
                .select('#episode_related > li > a'), (it) {
      return toEpisode(it);
    }).reversed.toList());

    return media;
  }

  @override
  Future<List<ExtractorLink>> loadLinks(String url) async {
    return ListUtils.mapList(
        (await AppUtils.httpRequest(url: url, method: 'GET'))
            .document
            .select('.anime_muti_link > ul > li > a'), (it) {
      return toExtractorLink(it);
    });
  }

  @override
  Future<Media?> loadMedia(ExtractorLink link) async {
    if (link.url.contains('/streaming.php?')) {
      return GogoCDN(link).extract();
    } else if (link.url.contains('/embedplus?')) {
      return GogoCDN(link).extract();
    } else {
      return null;
    }
  }

  SearchResponse toSearchResponse(ElementObject element) {
    return SearchResponse(
        title: element.selectFirst('p.name > a').text(),
        url: this.baseUrl + element.selectFirst('div.img > a').attr('href'),
        poster: element.selectFirst('div.img > a > img').attr('src'),
        type: ShowType.Anime);
  }

  Episode toEpisode(ElementObject element) {
    return Episode(
        data: this.baseUrl + element.attr('href').trim(),
        episode: StringUtils.toNum(
            element.selectFirst('div.name').text().replaceFirst('EP ', '')));
  }

  ShowType getType(String t) {
    if (t.contains("OVA")) {
      return ShowType.Ova;
    } else if (t.contains("Special")) {
      return ShowType.Ova;
    } else if (t.contains("Movie")) {
      return ShowType.AnimeMovie;
    } else {
      return ShowType.Anime;
    }
  }

  ShowStatus getStatus(String t) {
    if (t == 'Ongoing') {
      return ShowStatus.Ongoing;
    } else {
      return ShowStatus.Completed;
    }
  }

  ExtractorLink toExtractorLink(ElementObject it) {
    return ExtractorLink(
      name: it.text().replaceFirst('Choose this server', '').trim(),
      url: AppUtils.httpify(it.attr('data-video')),
    );
  }
}

main() {
  return GogoAnime();
}
