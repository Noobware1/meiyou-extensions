import 'dart:convert';
import 'package:meiyou_extensions_repo/extractors/mega_cloud.dart';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

const hostUrl = 'https://aniwatch.to';

final headers = {
  'X-Requested-With': 'XMLHttpRequest',
  'referer': hostUrl,
};

final embedHeaders = {"referer": '$hostUrl/'};

class AniWatch extends BasePluginApi {
  AniWatch();

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({
        'name': 'key',
      });

  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) async {
    return HomePage(data: HomePageList(name: '', data: []), page: page);
  }

  @override
  Future<List<SearchResponse>> search(String query) async {
    return ListUtils.mapList(
        (await AppUtils.httpRequest(
                url: '$hostUrl/search?keyword=${AppUtils.encode(query)}',
                method: 'GET',
                headers: headers))
            .document
            .select('div.film_list-wrap > div.flw-item'), (it) {
      return toSearchResponse(it);
    });
  }

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) async {
    final animePage = (await AppUtils.httpRequest(
            url: '$hostUrl${searchResponse.url}', method: 'GET'))
        .document;
    final media = MediaDetails();

    media.name = searchResponse.title;

    media.url = searchResponse.url;

    media.posterImage =
        animePage.selectFirst('.anis-content > div > div > img').attr('src');

    media.type = getType(animePage.selectFirst('div.tick > span.item').text());

    final info = animePage.select('.anisc-info > div');
    for (var i = 0; i < info.length - 1; i++) {
      final head = info[i].selectFirst('.item-head').text().trim();

      if (head == 'Aired:') {
        final aired = getName(info[i]).split(' ');
        media.startDate = AppUtils.toDateTime(
          StringUtils.toInt(
            StringUtils.trim(aired[2]),
          ),
          month: AppUtils.getMonthByName(aired[0]),
          day: StringUtils.toInt(StringUtils.trim(
            StringUtils.substringBefore(aired[1], ','),
          )),
        );
      } else if (head == 'Overview:') {
        media.description =
            StringUtils.trim(info[i].selectFirst('div.text').text());
      } else if (head == 'Japanese:') {
        media.otherTitles = [getName(info[i])];
      } else if (head == 'Duration:') {
        media.duration = parseDuration(getName(info[i]));
      } else if (head == 'Status:') {
        media.status = getStatus(getName(info[i]));
      } else if (head == 'MAL Score:') {
        media.rating = StringUtils.toDoubleOrNull(getName(info[i]));
      } else if (head == 'Genres:') {
        media.genres = AppUtils.selectMultiAttr(info[i].select('a'), 'title');
      }
    }

    media.actorData = ListUtils.mapList(
        animePage.select('div.bac-list-wrap > div.bac-item > div.per-info.ltr'),
        (it) {
      return toActorData(it);
    });

    media.recommendations = ListUtils.mapList(
        animePage.select('div.film_list-wrap > div.flw-item'), (it) {
      return toSearchResponse(it);
    });

    media.mediaItem =
        Anime(episodes: await getEpisodes(getIdFromUrl(searchResponse.url)));

    return media;
  }

  @override
  Future<List<ExtractorLink>> loadLinks(String url) async {
    final res = (await AppUtils.httpRequest(
            url: '$hostUrl/ajax/v2/episode/servers?episodeId=$url',
            method: 'GET',
            headers: embedHeaders))
        .json((e) => StringUtils.valueToString(e['html']));

    final servers = AppUtils.parseHtml(res).select('div.item.server-item');

    final List<ExtractorLink> list = [];

    for (var e in servers) {
      final link = (await AppUtils.httpRequest(
              url: '$hostUrl/ajax/v2/episode/sources?id=${e.attr('data-id')}',
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

  Future<List<Episode>> getEpisodes(String id) async {
    return ListUtils.mapList(
        AppUtils.parseHtml(json.decode((await AppUtils.httpRequest(
                    url: "$hostUrl/ajax/v2/episode/list/$id",
                    method: 'GET',
                    headers: headers))
                .text)['html'])
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
        type: getType(e
            .selectFirst('div.film-detail > div.fd-infor > span.fdi-item')
            .text()));
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

  Duration parseDuration(String d) {
    final l = d.toLowerCase().split(' ');
    if (l.length > 1) {
      return Duration(
          hours: StringUtils.toInt(StringUtils.substringBefore(l[0], 'h')),
          minutes: StringUtils.toInt(StringUtils.substringBefore(l[1], 'm')));
    } else {
      return Duration(
          minutes: StringUtils.toInt(StringUtils.substringBefore(l[0], 'm')));
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
    if (t.contains('Finished')) {
      return ShowStatus.Completed;
    } else {
      return ShowStatus.Ongoing;
    }
  }
}

BasePluginApi main() {
  return AniWatch();
}
