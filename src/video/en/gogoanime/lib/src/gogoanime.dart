// ignore_for_file: unnecessary_cast

import 'package:gogoanime/src/preferences.dart';
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
import 'package:meiyou_extensions/extractors/gogocdn.dart';

class GogoAnime extends ParsedHttpSource {
  GogoAnime();

  @override
  int get id => 7055547649318749672;

  @override
  final String name = 'GogoAnime';

  @override
  String get lang => 'en';

  @override
  String get baseUrl {
    final url = this.preferences.getString(
        Preferences.pref_domain_key, Preferences.pref_domain_default)!;
    if (url.trim().isEmpty) {
      return Preferences.pref_domain_default;
    }
    return url;
  }

  final ajaxUrl = 'https://ajax.gogocdn.net';

  @override
  HeadersBuilder headersBuilder() {
    return super
        .headersBuilder()
        .add('Origin', this.baseUrl)
        .add("Referer", "${this.baseUrl}/");
  }

  // ============================== HomePage ===================================
  @override
  List<HomePageRequest> homePageRequests() {
    return [
      HomePageRequest(name: 'Recent Release - Sub', data: '1'),
      HomePageRequest(name: 'Recent Release - Dub', data: '2'),
      HomePageRequest(name: 'Recent Release - Chinese', data: '3'),
    ];
  }

  @override
  HomePage homePageParse(int page, HomePageRequest request, Response response) {
    final document = response.body.document;

    final data = homePageDataParse(page, request, response);

    final hasNextPageSelector = homePageNextPageSelector(page, request);

    final bool hasNextPage = document.selectFirst(hasNextPageSelector) != null;

    return HomePage.fromData(
      data: data,
      hasNextPage: hasNextPage,
    );
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    return GET(
      '${this.ajaxUrl}/ajax/page-recent-release.html?page=$page&type=${request.data}',
      headers: this.headers,
    );
  }

  @override
  String homePageDataSelector(int page, HomePageRequest request) {
    throw UnsupportedError('Not Used');
  }

  String contentItemSelector() => "div > ul.items > li";

  @override
  String homePageNextPageSelector(int page, HomePageRequest request) {
    return 'ul.pagination-list li:last-child:not(.selected)';
  }

  HomePageData homePageDataParse(
      int page, HomePageRequest request, Response response) {
    return HomePageData.withRequest(
      request,
      homePageDataEntriesFromElement(request, response.body.document),
    );
  }

  @override
  HomePageData homePageDataFromElement(
      int page, HomePageRequest request, Element element) {
    throw UnsupportedError('Not used');
  }

  List<ContentItem> homePageDataEntriesFromElement(
      HomePageRequest request, Document document) {
    return ListUtils.mapList(document.select(contentItemSelector()), (element) {
      element as Element;
      final a = element.selectFirst(' p.name > a')!;
      return ContentItem(
        title: a.text,
        url: this.baseUrl + a.attr('href')!,
        poster: element.selectFirst('.img > a > img')?.attr('src') ?? '',
        category: ContentCategory.Anime,
        currentCount: StringUtils.toIntOrNull(
          StringUtils.substringAfter(
                  element.selectFirst('p.episode')?.text ?? '', 'Episode')
              .trim(),
        ),
      );
    });
  }

  @override
  Request infoPageRequest(ContentItem contentItem) {
    return GET(contentItem.url, headers: this.headers);
  }

  @override
  Future<InfoPage> infoPageFromDocument(
      ContentItem contentItem, Document document) async {
    final body = document.selectFirst('div.anime_info_body_bg');

    String? posterImage = body!.selectFirst('img')!.attr('src');
    String? description;
    ContentCategory? category;
    List<String>? genres;
    DateTime? startDate;
    Status? status;
    List<String>? otherTitles;
    for (var e in body.select('p.type')) {
      final header = e.selectFirst('span')!.text.trim();

      if (header == 'Plot Summary:') {
        description = e.text.replaceFirst('Plot Summary:', '').trim();
      } else if (header == 'Type:') {
        category = getCategory(e.selectFirst('a')!.attr('title')!);
      } else if (header == 'Genre:') {
        genres = ListUtils.mapList(e.select('a'), (e) {
          e as Element;
          return e.attr('title')!;
        });
      } else if (header == 'Released:') {
        startDate = AppUtils.toDateTime(
            StringUtils.toInt(e.text.replaceFirst('Released:', '').trim()));
      } else if (header == 'Status:') {
        status = getStatus(e.text.replaceFirst('Status:', ''));
      } else if (header == 'Other name:') {
        otherTitles = e.text.replaceFirst('Other name:', '').trim().split(';');
      }
    }

    final Anime content = await getAnime(document);

    return InfoPage.withItem(
      contentItem,
      posterImage: posterImage,
      description: description,
      category: category,
      genres: genres,
      startDate: startDate,
      status: status,
      otherTitles: otherTitles,
      content: content,
    );
  }

