// ignore_for_file: unnecessary_cast, unnecessary_this

import 'package:meiyou_extensions_repo/extractors/gogo_cdn.dart';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

class GogoAnime extends BasePluginApi {
  GogoAnime();

  @override
  String get baseUrl => 'https://anitaku.to';

  final ajaxUrl = 'https://ajax.gogo-load.com';

  // ============================== HomePage ===================================
  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Popular Ongoing':
            '${this.ajaxUrl}/ajax/page-recent-release-ongoing.html',
        'Latest Episodes': '${this.ajaxUrl}/ajax/page-recent-release.html',
        'Popular Anime': '${this.baseUrl}/popular.html',
      });

  // ============================== LoadHomePage ===============================
  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) async {
    return HomePage(
        data: HomePageList(
            name: request.name, data: await getHomePageListData(page, request)),
        page: page);
  }

  Future<List<SearchResponse>> getHomePageListData(
      int page, HomePageRequest request) async {
    if (request.name == 'Popular Ongoing') {
      return getPopularOnGoing(page, request);
    } else if (request.name == 'Popular Anime') {
      return getPopularPage(page, request);
    } else {
      return getRecentReleased(page, request);
    }
  }

  Future<List<SearchResponse>> getPopularPage(
      int page, HomePageRequest request) async {
    final res = await AppUtils.httpRequest(
        url: '${request.data}?page=$page', method: 'GET');

    return parseHomePage(res.document);
  }

  Future<List<SearchResponse>> getRecentReleased(
      int page, HomePageRequest request) async {
    final res = await AppUtils.httpRequest(
        url: '${request.data}?page=$page&type=2', method: 'GET');
    return parseRecentReleased(res.document);
  }

  List<SearchResponse> parseRecentReleased(DocumentObject doc) {
    return ListUtils.map<ElementObject, SearchResponse>(
        doc.select('.last_episodes.loaddub > .items > li'), (e) {
      e as ElementObject;
      final a = e.selectFirst(' p.name > a');
      return SearchResponse(
        title: a.text(),
        url: this.baseUrl + a.attr('href'),
        poster: e.selectFirst('.img > a > img').attr('src'),
        type: ShowType.Anime,
        current: StringUtils.toIntOrNull(StringUtils.substringAfter(
                e.selectFirst('p.episode').text(), 'Episode')
            .trim()),
      );
    });
  }

  Future<List<SearchResponse>> getPopularOnGoing(
      int page, HomePageRequest request) async {
    final res = await AppUtils.httpRequest(
        url: '${request.data}?page=$page', method: 'GET');

    return parsePopularOnGoing(res.document);
  }

  List<SearchResponse> parsePopularOnGoing(DocumentObject doc) {
    return ListUtils.map<ElementObject, SearchResponse>(
        doc.select(".added_series_body.popular > ul > li"), (e) {
      e as ElementObject;
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
    });
  }

  List<SearchResponse> parseHomePage(DocumentObject doc) {
    return ListUtils.map(doc.select("div > ul.items > li"), (e) {
      e as ElementObject;
      final a = e.selectFirst('p.name > a');
      return SearchResponse(
          title: a.text(),
          url: this.baseUrl + a.attr('href'),
          poster: e.selectFirst('div.img > a > img').attr('src'),
          type: ShowType.Anime);
    });
  }

  // =========================== LoadMediaDetails ==============================
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
        episodes: ListUtils.map(
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

  // =============================== LoadLinks =================================
  @override
  Future<List<ExtractorLink>> loadLinks(String url) async {
    return ListUtils.map(
        (await AppUtils.httpRequest(url: url, method: 'GET'))
            .document
            .select('.anime_muti_link > ul > li > a'), (it) {
      return toExtractorLink(it);
    });
  }

  // =============================== LoadMedia =================================
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

  // ============================== Search ===============================

  @override
  Future<List<SearchResponse>> search(String query) async {
    final doc = (await AppUtils.httpRequest(
            url:
                '${this.baseUrl}/search.html?keyword=${AppUtils.encode(query)}',
            method: 'GET'))
        .document;

    return ListUtils.map(doc.select('.items > li'), (it) {
      return toSearchResponse(it);
    });
  }

  // ============================== Helpers ===============================

  List<String> getGeneres(List<ElementObject> elements) {
    return ListUtils.map<ElementObject, String>(elements, (it) {
      return (it as ElementObject).attr('title');
    });
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
