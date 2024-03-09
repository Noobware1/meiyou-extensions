// ignore_for_file: unnecessary_this, unnecessary_cast

import 'package:meiyou_extensions_lib/html_extensions.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';

import 'package:html/dom.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

class HiAnime extends ParsedHttpSource {
  HiAnime(NetworkHelper network) : super(network);

  @override
  int get id => 8875918538894472758;

  @override
  final String name = "hianime";

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
  Iterable<HomePageData> get homePageList => HomePageData.fromMap({
        'Trending': '${this.baseUrl}/home',
        'Latest Episodes': '${this.baseUrl}/recently-updated',
        'Top Airing': '${this.baseUrl}/top-airing',
        'Most Popular': '${this.baseUrl}/most-popular',
        'New on hianime': '${this.baseUrl}/recently-added',
      });

  @override
  String? homePageHasNextPageSelector(int page, HomePageRequest request) {
    if (request.name != 'Trending') {
      return 'li.page-item a[title=Next]';
    }
    return null;
  }

  @override
  String homePageListDataSelector(int page, HomePageRequest request) {
    return (request.name == 'Trending')
        ? '.deslide-item'
        : searchListSelector();
  }

  @override
  SearchResponse homePageListDataFromElement(
      int page, HomePageRequest request, Element element) {
    if (request.name == 'Trending') {
      final content = element.selectFirst('.deslide-item-content')!;

      return SearchResponse(
        title: content.selectFirst('div.desi-head-title.dynamic-name')!.text,
        url: content
            .selectFirst('.desi-buttons > .btn.btn-secondary.btn-radius')!
            .attr('href')!,
        poster: element
            .selectFirst('.deslide-cover > div > img')!
            .attr('data-src')!,
        type: getType(content.selectFirst('.sc-detail > div')!.text),
        description: content.selectFirst('.desi-description')!.text.trim(),
      );
    }
    return searchResponseFromElement(element);
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    var url = request.data;
    if (request.name != 'Trending') {
      url += '?page=$page';
    }
    return GET(url, docHeaders);
  }

  @override
  FilterList getFilterList() => FilterList([]);

  @override
  String searchListSelector() => 'div.flw-item';

  @override
  Request searchRequest(int page, String query, FilterList filters) {
    return GET('$baseUrl/search?q=$query&page=$page', docHeaders);
  }

  @override
  SearchResponse searchResponseFromElement(Element element) {
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
    final type = getType(element
        .selectFirst('div.film-detail > div.fd-infor > span.fdi-item')!
        .text);
    return SearchResponse(
      title: title,
      url: url,
      poster: poster,
      type: type,
    );
  }

  ShowType getType(String t) {
    if (t.contains("OVA") || t.contains("Special")) {
      return ShowType.Ova;
    } else if (t.contains("Movie")) {
      return ShowType.AnimeMovie;
    } else if (t.contains("ONA")) {
      return ShowType.Ona;
    } else {
      return ShowType.Anime;
    }
  }

  @override
  MediaDetails mediaDetailsFromDocument(Document document) {
    // TODO: implement mediaDetailsFromDocument
    throw UnimplementedError();
  }

  @override
  Request mediaDetailsRequest(SearchResponse searchResponse) {
    // TODO: implement mediaDetailsRequest
    throw UnimplementedError();
  }

  @override
  Media? mediaFromDocument(Document document) {
    // TODO: implement mediaFromDocument
    throw UnimplementedError();
  }

  @override
  MediaItem? mediaItemFromDocument(Document document) {
    // TODO: implement mediaItemFromDocument
    throw UnimplementedError();
  }

  @override
  Request? mediaItemRequest(SearchResponse searchResponse, Response response) {
    // TODO: implement mediaItemRequest
    throw UnimplementedError();
  }

  @override
  ExtractorLink linkFromElement(Element element) {
    // TODO: implement linkFromElement
    throw UnimplementedError();
  }

  @override
  String linksListSelector() {
    // TODO: implement linksListSelector
    throw UnimplementedError();
  }

  @override
  Request linksRequest(String url) {
    // TODO: implement linksRequest
    throw UnimplementedError();
  }

  @override
  Request? mediaRequest(ExtractorLink link) {
    // TODO: implement mediaRequest
    throw UnimplementedError();
  }
}
