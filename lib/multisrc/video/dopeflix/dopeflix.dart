// ignore_for_file: unnecessary_cast

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

abstract class Dopeflix extends ParsedHttpSource {
  Dopeflix({
    required this.name,
    required this.lang,
    required this.domainList,
    required this.defaultDomain,
  });

  @override
  final String name;

  @override
  final String lang;

  final List<String> domainList;

  final String defaultDomain;

  @override
  String get baseUrl => this
      .preferences
      .getString(Preferences.PREF_DOMAIN_KEY, this.defaultDomain)!;

  @override
  HeadersBuilder headersBuilder() =>
      super.headersBuilder().add("Referer", "${this.baseUrl}/");

  // ============================== HomePage ===================================
  @override
  List<HomePageRequest> homePageRequests() {
    return [
      HomePageRequest(name: 'Home', data: 'home'),
    ];
  }

  @override
  HomePage homePageParse(int page, HomePageRequest request, Response response) {
    final document = response.body.document;

    final banner = ListUtils.mapList(
        document.select('.swiper-slide > .slide-caption-wrap > .slide-caption'),
        (e) {
      e as Element;

      final title = e.selectFirst('.film-title > a')!;
      final url = title.attr('href')!;
      return ContentItem(
        title: title.text,
        url: url,
        poster: e.selectFirst('.film-poster > img')!.attr('src')!,
        category: getCategory(url),
        description: e.selectFirst('.sc-desc')!.text,
        rating: StringUtils.toDoubleOrNull(
          e.selectFirst('.sc-detail > div.scd-item:nth-child(1)')!.text,
        ),
      );
    });

    final trendingMovie = ListUtils.mapList(
        document.select(trendingSelector('trending-movies')),
        (e) => contentItemFromElement(e));

    final trendingSeries = ListUtils.mapList(
        document.select(trendingSelector('trending-tv')),
        (e) => contentItemFromElement(e));

    final latestMovies = ListUtils.mapList(
        document.select(latestSelector(true)),
        (e) => contentItemFromElement(e));

    final latestSeries = ListUtils.mapList(
        document.select(latestSelector(false)),
        (e) => contentItemFromElement(e));

    return HomePage(
      data: [
        HomePageData(name: 'Banner', items: banner, horizontalImages: false),
        HomePageData(
            name: 'Trending Movies',
            items: trendingMovie,
            horizontalImages: false),
        HomePageData(
            name: 'Trending Series',
            items: trendingSeries,
            horizontalImages: false),
        HomePageData(
            name: 'Latest Movies',
            items: latestMovies,
            horizontalImages: false),
        HomePageData(
            name: 'Latest Series',
            items: latestSeries,
            horizontalImages: false),
      ],
      hasNextPage: false,
    );
  }

  String latestSelector(bool movie) {
    final index = (movie) ? 6 : 7;
    return 'section.block_area:nth-child($index) > div:nth-child(2) > div';
  }

  String trendingSelector(String name) {
    return 'section.block_area.block_area_home.section-id-01 > .tab-content > div#$name > div > div';
  }

  ContentItem contentItemFromElement(Element element) {
    final a = element.selectFirst('a')!;
    final url = a.attr('href')!;
    return ContentItem(
      title: a.attr('title')!,
      poster: element.selectFirst('img')!.attr('data-src')!,
      url: this.baseUrl + url,
      category: getCategory(url),
    );
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    return GET(
      '${this.baseUrl}/${request.data}',
      headers: this.headers,
    );
  }

  @override
  String homePageDataSelector(int page, HomePageRequest request) {
    throw UnsupportedError('Not Used');
  }

  @override
  String homePageNextPageSelector(int page, HomePageRequest request) {
    throw UnsupportedError('Not Used');
  }

  @override
  HomePageData homePageDataFromElement(
      int page, HomePageRequest request, Element element) {
    throw UnsupportedError('Not used');
  }

  @override
  Request infoPageRequest(ContentItem contentItem) =>
      GET('${this.baseUrl}/${contentItem.url}', headers: this.headers);

  @override
  Future<InfoPage> infoPageFromDocument(
      ContentItem contentItem, Document document) async {
    final rating = StringUtils.toDoubleOrNull(StringUtils.substringAfter(
        document.selectFirst('.imdb)')!.text, 'IMDB: '));

    final description = document
        .selectFirst('.description')!
        .text
        .replaceFirst('Overview:', '')
        .trim();

    final elements = document.select('.elements > div > div > .row-line');

    List<String>? genres;
    DateTime? startDate;
    List<Character>? cast;
    Duration? duration;

    for (var e in elements) {
      final type = e.selectFirst('span.type > strong')!.text.trim();

      if (type == 'Genre:') {
        genres = ListUtils.mapList(
            e.select('a'), (e) => (e as Element).attr('title')!);
      } else if (type == 'Released:') {
        startDate =
            DateTime.tryParse(e.text.replaceFirst('Released:', '').trim());
      } else if (type == 'Casts:') {
        cast = ListUtils.mapList(
            e.select('a'), (e) => Character(name: (e as Element).text));
      } else if (type == 'Duration:') {
        duration = AppUtils.tryParseDuration(
            e.text.replaceFirst('Duration:', '').trim(), 'min');
      }
    }

    final recommendations = ListUtils.mapList(
        document.select('div.flw-item > div.film-poster'),
        (e) => contentItemFromElement(e));

    final Content content;
    if (contentItem.category == ContentCategory.Movie) {
      content = getMovie(contentItem.url);
    } else {
      content = await getSeries(contentItem.url);
    }

    return InfoPage.withItem(
      contentItem,
      genres: genres,
      startDate: startDate,
      rating: rating,
      description: description,
      characters: cast,
      duration: duration,
      recommendations: recommendations,
      content: content,
    );
  }

