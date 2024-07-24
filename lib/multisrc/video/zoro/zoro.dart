// ignore_for_file: unnecessary_cast

import 'dart:async';

import 'package:html/dom.dart';
import 'package:meiyou_extensions/multisrc/video/zoro/preferences.dart';
import 'package:meiyou_extensions_lib/html_extensions.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

abstract class Zoro extends ParsedHttpSource {
  Zoro({
    required this.id,
    required this.baseUrl,
    required this.name,
    required this.lang,
    required this.hosterNames,
    required this.ajaxRoute,
  });

  @override
  final int id;

  @override
  final String baseUrl;

  @override
  final String name;

  @override
  final String lang;

  final List<String> hosterNames;

  final String ajaxRoute;

  Headers get _docHeaders => headers
      .newBuilder()
      .add("Accept",
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")
      .add("Host", Uri.parse(baseUrl).host)
      .add("Referer", "$baseUrl/")
      .build();

  @override
  List<HomePageRequest> getHomePageRequestList() => [
        HomePageRequest(title: 'Most Popular', url: '/most-popular'),
        HomePageRequest(title: 'Latest', url: '/top-airing'),
        HomePageRequest(title: 'Most Favorite', url: '/most-favorite'),
        HomePageRequest(title: 'Completed', url: '/completed'),
      ];

  // ============================== HomePage ===================================

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    String url = baseUrl + request.url;
    if (request.title != 'Home') {
      url += '?page=$page';
    }
    return GET(url, headers: _docHeaders);
  }

  @override
  IMedia homeMediaFromElement(HomePageRequest request, Element element) {
    return searchMediaFromElement(element);
  }

  @override
  String? homeHasNextPageSelector(HomePageRequest request) =>
      searchHasNextPageSelector();

  @override
  String homeMediaListSelector(HomePageRequest request) =>
      searchMediaListSelector();

  // ============================== MediaDetails ===================================

  @override
  IMedia mediaDetailsFromDocument(Document document) {
    final IMedia mediaDetails = IMedia();
    mediaDetails.format =
        getFormat(document.selectFirst('.tick > .item')!.text);

    final info = document.select('div.anisc-info > div');
    for (var element in info) {
      final head = element.selectFirst('.item-head')?.text;

      if (head == 'Japanese:') {
        mediaDetails.addOtherTitle(getInfo(element));
      } else if (head == 'Status:') {
        mediaDetails.status = getStatus(getInfo(element));
      } else if (head == 'Genres:') {
        mediaDetails.genres =
            ListUtils.mapList(element.select('a'), (e) => (e as Element).text);
      } else if (head == 'MAL Score:') {
        mediaDetails.score = StringUtils.toDoubleOrNull(getInfo(element));
      } else if (head == 'Overview:') {
        mediaDetails.description = element.selectFirst('.text')?.text;
      }
    }

    return mediaDetails;
  }

  String getInfo(Element element) {
    return element.selectFirst(".name")!.text;
  }

  Status getStatus(String s) {
    if (s == "Currently Airing") {
      return Status.ongoing;
    } else if (s == "Finished Airing") {
      return Status.completed;
    } else {
      return Status.unknown;
    }
  }

  @override
  Request mediaContentListRequest(IMedia media) {
    final url = media.url;
    final id = StringUtils.substringAfterLast(url, "-");
    return GET("$baseUrl/ajax$ajaxRoute/episode/list/$id",
        headers: _apiHeaders(baseUrl + url));
  }

  @override
  FutureOr<List<IMediaContent>> mediaContentListParse(Response response) {
    final document = Document.html(response.body.json((json) {
      return json['html'];
    }));
    return mediaContentListFromDocument(document);
  }

  @override
  String mediaContentListSelector() => 'a.ep-item';

  @override
  IMediaContent mediaContentFromElement(Element element) {
    final episodeNumber = int.parse(element.attr("data-number")!);

    final name = element.attr('title');

    final url = element.attr('href')!;

    final isFiller = element.attr('class')!.contains('ssl-item-filler');

    return IMediaContent(
      number: episodeNumber,
      name: name,
      url: url,
      isFiller: isFiller,
    );
  }

  Headers _apiHeaders(String referer) {
    return headers
        .newBuilder()
        .add("Accept", "*/*")
        .add("Host", Uri.parse(baseUrl).host)
        .add("Referer", referer)
        .add("X-Requested-With", "XMLHttpRequest")
        .build();
  }

