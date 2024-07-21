// ignore_for_file: unnecessary_cast

import 'dart:convert';

import 'package:meiyou_extensions/multisrc/video/dopeflix/dopeflix_extractor.dart';
import 'package:meiyou_extensions/multisrc/video/dopeflix/preferences.dart';
import 'package:meiyou_extensions_lib/html_extensions.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:html/dom.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/preference.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

void main(List<String> args) async {
  final sflix = Sflix();
  final previewMovie = MediaPreview.fromJson(jsonDecode(r'''
     {
          "title": "The Fall Guy",
          "url": "/movie/free-the-fall-guy-hd-108544",
          "poster": "https://img.sflix.to/xxrz/250x400/224/ee/68/ee684b0d95199c3339042481307386c9/ee684b0d95199c3339042481307386c9.jpg",
          "format": "movie",
          "description": "Fresh off an almost career-ending accident, stuntman Colt Seavers has to track down a missing movie star, solve a conspiracy and try to win back the love of his life while still doing his day job.",
          "generes": null,
          "rating": 7.2
        }
'''));

  final previewTv = MediaPreview.fromJson(jsonDecode(r'''
{
          "title": "Sweet Home",
          "url": "/tv/free-sweet-home-hd-66340",
          "poster": "https://img.sflix.to/xxrz/250x400/224/0b/2c/0b2cdbad906aef277298af56bf13ab9e/0b2cdbad906aef277298af56bf13ab9e.jpg",
          "format": "tvSeries",
          "description": null,
          "generes": null,
          "rating": null
        }
'''));
  final baseDetails = MediaDetails(
    title: previewMovie.title,
    poster: previewMovie.poster,
    description: previewMovie.description,
    genres: previewMovie.generes,
    format: previewMovie.format,
    url: previewMovie.url,
  );

  final mediaDetails = await sflix.getMediaDetails(baseDetails);

  print(mediaDetails);

  final content = (await sflix.getMediaContent(baseDetails)) as Movie;

  print(content);

  final links = await sflix.getMediaLinks(content.playUrl);

  print(links);

  final media = await sflix.getMedia(links.first);

  print(media);
}

class Sflix extends Dopeflix {
  Sflix();

  @override
  final String name = "SFlix";

  @override
  final String lang = "en";

  @override
  final List<String> domainList = ["https://sflix.to", "https://sflix.se"];

  @override
  final String defaultDomain = "https://sflix.to";

  @override
  int get id => 8615824918772726940;
}

abstract class Dopeflix extends ParsedHttpSource {
  Dopeflix();

  @override
  abstract final String name;

  @override
  abstract final String lang;

  abstract final List<String> domainList;

  abstract final String defaultDomain;

  @override
  String get baseUrl => this
      .preferences
      .getString(DopeFlixPreferences.PREF_DOMAIN_KEY, this.defaultDomain)!;

  @override
  HeadersBuilder headersBuilder() =>
      super.headersBuilder().add("Referer", "${this.baseUrl}/");

  // ============================== HomePage ===================================
  @override
  List<HomePageRequest> homePageRequests() {
    return [
      HomePageRequest(title: 'Home', data: 'home'),
    ];
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    return GET(
      '${this.baseUrl}/${request.data}',
      headers: this.headers,
    );
  }

  @override
  HomePage homePageParse(HomePageRequest request, Response response) {
    final document = response.body.document;

    final banner = HomePageList(
      title: 'Banner',
      list: ListUtils.mapList(document.select(bannerSelector()), (e) {
        e as Element;

        final title = e.selectFirst('.film-title > a')!;
        final url = title.attr('href')!;
        return MediaPreview(
          title: title.text,
          url: url,
          poster: e.selectFirst('.film-poster > img')!.attr('src')!,
          format: getFormat(url),
          description: e.selectFirst('p.sc-desc')!.text,
          rating: StringUtils.toDoubleOrNull(
            e.selectFirst('.sc-detail > div.scd-item:nth-child(1)')!.text,
          ),
        );
      }),
    );

    final trendingMovie = HomePageList(
      title: 'Trending Movie',
      list: ListUtils.mapList(document.select(trendingSelector(true)),
          (e) => searchItemFromElement(e)),
    );

    final trendingSeries = HomePageList(
      title: 'Trending Tv Series',
      list: ListUtils.mapList(document.select(trendingSelector(false)),
          (e) => searchItemFromElement(e)),
    );

    final List<HomePageList> items = [];

    items.add(banner);

    items.add(trendingMovie);

    items.add(trendingSeries);

    final homePageLists = ListUtils.mapList(
        document.select(homeListSelector(request)),
        (e) => homeListFromElement(request, e));

    items.addAll(homePageLists);

    return HomePage(
      items: items,
      hasNextPage: false,
    );
  }

  String bannerSelector() =>
      '.swiper-slide > .slide-caption-wrap > .slide-caption';

  String trendingSelector(bool movie) {
    final index = (movie) ? 1 : 2;
    final id = (movie) ? 'movies' : 'tv';
    return 'section.block_area.block_area_home.section-id-0$index > .tab-content > #trending-$id > div > div.film_list-wrap > div.flw-item';
  }