  Movie getMovie(String id) =>
      Movie(url: '${this.baseUrl}/ajax/episode/list/$id');

  Request seriesRequest(String id) =>
      GET('${this.baseUrl}/ajax/season/list/$id', headers: this.headers);

  Future<Series> getSeries(String id) async {
    final List<SeasonList> results = [];
    final response = await client.newCall(seriesRequest(id)).execute();
    final seasonsList = response.body.document
        .select('div.dropdown-menu.dropdown-menu-model > a');
    for (var s in seasonsList) {
      results.add(
        SeasonList(
          season: Season(
            number: num.tryParse(StringUtils.substringAfter(s.text, 'Season ')),
          ),
          episodes: await getEpisodes(s.attr('data-id')!),
        ),
      );
    }

    return Series(results);
  }

  Request episodeListRequest(String id) {
    return GET(
      '/ajax/season/episodes/$id',
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
      number: num.tryParse(episode ?? ''),
      name: details.selectFirst('h3.film-name')!.text.trimLeft().trimRight(),
    );
  }

  // ============================== LoadLinks ===================================

  @override
  Request contentDataLinksRequest(String url) =>
      GET(this.baseUrl + url, headers: this.headers);

  @override
  String contentDataLinkSelector(String url) => 'ul.ulclear.fss-list > li > a';

  @override
  Future<List<ContentDataLink>> getContentDataLinks(String url) async {
    final response =
        await client.newCall(contentDataLinksRequest(url)).execute();

    final document = response.body.document;
    final servers = document.select(contentDataLinkSelector(url));
    final episodeReferer =
        Headers.fromMap({"Referer": response.request.headers["referer"]!});

    final List<ContentDataLink> links = [];
    for (var s in servers) {
      final String url = await client
          .newCall(GET(
            '${this.baseUrl}/ajax/sources/${s.attr("data-id")}',
            headers: episodeReferer,
          ))
          .execute()
          .then(
              (value) => (value as Response).body.json((json) => json['link']));

      links.add(ContentDataLink(
        data: url,
        name: s.text.replaceFirst('Server', '').trimLeft().trimRight(),
      ));
    }

    return links;
  }

  @override
  ContentDataLink contentDataLinkFromElement(String url, Element element) {
    throw UnsupportedError('Not used');
  }

  // List<ExtractorLink> sortLinks(List<ExtractorLink> links) {
  //   final server = this.preferences.getString(
  //       Preferences.pref_server_key, Preferences.pref_server_default);

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
  Future<ContentData?> getContentData(ContentDataLink link) async {
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
    //     .getString("pref_quality_key", Preferences.pref_quality_key)!;
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
  String searchPageItemSelector(int page, String query, FilterList filters) =>
      ''; // contentItemSelector();

  @override
  String? searchPageNextPageSelector(
      int page, String query, FilterList filters) {
    throw UnimplementedError();
  }

  @override
  ContentItem searchPageItemFromElement(
      int page, String query, FilterList filters, Element element) {
    return ContentItem(
      title: element.selectFirst('p.name > a')!.text,
      url: this.baseUrl + element.selectFirst('div.img > a')!.attr('href')!,
      poster: element.selectFirst('div.img > a > img')!.attr('src')!,
      category: ContentCategory.Anime,
    );
  }

  // ============================== Helpers ===============================

  List<String> getGeneres(List<Element> elements) {
    return ListUtils.mapList<Element, String>(elements, (it) {
      return (it as Element).attr('title')!;
    });
  }

  ContentCategory getCategory(String t) {
    if (t.contains('/movie/')) {
      return ContentCategory.Movie;
    }
    return ContentCategory.TvSeries;
  }
}

// ============================== Preferences ===================================

@override
List<PreferenceData> setupPreferences() {
  return [];
  // return [
  //   EditTextPreference(
  //     key: Preferences.pref_domain_key,
  //     title: Preferences.pref_domain_title,
  //     value: Preferences.pref_domain_default,
  //     dialogTitle: Preferences.pref_domain_title,
  //     dialogMessage: Preferences.PREF_DOMAIN_DIALOG_MESSAGE,
  //     summary: Preferences.pref_domain_summary,
  //   ),
  //   ListPreference(
  //     key: Preferences.pref_quality_key,
  //     title: Preferences.pref_quality_title,
  //     entries: Preferences.pref_quality_entries,
  //     entryValues: Preferences.pref_quality_values,
  //     summary: '',
  //   ),
  //   ListPreference(
  //     key: Preferences.pref_server_key,
  //     title: Preferences.pref_server_title,
  //     entries: Preferences.hosters,
  //     entryValues: Preferences.hosters,
  //     summary: '',
  //   ),
  //   MultiSelectListPreference(
  //     key: Preferences.pref_hoster_key,
  //     title: Preferences.pref_hoster_title,
  //     entries: Preferences.hosters,
  //     entryValues: Preferences.hosters_names,
  //     summary: '',
  //     defaultSelected: Preferences.pref_hoster_default,
  //   )
  // ];
}