  @override
  Future<List<MediaLink>> mediaLinkListParse(Response response) async {
    final episodeReferer = response.request.headers.get("referer")!;
    final typeSelection = _typeToggle;
    final hosterSelection = _hostToggle;

    final Document document =
        Document.html(response.body.json((json) => json['html']));

    final types = ZoroPreferences.prefTypesEntryValues;

    final List<MediaLink> links = [];

    final regex = RegExp(r'\s+');

    for (var type in types) {
      if (typeSelection.contains(type)) {
        final servers = document.select("div.$type div.item");
        for (var server in servers) {
          final id = server.attr("data-id");

          final name = server.text.replaceFirst(regex, ' ').trim();

          if (hosterSelection.contains(name)) {
            final link = await client
                .newCall(GET("$baseUrl/ajax$ajaxRoute/episode/sources?id=$id",
                    headers: _apiHeaders(episodeReferer)))
                .execute()
                .then((value) => (value as Response)
                    .body
                    .jsonSafe((json) => json['link'] ?? ""));

            links.add(MediaLink(name: name, url: link));
          }
        }
      }
    }

    return links;
  }

  @override
  Request mediaLinkListRequest(IMediaContent content) {
    final url = content.url;
    final id = StringUtils.substringAfterLast(url, "?ep=");
    return GET("$baseUrl/ajax$ajaxRoute/episode/servers?episodeId=$id",
        headers: _apiHeaders(baseUrl + url));
  }

  @override
  MediaLink mediaLinkFromElement(Element element) {
    throw UnsupportedOperationException();
  }

  @override
  String mediaLinkListSelector() {
    throw UnsupportedOperationException();
  }

  // ============================== Search ===================================

  @override
  IMedia searchMediaFromElement(Element element) {
    final poster =
        element.selectFirst('div.film-poster > img')!.attr('data-src')!;
    final details = element.selectFirst('div.film-detail')!;
    final atag = details.selectFirst('.film-name > a')!;
    final title = (useEnglish && atag.attr('title') != null)
        ? atag.attr('title')!
        : atag.attr('data-jname')!;

    final url = atag.attr('href')!;

    return IMedia(
      title: title,
      url: url,
      poster: poster,
      format: MediaFormat.anime,
    );
  }

  @override
  String searchMediaListSelector() => '.film_list-wrap > .flw-item';

  @override
  String? searchHasNextPageSelector() => 'li.page-item a[title=Next]';

  @override
  Request searchPageRequest(int page, String query, FilterList filters) {
    final endpoint = (query.isEmpty) ? 'filter' : 'search';

    final queryParameters = {
      'page': page.toString(),
    };

    addIfNotBlank('keyword', query, queryParameters);

    final url = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: queryParameters,
    );

    return GET(url, headers: _docHeaders);
  }

  void addIfNotBlank(
      String key, String value, Map<String, String> queryParameters) {
    if (StringUtils.isNotBlank(value)) {
      queryParameters[key] = value;
    }
  }

  @override
  FilterList getFilterList() {
    return FilterList([]);
  }

  // ============================== MediaAsset ===================================

  @override
  FutureOr<MediaAsset> mediaAssetFromDocument(
      MediaLink link, Document document) {
    throw UnsupportedOperationException();
  }

  // ============================== Utils ===============================

  MediaFormat getFormat(String s) {
    if (StringUtils.equals(s, 'movie', ignoreCase: true)) {
      return MediaFormat.animeMovie;
    } else if (StringUtils.equals(s, 'ova', ignoreCase: true)) {
      return MediaFormat.ova;
    } else if (StringUtils.equals(s, 'ona', ignoreCase: true)) {
      return MediaFormat.ona;
    } else {
      return MediaFormat.anime;
    }
  }

  // ============================== Preferences ===================================

  String get _getTitleLang => preferences.getString(
      ZoroPreferences.prefLangKey, ZoroPreferences.prefLangDefault)!;

  bool get useEnglish => _getTitleLang == 'English';

  bool get _markFillers => preferences.getBool(
      ZoroPreferences.prefMarkFillersKey,
      ZoroPreferences.prefMarkFillersDefault)!;

  String get _prefQuality => preferences.getString(
      ZoroPreferences.prefQualityKey, ZoroPreferences.prefQualityDefault)!;

  String get _prefServer =>
      preferences.getString(ZoroPreferences.prefServerKey, hosterNames.first)!;

  String get _prefLang => preferences.getString(
      ZoroPreferences.prefLangKey, ZoroPreferences.prefLangDefault)!;

  List<String> get _hostToggle =>
      preferences.getStringList(ZoroPreferences.prefHosterKey, hosterNames)!;

  List<String> get _typeToggle => preferences.getStringList(
      ZoroPreferences.prefTypeToggleKey,
      ZoroPreferences.prefTypesToggleDefault)!;
}
