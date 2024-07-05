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
      .getString(Preferences.PREF_DOMAIN_KEY, this.defaultDomain)!;

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
  HomePage homePageParse(HomePageRequest request, Response response) {
    final document = response.body.document;

    final banner = ListUtils.mapList(
        document.select('.swiper-slide > .slide-caption-wrap > .slide-caption'),
        (e) {
      e as Element;

      final title = e.selectFirst('.film-title > a')!;
      final url = title.attr('href')!;
      return MediaPreview(
        title: title.text,
        url: url,
        poster: e.selectFirst('.film-poster > img')!.attr('src')!,
        format: getFormat(url),
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
      items: [
        HomePageData(title: 'Banner', list: banner, horizontalImages: false),
        HomePageData(
            title: 'Trending Movies',
            list: trendingMovie,
            horizontalImages: false),
        HomePageData(
            title: 'Trending Series',
            list: trendingSeries,
            horizontalImages: false),
        HomePageData(
            title: 'Latest Movies',
            list: latestMovies,
            horizontalImages: false),
        HomePageData(
            title: 'Latest Series',
            list: latestSeries,
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

  MediaPreview contentItemFromElement(Element element) {
    final a = element.selectFirst('a')!;
    final url = a.attr('href')!;
    return MediaPreview(
      title: a.attr('title')!,
      poster: element.selectFirst('img')!.attr('data-src')!,
      url: this.baseUrl + url,
      format: getFormat(url),
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
  String homeDataSelector(HomePageRequest request) {
    throw UnsupportedError('Not Used');
  }

  @override
  String homeNextPageSelector(HomePageRequest request) {
    throw UnsupportedError('Not Used');
  }

  @override
  Request mediaDetailsRequest(String url) =>
      GET('${this.baseUrl}/${url}', headers: this.headers);

  @override
  Future<MediaDetails> mediaDetailsFromDocument(Document document) async {
    final builder = MediaDetails.builder();

    builder.score(StringUtils.toDoubleOrNull(StringUtils.substringAfter(
        document.selectFirst('.imdb)')!.text, 'IMDB: ')));

    builder.description(document
        .selectFirst('.description')!
        .text
        .replaceFirst('Overview:', '')
        .trim());

    final elements = document.select('.elements > div > div > .row-line');

    for (var e in elements) {
      final type = e.selectFirst('span.type > strong')!.text.trim();

      if (type == 'Genre:') {
        builder.genres(ListUtils.mapList(
            e.select('a'), (e) => (e as Element).attr('title')!));
      } else if (type == 'Released:') {
        builder.startDate(
            DateTime.tryParse(e.text.replaceFirst('Released:', '').trim()));
      } else if (type == 'Casts:') {
        builder.characters(ListUtils.mapList(
            e.select('a'), (e) => Character(name: (e as Element).text)));
      } else if (type == 'Duration:') {
        builder.duration(
            AppUtils.tryParseDuration(e.text.replaceFirst('Duration:', '')));
      }
    }

    builder.recommendations(ListUtils.mapList(
        document.select('div.flw-item > div.film-poster'),
        (e) => contentItemFromElement(e)));

    // final Content content;
    // if (contentItem.format == ContentCategory.Movie) {
    //   content = getMovie(contentItem.url);
    // } else {
    //   content = await getSeries(contentItem.url);
    // }

    return builder.build();
  }

  Movie getMovie(String id) =>
      Movie(playUrl: '${this.baseUrl}/ajax/episode/list/$id');

  Request seriesRequest(String id) =>
      GET('${this.baseUrl}/ajax/season/list/$id', headers: this.headers);

  Future<TvSeries> getSeries(String id) async {
    final List<SeasonList> results = [];
    final response = await client.newCall(seriesRequest(id)).execute();
    final seasonsList = response.body.document
        .select('div.dropdown-menu.dropdown-menu-model > a');
    for (var s in seasonsList) {
      results.add(
        SeasonList(
          season: Season(
            number: int.tryParse(StringUtils.substringAfter(s.text, 'Season ')),
          ),
          episodes: await getEpisodes(s.attr('data-id')!),
        ),
      );
    }

    return TvSeries(seasons: results);
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
      number: int.tryParse(episode ?? ''),
      name: details.selectFirst('h3.film-name')!.text.trimLeft().trimRight(),
    );
  }

  // ============================== LoadLinks ===================================

  @override
  Request mediaLinksRequest(String url) =>
      GET(this.baseUrl + url, headers: this.headers);

  @override
  String mediaLinkSelector() => 'ul.ulclear.fss-list > li > a';

  @override
  Future<List<MediaLink>> getMediaLinks(String url) async {
    final response = await client.newCall(mediaLinksRequest(url)).execute();

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
  String searchItemSelector() => ''; // contentItemSelector();

  @override
  String? searchNextPageSelector() {
    throw UnimplementedError();
  }

  @override
  MediaPreview searchItemFromElement(Element element) {
    final url = element.selectFirst('div.img > a')!.attr('href')!;
    return MediaPreview(
      title: element.selectFirst('p.name > a')!.text,
      url: this.baseUrl + url,
      poster: element.selectFirst('div.img > a > img')!.attr('src')!,
      format: getFormat(url),
    );
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
