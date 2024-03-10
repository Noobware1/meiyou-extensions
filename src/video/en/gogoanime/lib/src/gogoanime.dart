// ignore_for_file: unnecessary_cast

import 'package:meiyou_video_extensions_en_gogoanime/src/preferences.dart';
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
  GogoAnime(NetworkHelper networkHelper) : super(networkHelper);

  @override
  String get baseUrl {
    final url = this.preferences.getString(
        Preferences.PREF_DOMAIN_KEY, Preferences.PREF_DOMAIN_DEFAULT)!;
    if (url.trim().isEmpty) {
      return Preferences.PREF_DOMAIN_DEFAULT;
    }
    return url;
  }

  final ajaxUrl = 'https://ajax.gogocdn.net';

  @override
  final String name = 'GogoAnime';

  @override
  String get lang => 'en';

  @override
  HeadersBuilder headersBuilder() {
    return super
        .headersBuilder()
        .add('Origin', this.baseUrl)
        .add("Referer", "${this.baseUrl}/");
  }

  // ============================== HomePage ===================================
  @override
  Iterable<HomePageData> get homePageList => HomePageData.fromMap({
        'Popular Ongoing':
            '${this.ajaxUrl}/ajax/page-recent-release-ongoing.html',
        'Latest Episodes': '${this.ajaxUrl}/ajax/page-recent-release.html',
        'Popular Anime': '${this.baseUrl}/popular.html',
      });

  @override
  String? homePageHasNextPageSelector(int page, HomePageRequest request) =>
      null;

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    String url = '${request.data}?page=$page';
    if (request.name == 'Latest Episodes') {
      url += '&type=2';
    }
    return GET(url, this.headers);
  }

  @override
  String homePageListDataSelector(int page, HomePageRequest request) {
    if (request.name == 'Popular Ongoing') {
      return ".added_series_body.popular > ul > li";
    } else if (request.name == 'Latest Episodes') {
      return '.last_episodes.loaddub > .items > li';
    } else {
      return popularAnimeSelector();
    }
  }

  String popularAnimeSelector() => "div > ul.items > li";

  @override
  SearchResponse homePageListDataFromElement(
      int page, HomePageRequest request, Element element) {
    if (request.name == 'Popular Ongoing') {
      return parsePopularOngoing(element);
    } else if (request.name == 'Latest Episodes') {
      return parseLatest(element);
    } else {
      final a = element.selectFirst('p.name > a')!;
      return SearchResponse(
        title: a.text,
        url: this.baseUrl + a.attr('href')!,
        poster: element.selectFirst('div.img > a > img')!.attr('src')!,
        type: ShowType.Anime,
      );
    }
  }

  SearchResponse parseLatest(Element element) {
    final a = element.selectFirst(' p.name > a')!;
    return SearchResponse(
      title: a.text,
      url: this.baseUrl + a.attr('href')!,
      poster: element.selectFirst('.img > a > img')?.attr('src') ?? '',
      type: ShowType.Anime,
      current: StringUtils.toIntOrNull(
        StringUtils.substringAfter(
                element.selectFirst('p.episode')?.text ?? '', 'Episode')
            .trim(),
      ),
    );
  }

  SearchResponse parsePopularOngoing(Element element) {
    final a = element.selectFirst('a')!;
    final img = RegExp(r"""background:\surl\(['|"](.*)['|"]\)""")
        .firstMatch(a.selectFirst('div')!.attr('style')!)
        ?.group(1);

    return SearchResponse(
        title: element.select('a')[1].text.trim(),
        url: this.baseUrl + a.attr('href')!,
        generes: getGeneres(element.select('.genres > a')),
        poster: img!,
        type: ShowType.Anime);
  }

  @override
  FilterList getFilterList() {
    return FilterList([HeaderFilter('idk')]);
  }

  @override
  Request mediaDetailsRequest(SearchResponse searchResponse) {
    return GET(searchResponse.url, this.headers);
  }

  @override
  MediaDetails mediaDetailsFromDocument(Document document) {
    final media = MediaDetails();

    final body = document.selectFirst('div.anime_info_body_bg');

    media.posterImage = body!.selectFirst('img')!.attr('src');

    for (var e in body.select('p.type')) {
      final header = e.selectFirst('span')!.text.trim();

      if (header == 'Plot Summary:') {
        media.description = e.text.replaceFirst('Plot Summary:', '').trim();
      } else if (header == 'Type:') {
        media.type = getType(e.selectFirst('a')!.attr('title')!);
      } else if (header == 'Genre:') {
        media.genres = ListUtils.mapList(e.select('a'), (e) {
          e as Element;
          return e.attr('title')!;
        });
      } else if (header == 'Released:') {
        media.startDate = AppUtils.toDateTime(
            StringUtils.toInt(e.text.replaceFirst('Released:', '').trim()));
      } else if (header == 'Status:') {
        media.status = getStatus(e.text.replaceFirst('Status:', ''));
      } else if (header == 'Other name:') {
        media.otherTitles =
            e.text.replaceFirst('Other name:', '').trim().split(';');
      }
    }
    return media;
  }

  @override
  Future<MediaDetails> getMediaDetails(SearchResponse searchResponse) async {
    Document document = await this
        .client
        .newCall(mediaDetailsRequest(searchResponse))
        .execute()
        .then((response) => (response as Response).body.document);

    final mediaDetails = mediaDetailsFromDocument(document);
    mediaDetails.copyFromSearchResponse(searchResponse);

    final id = document
        .selectFirst('.anime_info_episodes_next > #movie_id')!
        .attr('value')!;

    final epEnd =
        document.select('ul#episode_page > li > a').last.attr('ep_end')!;

    document = await this
        .client
        .newCall(episodeListRequest(epEnd, id))
        .execute()
        .then((response) => (response as Response).body.document);

    mediaDetails.mediaItem = mediaItemFromDocument(document);
    return mediaDetails;
  }

  @override
  MediaItem? mediaItemFromDocument(Document document) {
    final List<Episode> episodes = [];
    final elements = document.select(episodeListSelector());

    for (var i = ListUtils.lastIndex(elements); i >= 0; i--) {
      episodes.add(episodeFromElement(elements[i]));
    }

    return Anime(episodes: episodes);
  }

  Request episodeListRequest(String epEnd, String id) {
    return GET(
      '${this.ajaxUrl}/ajax/load-list-episode?ep_start=0&ep_end=$epEnd&id=$id',
      this.headers,
    );
  }

  String episodeListSelector() => '#episode_related > li > a';

  Episode episodeFromElement(Element element) {
    return Episode(
      data: this.baseUrl + element.attr('href')!.trim(),
      episode: StringUtils.toNum(
          element.selectFirst('div.name')!.text.replaceFirst('EP ', '')),
    );
  }

  // ============================== LoadLinks ===================================

  @override
  Request linksRequest(String url) {
    return GET(url, this.headers);
  }

  @override
  String linksListSelector() => '.anime_muti_link > ul > li > a';

  @override
  ExtractorLink linkFromElement(Element element) {
    return ExtractorLink(
      name: element.text.replaceFirst('Choose this server', '').trim(),
      url: AppUtils.httpify(element.attr('data-video')!),
    );
  }

  @override
  Future<List<ExtractorLink>> getLinks(String url) {
    return this.client.newCall(linksRequest(url)).execute().then((response) {
      response as Response;
      final elements = response.body.document.select(linksListSelector());
      final links = ListUtils.mapList(elements, (e) => linkFromElement(e));
      return sortLinks(links);
    });
  }

  List<ExtractorLink> sortLinks(List<ExtractorLink> links) {
    final server = this.preferences.getString(
        Preferences.PREF_SERVER_KEY, Preferences.PREF_SERVER_DEFAULT);

    return links
      ..sort((a, b) {
        a as ExtractorLink;
        b as ExtractorLink;
        if (a.name == server) {
          return 1;
        } else if (b.name == server) {
          return -1;
        } else {
          return 0;
        }
      });
  }

  @override
  Future<Media?> getMedia(ExtractorLink link) async {
    final Video? video;
    if (link.url.contains('/streaming.php?') ||
        link.url.contains('/embedplus?')) {
      video = await GogoCDNExtractor(this.client).extract(link);
    } else {
      video = null;
    }

    if (video != null) {
      video.videoSources = sortVideoSources(video.videoSources);
    }

    return video;
  }

  List<VideoSource> sortVideoSources(List<VideoSource> sources) {
    // final qualityStr = this
    //     .preferences
    //     .getString("PREF_QUALITY_KEY", Preferences.PREF_QUALITY_KEY)!;
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
  String searchListSelector() => this.popularAnimeSelector();

  @override
  Request searchRequest(int page, String query, FilterList filters) {
    return GET('${this.baseUrl}/search.html?keyword=$query', this.headers);
  }

  @override
  SearchResponse searchResponseFromElement(Element element) {
    return SearchResponse(
      title: element.selectFirst('p.name > a')!.text,
      url: this.baseUrl + element.selectFirst('div.img > a')!.attr('href')!,
      poster: element.selectFirst('div.img > a > img')!.attr('src')!,
      type: ShowType.Anime,
    );
  }

  // ============================== Helpers ===============================

  List<String> getGeneres(List<Element> elements) {
    return ListUtils.mapList<Element, String>(elements, (it) {
      return (it as Element).attr('title')!;
    });
  }

  ShowType getType(String t) {
    if (t.contains("OVA") || t.contains("Special")) {
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

  // ============================== Not Used ===================================
  @override
  Request? mediaRequest(ExtractorLink link) {
    throw UnsupportedError('Not Used');
  }

  @override
  Media? mediaFromDocument(Document document) {
    throw UnsupportedError('Not Used');
  }

  @override
  Request? mediaItemRequest(SearchResponse searchResponse, Response response) {
    throw UnsupportedError('Not Used');
  }

  // ============================== Preferences ===================================

  @override
  List<PreferenceData> setupPreferences() {
    return [
      EditTextPreference(
        key: Preferences.PREF_DOMAIN_KEY,
        title: Preferences.PREF_DOMAIN_TITLE,
        value: Preferences.PREF_DOMAIN_DEFAULT,
        dialogTitle: Preferences.PREF_DOMAIN_TITLE,
        dialogMessage: Preferences.PREF_DOMAIN_DIALOG_MESSAGE,
        summary: Preferences.PREF_DOMAIN_SUMMARY,
      ),
      ListPreference(
        key: Preferences.PREF_QUALITY_KEY,
        title: Preferences.PREF_QUALITY_TITLE,
        entries: Preferences.PREF_QUALITY_ENTRIES,
        entryValues: Preferences.PREF_QUALITY_VALUES,
        dialogTitle: '',
        dialogMessage: '',
        summary: '',
      ),
      ListPreference(
        key: Preferences.PREF_SERVER_KEY,
        title: Preferences.PREF_SERVER_TITLE,
        entries: Preferences.HOSTERS,
        entryValues: Preferences.HOSTERS,
        dialogTitle: '',
        dialogMessage: '',
        summary: '',
      ),
      MultiSelectListPreference(
        key: Preferences.PREF_HOSTER_KEY,
        title: Preferences.PREF_HOSTER_TITLE,
        entries: Preferences.HOSTERS,
        entryValues: Preferences.HOSTERS_NAMES,
        dialogMessage: '',
        dialogTitle: '',
        summary: '',
        defaultSelected: Preferences.PREF_HOSTER_DEFAULT,
      )
    ];
  }
}
