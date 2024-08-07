import 'dart:async';

import 'package:html/dom.dart';
import 'package:meiyou_extensions_lib/html_extensions.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/preference.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/src/response.dart';
import 'package:turkish123/src/turkish123_extractor.dart';

class Turkish123 extends ParsedHttpSource {
  Turkish123();

  @override
  final String name = 'Turkish123';

  @override
  String get lang => 'tr';

  @override
  final String baseUrl = 'https://turkish123.ac';

  final ajaxUrl = 'https://ajax.gogocdn.net';

  // ============================== HomePage ===================================
  @override
  List<HomePageRequest> getHomePageRequestList() {
    return [
      HomePageRequest(title: 'Latest', url: '/episodes-list'),
      HomePageRequest(title: 'Series', url: '/series-list'),
    ];
  }

  @override
  String? homeHasNextPageSelector(HomePageRequest request) {
    if (request.title == 'Latest') {
      return searchHasNextPageSelector();
    }
    return null;
  }

  @override
  String homeMediaListSelector(HomePageRequest request) =>
      searchMediaListSelector();

  @override
  IMedia homeMediaFromElement(HomePageRequest request, Element element) {
    final media = searchMediaFromElement(element);

    if (request.title == 'Latest') {
      media.url = StringUtils.substringBeforeLast(media.url, '-episode');
    }

    return media;
  }

  // ============================== MediaDetails ===================================

  @override
  IMedia mediaDetailsFromDocument(Document document) {
    final details = IMedia();

    details.title = document.selectFirst('h1[itemprop=name]')?.text ?? '';

    details.banner = AppUtils.getBackgroundImage(
        document.selectFirst('div#content-cover')?.attr('style') ?? '');

    final meta = document.selectFirst('div.mvic-desc')!;

    details.description = meta.selectFirst('div.desc')?.text;

    final info = document.select('div.mvic-info > div > p');

    for (var element in info) {
      final key = element.selectFirst('strong')?.text.trim();

      if (key == null) {
        if (key == 'Title in English:') {
          details.addOtherTitle(element.selectFirst('span')?.text);
        } else if (key == 'Genre:') {
          details.genres =
              ListUtils.mapList(element.select('a'), (Element e) => e.text);
        } else if (key == 'Status:') {
          details.status = getStatus(element.selectFirst('span')?.text);
        }
      }
    }

    details.format = MediaFormat.tvSeries;

    return details;
  }

  // ============================== MediaContent ===================================

  @override
  String mediaContentListSelector() => 'div.les-content > a.episodi';

  @override
  List<IMediaContent> mediaContentListFromDocument(Document document) {
    final List<IMediaContent> list = [];

    final elements = document.select(mediaContentListSelector());

    var season = 0;
    final seasonRegex = RegExp(r'(?<=Season\s)\d+');
    final episodeRegex = RegExp(r'(?<=Episode\s)\d+');

    for (var element in elements) {
      final url = AppUtils.getUrlWithoutDomain(element.attr('href')!);

      final number = StringUtils.toIntOrNull(
          episodeRegex.firstMatch(element.text)?.group(0));

      final content = IMediaContent(
        url: url,
        number: number,
      );

      final seasonInfo = element.selectFirst('span')?.text;

      if (seasonInfo != null) {
        if (seasonInfo.startsWith('Season')) {
          season = StringUtils.toInt(
              seasonRegex.firstMatch(seasonInfo)?.group(0) ??
                  season.toString());
        }
      }

      content.season = season;

      list.add(content);
    }

    return list;
  }

  @override
  IMediaContent mediaContentFromElement(Element element) {
    throw UnsupportedOperationException();
  }

  // ============================== MediaLinks ===================================
  @override
  List<MediaLink> mediaLinkListFromDocument(Document document) {
    final list = <MediaLink>[];

    final elements = document.select(mediaLinkListSelector());

    for (var element in elements) {
      final script = element.selectFirst('script');

      if (script != null) {
        final link = mediaLinkFromElement(element);

        if (link.url.isNotEmpty) {
          list.add(link);
        }
      }
    }

    return list;
  }

  @override
  String mediaLinkListSelector() => '#player2 > div > div.movieplay';

  @override
  MediaLink mediaLinkFromElement(Element element) {
    final url = RegExp(r'<iframe[^>]*\bsrc="([^"]*)"')
            .firstMatch(element.text)
            ?.group(1) ??
        '';

    final name = StringUtils.capitalize(
        StringUtils.substringBefore(Uri.tryParse(url)?.host ?? '', '.'));

    return MediaLink(
      name: name,
      url: url,
      headers: this.headers,
      referer: this.baseUrl,
    );
  }

  // ============================== MediaAsset ===================================

  @override
  Future<MediaAsset?> getMediaAsset(MediaLink link) {
    return extractor.extract(link);
  }

  @override
  FutureOr<MediaAsset?> mediaAssetFromDocument(
      MediaLink link, Document document) {
    throw UnsupportedOperationException();
  }

  Turkish123Extractor get extractor => Turkish123Extractor(this.client);

  // ============================== Search ===============================
  @override
  FilterList getFilterList() {
    return FilterList([HeaderFilter('idk')]);
  }

  @override
  Request searchPageRequest(int page, String query, FilterList filters) {
    return GET('${this.baseUrl}/page/$page/?s=$query', headers: this.headers);
  }

  @override
  String searchMediaListSelector() =>
      '.movies-list.movies-list-full > div.ml-item > a';

  @override
  String searchHasNextPageSelector() {
    return 'ul.pagination > li:last-child > a:not(.page.larger)';
  }

  @override
  IMedia searchMediaFromElement(Element element) {
    final media = IMedia();

    media.url = AppUtils.getUrlWithoutDomain(element.attr('href')!);
    media.title = element.selectFirst('span.mli-info')!.text.trim();
    media.poster = element.selectFirst('img')!.attr('src')!;

    return media;
  }

  // ============================== Utils ===============================

  Status getStatus(String? s) {
    if (s == 'Active') {
      return Status.ongoing;
    } else if (s == 'Completed') {
      return Status.completed;
    } else {
      return Status.unknown;
    }
  }

  // ============================== Preferences ===================================

  @override
  List<PreferenceData> setupPreferences() {
    return [];
  }
}
