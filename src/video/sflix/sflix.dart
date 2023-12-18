// ignore_for_file: unnecessary_this

import 'dart:convert';

import 'package:meiyou_extensions_repo/extractors/rabbit_stream.dart';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

main() {
  return Sflix();
}

class Sflix extends BasePluginApi {
  Sflix();

  @override
  String get baseUrl => 'https://sflix.to';

  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({});

  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) {
    // TODO: implement loadHomePage
    throw UnimplementedError();
  }

  @override
  Future<List<ExtractorLink>> loadLinks(String url) async {
    final servers = (await AppUtils.httpRequest(
            url: url,
            method: 'GET',
            headers: {"X-Requested-With": "XMLHttpRequest"}))
        .document
        .select('ul.ulclear.fss-list > li > a');

    final List<ExtractorLink> list = [];
    for (var e in servers) {
      final link = (await AppUtils.httpRequest(
              url: '${this.baseUrl}/ajax/sources/${e.attr("data-id")}',
              method: 'GET',
              headers: {"X-Requested-With": "XMLHttpRequest"}))
          .json((j) => StringUtils.valueToString(j['link']));

      try {
        list.add(ExtractorLink(
            url: link,
            name:
                StringUtils.trimNewLines(e.text().replaceFirst('Server', ''))));
      } catch (e) {
        print(e);
      }
    }
    return list;
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
    final page = (await AppUtils.httpRequest(
            url: this.baseUrl + searchResponse.url,
            method: 'GET',
            referer: '${this.baseUrl}/home'))
        .document;
    final media = MediaDetails();

    media.copyFromSearchResponse(searchResponse);

    media.rating = StringUtils.toDoubleOrNull(StringUtils.substringAfter(
        page.selectFirst('.imdb)').text(), 'IMDB: '));

    media.description = page
        .selectFirst('.description')
        .text()
        .replaceFirst('Overview:', '')
        .trim();

    final elements = page.select('.elements > div > div > .row-line');

    for (var e in elements) {
      final type = e.selectFirst('span.type > strong').text().trim();

      if (type == 'Genre:') {
        media.genres = AppUtils.selectMultiAttr(e.select('a'), 'title');
      } else if (type == 'Released:') {
        media.startDate =
            DateTime.tryParse(e.text().replaceFirst('Released:', '').trim());
      } else if (type == 'Casts:') {
        media.actorData = ListUtils.map(e.select('a'), (e) {
          return toActorData(e);
        });
      } else if (type == 'Duration:') {
        media.duration =
            parseDuation(e.text().replaceFirst('Duration:', '').trim());
      }
    }

    media.recommendations =
        ListUtils.map(page.select('div.flw-item > div.film-poster'), (e) {
      return toSearchResponse(e);
    });

    if (searchResponse.type == ShowType.Movie) {
      media.mediaItem = getMovie(extractIdFromUrl(searchResponse.url));
    } else {
      media.mediaItem = await getTV(extractIdFromUrl(searchResponse.url));
    }

    return media;
  }

  Future<TvSeries> getTV(String id) async {
    final List<SeasonList> results = [];
    final seasonsList = (await AppUtils.httpRequest(
            url: '${this.baseUrl}/ajax/season/list/$id', method: 'GET'))
        .document
        .select('div.dropdown-menu.dropdown-menu-model > a');
    for (var s in seasonsList) {
      results.add(SeasonList(
          season: SeasonData(
            season:
                num.tryParse(StringUtils.substringAfter(s.text(), 'Season ')),
          ),
          episodes: await getEpisodes(s.attr('data-id'))));
    }

    return TvSeries(data: results);
  }

  Episode toEpisode(ElementObject e) {
    final details = e.selectFirst('div.film-detail');
    final img = e.selectFirst('a > img').attr('src');
    var episode = RegExp(r'\d+')
        .firstMatch(details.selectFirst('div.episode-number').text())
        ?.group(0);

    return Episode(
      data: '${this.baseUrl}/ajax/episode/servers/${e.attr('data-id')}',
      posterImage: img,
      episode: num.tryParse(episode ?? ''),
      name:
          StringUtils.trimNewLines(details.selectFirst('h3.film-name').text()),
    );
  }

  Future<List<Episode>> getEpisodes(String id) async {
    return ListUtils.map(
        (await AppUtils.httpRequest(
                url: '${this.baseUrl}/ajax/season/episodes/$id', method: 'GET'))
            .document
            .select('div.swiper-container > div > div > div'), (e) {
      return toEpisode(e);
    });
  }

  Movie getMovie(String id) {
    return Movie(url: '${this.baseUrl}/ajax/episode/list/$id');
  }

  Duration? parseDuation(String s) {
    final min =
        StringUtils.toIntOrNull(StringUtils.substringBefore(s, 'min').trim());
    if (min == null) {
      return null;
    }
    return Duration(minutes: min);
  }

  String extractIdFromUrl(String url) {
    return StringUtils.substringAfterLast(url, '-');
  }

  ActorData toActorData(ElementObject e) {
    return ActorData(name: e.attr('title'));
  }

  @override
  Future<List<SearchResponse>> search(String query) async {
    return ListUtils.map(
        (await AppUtils.httpRequest(
          url: '${this.baseUrl}/search/${AppUtils.encode(query, "-")}',
          method: 'GET',
          referer: '${this.baseUrl}/',
        ))
            .document
            .select('div.flw-item > div.film-poster'), (e) {
      return toSearchResponse(e);
    });
  }

  SearchResponse toSearchResponse(ElementObject e) {
    final a = e.selectFirst('a');
    final url = a.attr('href');
    return SearchResponse(
      title: a.attr('title'),
      poster: e.selectFirst('img').attr('data-src'),
      url: this.baseUrl + url,
      type: getType(url),
    );
  }

  ShowType getType(String s) {
    if (s.contains('movie')) {
      return ShowType.Movie;
    }
    return ShowType.TvSeries;
  }
}
