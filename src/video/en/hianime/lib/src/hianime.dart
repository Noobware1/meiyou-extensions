// ignore_for_file: unnecessary_this, unnecessary_cast

import 'package:meiyou_extensions_lib/html_extensions.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';

import 'package:html/dom.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

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
      HomePageRequest(name: 'Trending', data: '${this.baseUrl}/home'),
      HomePageRequest(
          name: 'Latest Episodes', data: '${this.baseUrl}/recently-updated'),
      HomePageRequest(name: 'Top Airing', data: '${this.baseUrl}/top-airing'),
      HomePageRequest(
          name: 'Most Popular', data: '${this.baseUrl}/most-popular'),
      HomePageRequest(
          name: 'New on HiAnime',
          data: '${this.baseUrl}/${this.baseUrl}/recently-added'),
    ];
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    var url = request.data;
    if (request.name != 'Trending') {
      url += '?page=$page';
    }
    return GET(url, headers: docHeaders);
  }

  @override
  ContentItem homePageItemFromElement(
      HomePageRequest request, Element element) {
    if (request.name == 'Trending') {
      return trendingItemFromElement(element);
    } else {
      return searchPageItemFromElement(element);
    }
  }

  @override
  String homePageItemSelector(HomePageRequest request) {
    if (request.name == 'Trending') {
      return 'li.page-item a[title=Next]';
    } else {
      return searchPageItemSelector();
    }
  }

  ContentItem trendingItemFromElement(Element element) {
    final content = element.selectFirst('.deslide-item-content')!;

    return ContentItem(
      title: content.selectFirst('div.desi-head-title.dynamic-name')!.text,
      url: content
          .selectFirst('.desi-buttons > .btn.btn-secondary.btn-radius')!
          .attr('href')!,
      poster:
          element.selectFirst('.deslide-cover > div > img')!.attr('data-src')!,
      category: getCategory(content.selectFirst('.sc-detail > div')!.text),
      description: content.selectFirst('.desi-description')!.text.trim(),
    );
  }

  @override
  String? homePageNextPageSelector(HomePageRequest request) {
    return (request.name == 'Trending') ? '.deslide-item' : null;
  }

  @override
  Request infoPageRequest(String url) {
    throw UnimplementedError();
  }

  @override
  Future<InfoPage> infoPageFromDocument(Document document) {
    // TODO: implement infoPageFromDocument
    throw UnimplementedError();
  }

  @override
  FilterList getFilterList() => FilterList([HeaderFilter('idk')]);

  @override
  Request searchPageRequest(int page, String query, FilterList filters) =>
      GET('$baseUrl/search?q=$query&page=$page', headers: docHeaders);

  @override
  String searchPageItemSelector() => 'div.flw-item';

  @override
  String? searchPageNextPageSelector() => null;

  @override
  ContentItem searchPageItemFromElement(Element element) {
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
    final category = getCategory(element
        .selectFirst('div.film-detail > div.fd-infor > span.fdi-item')!
        .text);
    return ContentItem(
      title: title,
      url: url,
      poster: poster,
      category: category,
    );
  }

  @override
  Request contentDataLinksRequest(String url) {
    // TODO: implement contentDataLinksRequest
    throw UnimplementedError();
  }

  @override
  String contentDataLinkSelector() {
    throw UnimplementedError();
  }

  @override
  ContentDataLink contentDataLinkFromElement(Element element) {
    // TODO: implement contentDataLinkFromElement
    throw UnimplementedError();
  }

  ContentCategory getCategory(String c) {
    if (c.contains("OVA") || c.contains("Special")) {
      return ContentCategory.Ova;
    } else if (c.contains("Movie")) {
      return ContentCategory.AnimeMovie;
    } else if (c.contains("ONA")) {
      return ContentCategory.Ona;
    } else {
      return ContentCategory.Anime;
    }
  }
}