  Future<Anime> getAnime(Document document) async {
    final id = document
        .selectFirst('.anime_info_episodes_next > #movie_id')!
        .attr('value')!;

    final epEnd =
        document.select('ul#episode_page > li > a').last.attr('ep_end')!;

    return this.client.newCall(animeRequest(epEnd, id)).execute().then(
        (response) => animeFromDocument((response as Response).body.document));
  }

  Anime animeFromDocument(Document document) {
    final List<Episode> episodes = [];
    final elements = document.select(episodeListSelector());

    for (var i = ListUtils.lastIndex(elements); i >= 0; i--) {
      episodes.add(episodeFromElement(elements[i]));
    }

    return Anime(episodes);
  }

  Request animeRequest(String epEnd, String id) {
    return GET(
      '${this.ajaxUrl}/ajax/load-list-episode?ep_start=0&ep_end=$epEnd&id=$id',
      headers: this.headers,
    );
  }

  String episodeListSelector() => '#episode_related > li > a';

  Episode episodeFromElement(Element element) {
    return Episode(
      data: this.baseUrl + element.attr('href')!.trim(),
      number: StringUtils.toNum(
          element.selectFirst('div.name')!.text.replaceFirst('EP ', '')),
    );
  }

  // ============================== LoadLinks ===================================

  @override
  Request contentDataLinksRequest(String url) =>
      GET(url, headers: this.headers);

  @override
  String contentDataLinkSelector(String url) =>
      '.anime_muti_link > ul > li > a';

  @override
  ContentDataLink contentDataLinkFromElement(String url, Element element) {
    return ContentDataLink(
      name: element.text.replaceFirst('Choose this server', '').trim(),
      data: AppUtils.httpify(element.attr('data-video')!),
    );
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

  @override
  Future<ContentData?> getContentData(ContentDataLink link) async {
    Video? video;
    if (link.data.contains('/streaming.php?') ||
        link.data.contains('/embedplus?')) {
      video = await GogoCDNExtractor(this.client).extract(link);
    } else {
      video = null;
    }

    if (video != null) {
      video = video.copyWith(sources: sortVideoSources(video.sources));
    }

    return video;
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
      contentItemSelector();

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
    if (t.contains("OVA") || t.contains("Special")) {
      return ContentCategory.Ova;
    } else if (t.contains("Movie")) {
      return ContentCategory.AnimeMovie;
    } else {
      return ContentCategory.Anime;
    }
  }

  Status getStatus(String t) {
    if (t == 'Ongoing') {
      return Status.Ongoing;
    } else {
      return Status.Completed;
    }
  }

  // ============================== Preferences ===================================

  @override
  List<PreferenceData> setupPreferences() {
    return [
      EditTextPreference(
        key: Preferences.pref_domain_key,
        title: Preferences.pref_domain_title,
        value: Preferences.pref_domain_default,
        dialogTitle: Preferences.pref_domain_title,
        dialogMessage: Preferences.PREF_DOMAIN_DIALOG_MESSAGE,
        summary: Preferences.pref_domain_summary,
      ),
      ListPreference(
        key: Preferences.pref_quality_key,
        title: Preferences.pref_quality_title,
        entries: Preferences.pref_quality_entries,
        entryValues: Preferences.pref_quality_values,
        summary: '',
      ),
      ListPreference(
        key: Preferences.pref_server_key,
        title: Preferences.pref_server_title,
        entries: Preferences.hosters,
        entryValues: Preferences.hosters,
        summary: '',
      ),
      MultiSelectListPreference(
        key: Preferences.pref_hoster_key,
        title: Preferences.pref_hoster_title,
        entries: Preferences.hosters,
        entryValues: Preferences.hosters_names,
        summary: '',
        defaultSelected: Preferences.pref_hoster_default,
      )
    ];
  }
}
