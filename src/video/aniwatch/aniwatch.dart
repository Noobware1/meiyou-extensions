// ignore_for_file: unnecessary_this
import 'package:meiyou_extensions_repo/extractors/mega_cloud.dart';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

class AniWatch extends BasePluginApi {
  AniWatch();

  @override
  String get baseUrl => 'https://aniwatch.to';

  Map<String, String> apiheaders(String referer) {
    return {
      "Accept": "*/*",
      "Host": Uri.parse(baseUrl).host,
      "Referer": referer,
      "X-Requested-With": "XMLHttpRequest"
    };
  }

  Map<String, String> get embedHeaders => {"referer": '${this.baseUrl}/'};

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'Trending': '${this.baseUrl}/home',
        'Latest Episodes': '${this.baseUrl}/recently-updated',
        'Top Airing': '${this.baseUrl}/top-airing',
        'Most Popular': '${this.baseUrl}/most-popular',
        'New on Aniwatch': '${this.baseUrl}/recently-added',
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
        .select('.deslide-item');
    final data = ListUtils.map(list, (e) {
      return parseTrending(e);
    });

    return HomePage(
        data: HomePageList(name: request.name, data: data),
        page: 1,
        hasNextPage: false);
  }

  SearchResponse parseTrending(ElementObject e) {
    final content = e.selectFirst('.deslide-item-content');

    return SearchResponse(
        title: content.selectFirst('div.desi-head-title.dynamic-name').text(),
        url: content
            .selectFirst('.desi-buttons > .btn.btn-secondary.btn-radius')
            .attr('href'),
        poster: e.selectFirst('.deslide-cover > div > img').attr('data-src'),
        type: getType(content.selectFirst('.sc-detail > div').text()),
        description: content.selectFirst('.desi-description').text().trim());
  }

  @override
  Future<List<SearchResponse>> search(String query) {
    return parseSearchResponse(
        '${this.baseUrl}/search?keyword=${AppUtils.encode(query)}');
  }

  Future<List<SearchResponse>> parseSearchResponse(String url) async {
    final list = (await AppUtils.httpRequest(url: url, method: 'GET'))
        .document
        .select('div.film_list-wrap > div.flw-item');
    return ListUtils.map(list, (it) {
      return toSearchResponse(it);
    });
  }

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final fixUrl = '${this.baseUrl}${searchResponse.url}';
    final animePage =
        (await AppUtils.httpRequest(url: fixUrl, method: 'GET')).document;
    final media = MediaDetails();

    media.copyFromSearchResponse(searchResponse);

    media.url = fixUrl;

    media.name = searchResponse.title;

    media.url = searchResponse.url;

    media.posterImage =
        animePage.selectFirst('.anis-content > div > div > img').attr('src');

    media.type = getType(animePage.selectFirst('div.tick > span.item').text());

    final info = animePage.select('.anisc-info > div')..removeLast();

    for (var e in info) {
      final head = e.selectFirst('.item-head').text().trim();

      if (head == 'Aired:') {
        final aired = getName(e).split(' ');
        final year = StringUtils.toIntOrNull(aired[2]);
        if (year != null) {
          media.startDate = AppUtils.toDateTime(
            year,
            month: AppUtils.getMonthByName(aired[0]),
            day: StringUtils.toIntOrNull(
              StringUtils.substringBefore(aired[1], ',').trim(),
            ),
          );
        }
      } else if (head == 'Overview:') {
        media.description = e.selectFirst('div.text').text().trim();
      } else if (head == 'Japanese:') {
        media.otherTitles = [getName(e)];
      } else if (head == 'Duration:') {
        media.duration = parseDuration(getName(e));
      } else if (head == 'Status:') {
        media.status = getStatus(getName(e));
      } else if (head == 'MAL Score:') {
        media.rating = StringUtils.toDoubleOrNull(getName(e));
      } else if (head == 'Genres:') {
        media.genres = AppUtils.selectMultiAttr(e.select('a'), 'title');
      }
    }

    media.actorData = ListUtils.map(
        animePage.select('div.bac-list-wrap > div.bac-item > div.per-info.ltr'),
        (it) {
      return toActorData(it);
    });

    media.recommendations = ListUtils.map(
        animePage.select('div.film_list-wrap > div.flw-item'), (it) {
      return toSearchResponse(it);
    });
    media.mediaItem = Anime(episodes: await getEpisodes(searchResponse.url));

    return media;
  }

  @override
  Future<List<ExtractorLink>> loadLinks(String url) async {
    final res = (await AppUtils.httpRequest(
            url: '${this.baseUrl}/ajax/v2/episode/servers?episodeId=$url',
            method: 'GET',
            headers: embedHeaders))
        .json((e) => StringUtils.valueToString(e['html']));

    final servers = AppUtils.parseHtml(res).select('div.item.server-item');

    final List<ExtractorLink> list = [];

    for (var e in servers) {
      final link = (await AppUtils.httpRequest(
              url:
                  '${this.baseUrl}/ajax/v2/episode/sources?id=${e.attr('data-id')}',
              method: 'GET',
              headers: embedHeaders))
          .json((e) => StringUtils.valueToString(e['link']));

      list.add(ExtractorLink(
          url: link,
          name: StringUtils.trimNewLines(
              "${e.attr('data-type').toUpperCase()} - ${e.text()}")));
    }

    return list;
  }

  @override
  Future<Media?> loadMedia(ExtractorLink link) async {
    if (link.url.contains('megacloud')) {
      return MegaCloud(link).extract();
    } else if (link.url.contains('rapidcloud')) {
      return MegaCloud(link).extract();
    }
    return null;
  }

  Future<List<Episode>> getEpisodes(String url) async {
    final response = await AppUtils.httpRequest(
        url: "${this.baseUrl}/ajax/v2/episode/list/${getIdFromUrl(url)}",
        method: 'GET',
        headers: apiheaders(baseUrl + url));

    return ListUtils.map(
        AppUtils.parseHtml(response.json((json) => json['html']))
            .select('div.ss-list > a'), (e) {
      return toEpisode(e);
    });
  }

  Episode toEpisode(ElementObject e) {
    return Episode(
        name: e.attr('title'),
        episode: StringUtils.toNumOrNull(e.attr("data-number")),
        data: e.attr("data-id"),
        isFiller: e.attr('class').contains("ssl-item-filler") == true);
  }

  String getIdFromUrl(String url) {
    return StringUtils.substringAfterLast(
        StringUtils.substringBeforeLast(url, '?'), '-');
  }