  @override
  String homeListSelector(HomePageRequest request) =>
      'section.block_area.block_area_home.section-id-02';

  @override
  HomePageList homeListFromElement(HomePageRequest request, Element element) {
    final title = element.selectFirst('div > div > h2')!.text;

    final list =
        ListUtils.mapList(element.select(homePageItemSelector(request)), (e) {
      e as Element;
      return homePageItemFromElement(request, element);
    });

    return HomePageList(title: title, list: list);
  }

  @override
  String homePageItemSelector(HomePageRequest request) =>
      'div > div.film_list-wrap > div.flw-item';

  @override
  MediaPreview homePageItemFromElement(
      HomePageRequest request, Element element) {
    return searchItemFromElement(element);
  }

  @override
  String homeNextPageSelector(HomePageRequest request) {
    throw UnsupportedError('Not Used');
  }

  @override
  MediaDetails mediaDetailsFromDocument(Document document) {
    final mediaDetails = MediaDetails();

    mediaDetails.score = StringUtils.toDoubleOrNull(StringUtils.substringAfter(
        document.selectFirst('.imdb)')!.text, 'IMDB: '));

    mediaDetails.description = document
        .selectFirst('.description')!
        .text
        .replaceFirst('Overview:', '')
        .trim();

    mediaDetails.genres = ListUtils.mapList(
        document.select('.elements > div > div > .row-line > a'),
        (e) => (e as Element).text);

    return mediaDetails;
  }

  Movie getMovie(String id) => Movie(playUrl: '/ajax/episode/list/$id');

  Request seriesRequest(String id) =>
      GET('${this.baseUrl}/ajax/season/list/$id', headers: this.headers);

  @override
  Request mediaContentRequest(MediaDetails mediaDetails) {
    return seriesRequest(extractIdFromUrl(mediaDetails.url));
  }

  @override
  Future<MediaContent> getMediaContent(MediaDetails mediaDetails) async {
    if (mediaDetails.format == MediaFormat.movie) {
      return getMovie(extractIdFromUrl(mediaDetails.url));
    }
    return await super.getMediaContent(mediaDetails);
  }

  String extractIdFromUrl(String url) {
    return StringUtils.substringAfterLast(url, '-');
  }

  @override
  MediaContent mediaContentParse(Response response) {
    throw UnsupportedError('Not Used');
  }

  @override
  Future<MediaContent> mediaContentParseAsync(Response response) async {
    final document = response.body.document;
    final List<Season> results = [];
    final seasonsList =
        document.select('div.dropdown-menu.dropdown-menu-model > a');

    for (var s in seasonsList) {
      results.add(
        Season(
          number: int.tryParse(StringUtils.substringAfter(s.text, 'Season ')),
          episodes: await getEpisodes(s.attr('data-id')!),
        ),
      );
    }

    return TvSeries(seasons: results);
  }

  @override
  MediaContent mediaContentFromDocument(Document document) {
    throw UnsupportedError('Not Used');
  }

  Request episodeListRequest(String id) {
    return GET(
      '${this.baseUrl}/ajax/season/episodes/$id',
      headers: this.headers,
    );
  }

  Future<List<Episode>> getEpisodes(String id) async {
    final response = await client.newCall(episodeListRequest(id)).execute();

    return ListUtils.mapList(
        response.body.document.select('div.swiper-container > div > div > div'),
        (e) => episodeFromElement(e));
  }

  Episode episodeFromElement(Element e) {
    final details = e.selectFirst('div.film-detail');
    final img = e.selectFirst('a > img')!.attr('src')!;
    var episode = RegExp(r'\d+')
        .firstMatch(details!.selectFirst('div.episode-number')!.text)
        ?.group(0);

    return Episode(
      data: '/ajax/episode/servers/${e.attr('data-id')}',
      image: img,
      number: int.tryParse(episode ?? ''),
      name: details.selectFirst('h3.film-name')!.text.trimLeft().trimRight(),
    );
  }

  // ============================== LoadLinks ===================================

  @override
  Request mediaLinksRequest(String data) =>
      GET(this.baseUrl + data, headers: this.headers);

  @override
  String mediaLinkSelector() => 'ul.ulclear.fss-list > li > a';

  @override
  List<MediaLink> medialinksParse(Response response) {
    throw UnsupportedError('Not used');
  }

  @override
  Future<List<MediaLink>> medialinksParseAsync(Response response) async {
    final document = response.body.document;
    final servers = document.select(mediaLinkSelector());
    final episodeReferer =
        Headers.fromMap({"Referer": response.request.headers["referer"]!});

    final List<MediaLink> links = [];
    for (var s in servers) {
      final String url = await client
          .newCall(GET(
            '${this.baseUrl}/ajax/sources/${s.attr("data-id")}',
            headers: episodeReferer,
          ))
          .execute()
          .then(
              (value) => (value as Response).body.json((json) => json['link']));

      links.add(MediaLink(
        data: url,
        name: s.text.replaceFirst('Server', '').trimLeft().trimRight(),
      ));
    }

    return links;
  }

