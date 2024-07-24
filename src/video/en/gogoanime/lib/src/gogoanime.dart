import 'dart:async';

import 'package:gogoanime/src/preferences.dart';
import 'package:html/dom.dart';
import 'package:meiyou_extensions/extractors/gogocdn.dart';
import 'package:meiyou_extensions_lib/html_extensions.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/preference.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

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
  List<HomePageRequest> getHomePageRequestList() {
    return [
      HomePageRequest(title: 'Recent Release - Sub', url: '1'),
      HomePageRequest(title: 'Recent Release - Dub', url: '2'),
      HomePageRequest(title: 'Recent Release - Chinese', url: '3'),
    ];
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    return GET(
      '${this.ajaxUrl}/ajax/page-recent-release.html?page=$page&type=${request.url}',
      headers: this.headers,
    );
  }

  @override
  String? homeHasNextPageSelector(HomePageRequest request) {
    return 'ul.pagination-list li:last-child:not(.selected)';
  }

  @override
  String homeMediaListSelector(HomePageRequest request) =>
      searchMediaListSelector();

  @override
  IMedia homeMediaFromElement(HomePageRequest request, Element element) {
    final media = searchMediaFromElement(element);
    media.url = StringUtils.substringBeforeLast(media.url, '-episode');
    return media;
  }

  // ============================== MediaDetails ===================================

  @override
  Request mediaDetailsRequest(IMedia media) {
    return GET('${this.baseUrl}/category${media.url}', headers: this.headers);
  }

  @override
  IMedia mediaDetailsFromDocument(Document document) {
    final mediaDetails = IMedia();

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

  // ============================== MediaContent ===================================

  @override
  Request mediaContentListRequest(IMedia media) {
    return mediaDetailsRequest(media);
  }

  @override
  Future<List<IMediaContent>> mediaContentListParse(Response response) {
    final document = response.body.document;
    final id = document
        .selectFirst('.anime_info_episodes_next > #movie_id')!
        .attr('value')!;

    final epEnd = (document.select('ul#episode_page > li > a').last as Element)
        .attr('ep_end')!;

    final request = episodeListRequest(epEnd, id);

    return this.client.newCall(request).execute().then(
        (Response res) => this.mediaContentListFromDocument(res.body.document));
  }

  @override
  List<IMediaContent> mediaContentListFromDocument(Document document) {
    return (super.mediaContentListFromDocument(document) as List<IMediaContent>)
        .reversed
        .toList();
  }

  Request episodeListRequest(String epEnd, String id) {
    return GET(
      '${this.ajaxUrl}/ajax/load-list-episode?ep_start=0&ep_end=$epEnd&id=$id',
      headers: this.headers,
    );
  }

  @override
  String mediaContentListSelector() => '#episode_related > li > a';

  @override
  IMediaContent mediaContentFromElement(Element element) {
    return IMediaContent(
      url: AppUtils.getUrlWithoutDomain(element.attr('href')!.trim()),
      number: StringUtils.toInt(
          element.selectFirst('div.name')!.text.replaceFirst('EP ', '')),
    );
  }

  // ============================== MediaLinks ===================================

  @override
  String mediaLinkListSelector() => '.anime_muti_link > ul > li > a';

  @override
  MediaLink mediaLinkFromElement(Element element) {
    return MediaLink(
      name: element.text.replaceFirst('Choose this server', '').trim(),
      url: AppUtils.httpify(element.attr('data-video')!),
    );
  }

  // ============================== MediaAsset ===================================

  @override
  FutureOr<MediaAsset?> mediaAssetFromDocument(
      MediaLink link, Document document) {
    if (link.name == 'Vidstreaming' || link.name == 'Gogo server') {
      return this.gogoCDNExtractor.extract(link, document);
    }
    return null;
  }

  GogoCDNExtractor get gogoCDNExtractor => GogoCDNExtractor(this.client);

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
  String searchMediaListSelector() => "div > ul.items > li";

  @override
  String? searchHasNextPageSelector() {
    return null;
  }

  @override
  IMedia searchMediaFromElement(Element element) {
    return IMedia(
      title: element.selectFirst('p.name > a')!.text,
      url: element.selectFirst('div.img > a')!.attr('href')!,
      poster: element.selectFirst('div.img > a > img')!.attr('src')!,
      format: MediaFormat.anime,
    );
  }

  // ============================== Utils ===============================

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
