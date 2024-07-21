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
    if (StringUtils.isBlank(url)) {
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
      HomePageRequest(title: 'Recent Release - Sub', data: '1'),
      HomePageRequest(title: 'Recent Release - Dub', data: '2'),
      HomePageRequest(title: 'Recent Release - Chinese', data: '3'),
    ];
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    return GET(
      '${this.ajaxUrl}/ajax/page-recent-release.html?page=$page&type=${request.data}',
      headers: this.headers,
    );
  }

  @override
  String homeNextPageSelector(HomePageRequest request) {
    return 'ul.pagination-list li:last-child:not(.selected)';
  }

  @override
  String homePageItemSelector(HomePageRequest request) => searchItemSelector();

  @override
  MediaPreview homePageItemFromElement(
      HomePageRequest request, Element element) {
    final a = element.selectFirst(' p.name > a')!;
    final url = StringUtils.substringBeforeLast(a.getHref!, '-episode');
    return MediaPreview(
      title: a.text,
      url: url,
      poster: element.selectFirst('.img > a > img')?.attr('src') ?? '',
      format: MediaFormat.anime,
    );
  }

  @override
  Request mediaDetailsRequest(MediaDetails mediaDetails) {
    return GET('${this.baseUrl}/category${mediaDetails.url}',
        headers: this.headers);
  }

  @override
  MediaDetails mediaDetailsFromDocument(Document document) {
    final mediaDetails = MediaDetails();

    final Element body = document.selectFirst('div.anime_info_body_bg')!;

    mediaDetails.poster = body.selectFirst('img')!.attr('src')!;

    for (var e in body.select('p.type')) {
      final header = e.selectFirst('span')!.text.trim();

      if (header == 'Plot Summary:') {
        mediaDetails.description =
            e.text.replaceFirst('Plot Summary:', '').trim();
      } else if (header == 'Type:') {
        mediaDetails.format = getFormat(e.selectFirst('a')!.attr('title')!);
      } else if (header == 'Genre:') {
        mediaDetails.genres = ListUtils.mapList(e.select('a'), (e) {
          e as Element;
          return e.attr('title')!;
        });
      } else if (header == 'Status:') {
        mediaDetails.status = getStatus(e.text.replaceFirst('Status:', ''));
      } else if (header == 'Other name:') {
        mediaDetails.otherTitles =
            e.text.replaceFirst('Other name:', '').trim().split(';');
      }
    }

    return mediaDetails;
  }

  @override
  Request mediaContentRequest(MediaDetails mediaDetails) {
    return mediaDetailsRequest(mediaDetails);
  }

  @override
  MediaContent mediaContentParse(Response response) {
    throw UnsupportedError('Not Used');
  }

  @override
  Future<MediaContent> mediaContentParseAsync(Response response) {
    final document = response.body.document;
    final id = document
        .selectFirst('.anime_info_episodes_next > #movie_id')!
        .attr('value')!;

    final epEnd = (document.select('ul#episode_page > li > a').last as Element)
        .attr('ep_end')!;

    final request = animeRequest(epEnd, id);

    return this.client.newCall(request).execute().then((response) =>
        mediaContentFromDocument((response as Response).body.document));
  }

  @override
  MediaContent mediaContentFromDocument(Document document) {
    final List<Episode> episodes = [];
    final elements = document.select(episodeListSelector());

    for (var i = ListUtils.lastIndex(elements); i >= 0; i--) {
      episodes.add(episodeFromElement(elements[i]));
    }

    return Anime(episodes: episodes);
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
      data: AppUtils.getUrlWithoutDomain(element.attr('href')!.trim()),
      number: StringUtils.toInt(
          element.selectFirst('div.name')!.text.replaceFirst('EP ', '')),
    );
  }

  // ============================== LoadLinks ===================================

  @override
  Request mediaLinksRequest(String url) =>
      GET(this.baseUrl + url, headers: this.headers);

  @override
  String mediaLinkSelector() => '.anime_muti_link > ul > li > a';

  @override
  MediaLink mediaLinkFromElement(Element element) {
    return MediaLink(
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
  Future<Media?> getMedia(MediaLink link) async {
    Video? video;
    if (link.name == 'Vidstreaming' || link.name == 'Gogo server') {
      video = await GogoCDNExtractor(this.client).extract(link);
    } else {
      video = null;
    }

    // if (video != null) {
    //   video = video.copyWith(sources: sortVideoSources(video.sources));
    // }

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
  String searchItemSelector() => "div > ul.items > li";

  @override
  String? searchNextPageSelector() {
    return null;
  }

  @override
  MediaPreview searchItemFromElement(Element element) {
    return MediaPreview(
      title: element.selectFirst('p.name > a')!.text,
      url: this.baseUrl + element.selectFirst('div.img > a')!.attr('href')!,
      poster: element.selectFirst('div.img > a > img')!.attr('src')!,
      format: MediaFormat.anime,
    );
  }

  // ============================== Helpers ===============================

  List<String> getGeneres(List<Element> elements) {
    return ListUtils.mapList<Element, String>(elements, (it) {
      return (it as Element).attr('title')!;
    });
  }

  MediaFormat getFormat(String t) {
    if (t.contains("OVA") || t.contains("Special")) {
      return MediaFormat.ova;
    } else if (t.contains("Movie")) {
      return MediaFormat.animeMovie;
    } else {
      return MediaFormat.anime;
    }
  }

  Status getStatus(String t) {
    if (t == 'Ongoing') {
      return Status.ongoing;
    } else {
      return Status.completed;
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