// Map<String, String>? getExternalIds(DocumentObject doc) {
//   try {
//     final data = json.decode(doc.selectFirst('#syncData').text());
//     return {
//       'mal': data['mal_id'],
//       'anilist': data['anilist_id'],
//     };
//   } catch (e) {
//     return null;
//   }
// }

  SearchResponse toSearchResponse(ElementObject e) {
    final element = e.selectFirst('.film-poster');
    return SearchResponse(
      title: element.selectFirst("a").attr("title"),
      poster: element.selectFirst("img").attr("data-src"),
      url: element.selectFirst("a").attr("href"),
      type: getType(
        e.selectFirst('div.film-detail > div.fd-infor > span.fdi-item').text(),
      ),
      current: StringUtils.toIntOrNull(
          element.selectFirst(".film-poster >.tick > .tick-sub").text()),
    );
  }

  ActorData toActorData(ElementObject element) {
    return ActorData(
      name: element
          .selectFirst('div.pi-detail > .pi-name')
          .text()
          .replaceFirst(',', ''),
      image: element.selectFirst('a > img').attr('data-src'),
      role: element.selectFirst('div.pi-detail > .pi-cast').text(),
    );
  }

  String getName(ElementObject element) {
    return element.selectFirst('span.name').text().trim();
  }

  Duration? parseDuration(String d) {
    if (d.contains('h')) {
      return AppUtils.tryParseDuration(d, 'hh/mm');
    } else {
      return AppUtils.tryParseDuration(d, 'mm');
    }
  }

  ShowType getType(String t) {
    if (t.contains("OVA")) {
      return ShowType.Ova;
    } else if (t.contains("Special")) {
      return ShowType.Ova;
    } else if (t.contains("Movie")) {
      return ShowType.AnimeMovie;
    } else if (t.contains('ONA')) {
      return ShowType.Ona;
    } else {
      return ShowType.Anime;
    }
  }

  ShowStatus getStatus(String t) {
    if (t.trim() == 'Finished Airing') {
      return ShowStatus.Completed;
    } else {
      return ShowStatus.Ongoing;
    }
  }
}

BasePluginApi main() {
  return AniWatch();
}
