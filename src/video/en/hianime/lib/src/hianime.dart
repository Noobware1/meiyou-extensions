// ignore_for_file: unnecessary_this, unnecessary_cast

import 'package:meiyou_extensions_lib/html_extensions.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:html/dom.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';

class HiAnime extends ParsedHttpSource {
  HiAnime();

  @override
  int get id => 8875918538894472758;

  @override
  final String name = 'HiAnime';

  @override
  final String lang = 'en';

  @override
  final String baseUrl = 'https://hianime.to';

  Headers get docHeaders => this
      .headers
      .newBuilder()
      .add("Accept",
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")
      .add("Host", Uri.parse(baseUrl).host)
      .add("Referer", "$baseUrl/")
      .build();

  bool get useEnglish =>
      this.preferences.getString("preferred_title_lang", "Romanji")! ==
      "English";

  @override
  List<HomePageRequest> homePageRequests() {
    return [
      HomePageRequest(title: 'Trending', data: '${this.baseUrl}/home'),
      HomePageRequest(
          title: 'Latest Episodes', data: '${this.baseUrl}/recently-updated'),
      HomePageRequest(title: 'Top Airing', data: '${this.baseUrl}/top-airing'),
      HomePageRequest(
          title: 'Most Popular', data: '${this.baseUrl}/most-popular'),
      HomePageRequest(
          title: 'New on HiAnime',
          data: '${this.baseUrl}/${this.baseUrl}/recently-added'),
    ];
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    var url = request.data;
    if (request.title != 'Trending') {
      url += '?page=$page';
    }
    return GET(url, headers: docHeaders);
  }

  @override
  MediaPreview homePageItemFromElement(
      HomePageRequest request, Element element) {
    if (request.title == 'Trending') {
      return trendingItemFromElement(element);
    } else {
      return searchItemFromElement(element);
    }
  }

  @override
  String homePageItemSelector(HomePageRequest request) {
    if (request.title == 'Trending') {
      return 'li.page-item a[title=Next]';
    } else {
      return searchItemSelector();
    }
  }

  MediaPreview trendingItemFromElement(Element element) {
    final content = element.selectFirst('.deslide-item-content')!;

    return MediaPreview(
      title: content.selectFirst('div.desi-head-title.dynamic-title')!.text,
      url: content
          .selectFirst('.desi-buttons > .btn.btn-secondary.btn-radius')!
          .attr('href')!,
      poster:
          element.selectFirst('.deslide-cover > div > img')!.attr('data-src')!,
      format: getFormat(content.selectFirst('.sc-detail > div')!.text),
      description: content.selectFirst('.desi-description')!.text.trim(),
    );
  }

  @override
  String? homeNextPageSelector(HomePageRequest request) {
    return (request.title == 'Trending') ? '.deslide-item' : null;
  }

  @override
  Future<MediaDetails> mediaDetailsFromDocument(Document document) {
    // TODO: implement infoPageFromDocument
    throw UnimplementedError();
  }

  @override
  FilterList getFilterList() => FilterList([HeaderFilter('idk')]);

  @override
  Request searchPageRequest(int page, String query, FilterList filters) =>
      GET('$baseUrl/search?q=$query&page=$page', headers: docHeaders);

  @override
  String searchItemSelector() => 'div.flw-item';

  @override
  String? searchNextPageSelector() => null;

  @override
  MediaPreview searchItemFromElement(Element element) {
    final details = element.selectFirst('div.film-detail > a')!;
    final url = details.attr('href')!;
    final String title;
    if (useEnglish && details.attr('title') != null) {
      title = details.attr('title')!;
    } else {
      title = details.attr('data-jname')!;
    }
    final poster =
        element.selectFirst('div.film-poster > img')!.attr('data-src')!;
    final format = getFormat(element
        .selectFirst('div.film-detail > div.fd-infor > span.fdi-item')!
        .text);
    return MediaPreview(
      title: title,
      url: url,
      poster: poster,
      format: format,
    );
  }

  @override
  Request mediaLinksRequest(String url) {
    // TODO: implement contentDataLinksRequest
    throw UnimplementedError();
  }

  @override
  String mediaLinkSelector() {
    throw UnimplementedError();
  }

  @override
  MediaLink mediaLinkFromElement(Element element) {
    // TODO: implement contentDataLinkFromElement
    throw UnimplementedError();
  }

  MediaFormat getFormat(String c) {
    if (c.contains("OVA") || c.contains("Special")) {
      return MediaFormat.ova;
    } else if (c.contains("Movie")) {
      return MediaFormat.animeMovie;
    } else if (c.contains("ONA")) {
      return MediaFormat.ona;
    } else {
      return MediaFormat.anime;
    }
  }
}