  @override
  MediaLink mediaLinkFromElement(Element element) {
    throw UnsupportedError('Not used');
  }

  // List<ExtractorLink> sortLinks(List<ExtractorLink> links) {
  //   final server = this.preferences.getString(
  //       DopeFlixPreferences.Preferences.pref_server_key, DopeFlixPreferences.Preferences.pref_server_default);

  //   return links
  //     ..sort((a, b) {
  //       a as ExtractorLink;
  //       b as ExtractorLink;
  //       if (a.name == server) {
  //         return 1;
  //       } else if (b.name == server) {
  //         return -1;
  //       } else {
  //         return 0;
  //       }
  //     });
  // }

  DopeFlixExtractor get dopeFlixExtractor => DopeFlixExtractor(this.client);

  @override
  Future<Media?> getMedia(MediaLink link) async {
    final url = link.data;
    if (url.contains('doki')) {
      return dopeFlixExtractor.extract(link);
    } else if (url.contains('rabbit')) {
      return dopeFlixExtractor.extract(link);
    } else {
      return null;
    }
  }

  List<VideoSource> sortVideoSources(List<VideoSource> sources) {
    // final qualityStr = this
    //     .preferences
    //     .getString("pref_quality_key", DopeFlixPreferences.Preferences.pref_quality_key)!;
    // final quality = VideoQuality.getFromString(qualityStr);
    return sources;
    // ..sort((a, b) {
    //   a as VideoSource;
    //   // b as VideoSource;
    //   if (a.quality != null) {
    //     return a.quality!.compareTo(quality);
    //   }
    //   return 0;
    // });
  }

  // ============================== Search ===============================
  @override
  FilterList getFilterList() {
    return FilterList([HeaderFilter('idk')]);
  }

  @override
  Request searchPageRequest(int page, String query, FilterList filters) {
    return GET('${this.baseUrl}/search.html?keyword=$query',
        headers: this.headers);
  }

  @override
  String searchItemSelector() => ''; // contentItemSelector();

  @override
  String? searchNextPageSelector() {
    throw UnimplementedError();
  }

  @override
  MediaPreview searchItemFromElement(Element element) {
    final a = element.selectFirst('a')!;
    final url = a.attr('href')!;
    return MediaPreview(
      title: a.attr('title')!,
      poster: element.selectFirst('img')!.attr('data-src')!,
      url: url,
      format: getFormat(url),
    );

    // final url = element.selectFirst('div.img > a')!.attr('href')!;
    // return MediaPreview(
    //   title: element.selectFirst('p.name > a')!.text,
    //   url: this.baseUrl + url,
    //   poster: element.selectFirst('div.img > a > img')!.attr('src')!,
    //   format: getFormat(url),
    // );
  }

  // ============================== Helpers ===============================

  List<String> getGeneres(List<Element> elements) {
    return ListUtils.mapList<Element, String>(elements, (it) {
      return (it as Element).attr('title')!;
    });
  }

  MediaFormat getFormat(String url) {
    if (url.contains('/movie/')) {
      return MediaFormat.movie;
    }
    return MediaFormat.tvSeries;
  }
}

// ============================== DopeFlixPreferences.Preferences ===================================

@override
List<PreferenceData> setupPreferences() {
  return [];
  // return [
  //   EditTextPreference(
  //     key: DopeFlixPreferences.Preferences.pref_domain_key,
  //     title: DopeFlixPreferences.Preferences.pref_domain_title,
  //     value: DopeFlixPreferences.Preferences.pref_domain_default,
  //     dialogTitle: DopeFlixPreferences.Preferences.pref_domain_title,
  //     dialogMessage: DopeFlixPreferences.Preferences.PREF_DOMAIN_DIALOG_MESSAGE,
  //     summary: DopeFlixPreferences.Preferences.pref_domain_summary,
  //   ),
  //   ListPreference(
  //     key: DopeFlixPreferences.Preferences.pref_quality_key,
  //     title: DopeFlixPreferences.Preferences.pref_quality_title,
  //     entries: DopeFlixPreferences.Preferences.pref_quality_entries,
  //     entryValues: DopeFlixPreferences.Preferences.pref_quality_values,
  //     summary: '',
  //   ),
  //   ListPreference(
  //     key: DopeFlixPreferences.Preferences.pref_server_key,
  //     title: DopeFlixPreferences.Preferences.pref_server_title,
  //     entries: DopeFlixPreferences.Preferences.hosters,
  //     entryValues: DopeFlixPreferences.Preferences.hosters,
  //     summary: '',
  //   ),
  //   MultiSelectListPreference(
  //     key: DopeFlixPreferences.Preferences.pref_hoster_key,
  //     title: DopeFlixPreferences.Preferences.pref_hoster_title,
  //     entries: DopeFlixPreferences.Preferences.hosters,
  //     entryValues: DopeFlixPreferences.Preferences.hosters_names,
  //     summary: '',
  //     defaultSelected: DopeFlixPreferences.Preferences.pref_hoster_default,
  //   )
  // ];
}
