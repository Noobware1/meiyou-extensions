part of '../make_source.dart';

String getParsedHttpSourceTemplate(String sourceName) {
  return '''
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:$sourceName/src/$sourceName.dart';

ParsedHttpSource getSource() {
  return ${StringUtils.capitalize(sourceName)}();
}
''';
}

String parsedHttpSourceTemplate(String sourceName) {
  return '''
// ignore_for_file: unnecessary_this, unnecessary_cast 

import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';

import 'package:html/dom.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

class ${StringUtils.capitalize(sourceName)} extends ParsedHttpSource {
  ${StringUtils.capitalize(sourceName)}();

 @override
  int get id => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();

  @override
  String get baseUrl => throw UnimplementedError();

  @override
  List<HomePageRequest> homePageRequests() {
    throw UnimplementedError();
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    throw UnimplementedError();
  }

  @override
  String homePageDataSelector(int page, HomePageRequest request) {
    throw UnimplementedError();
  }

  @override
  String? homePageNextPageSelector(int page, HomePageRequest request) {
    throw UnimplementedError();
  }

  @override
  HomePageData homePageDataFromElement(
      int page, HomePageRequest request, Element element) {
    throw UnimplementedError();
  }

  @override
  Request infoPageRequest(ContentItem contentItem) {
    throw UnimplementedError();
  }

  @override
  Future<InfoPage> infoPageFromDocument(Document document) {
    throw UnimplementedError();
  }

  @override
  FilterList getFilterList() {
    throw UnimplementedError();
  }

  @override
  Request searchPageRequest(int page, String query, FilterList filters) {
    throw UnimplementedError();
  }

  @override
  String searchPageItemSelector(int page, String query, FilterList filters) {
    throw UnimplementedError();
  }

  @override
  String? searchPageNextPageSelector(
      int page, String query, FilterList filters) {
    throw UnimplementedError();
  }

  @override
  ContentItem searchPageItemFromElement(
      int page, String query, FilterList filters, Element element) {
    throw UnimplementedError();
  }

  @override
  Request contentDataLinksRequest(String url) {
    throw UnimplementedError();
  }

  @override
  String contentDataLinkSelector(String url) {
    throw UnimplementedError();
  }

  @override
  ContentDataLink contentDataLinkFromElement(String url, Element element) {
    throw UnimplementedError();
  }


}

''';
}
