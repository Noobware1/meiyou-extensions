part of '../make_source.dart';

String getParsedHttpSourceTemplate(String sourceName) {
  return '''
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:$sourceName/src/$sourceName.dart';

ParsedHttpSource getSource(NetworkHelper network) {
  return ${StringUtils.capitalize(sourceName)}(network);
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
  ${StringUtils.capitalize(sourceName)}(NetworkHelper network) : super(network);

  @override
  String get name => "$sourceName";

  @override
  // TODO: implement lang
  String get lang => throw UnimplementedError();

  @override
  // TODO: implement baseUrl
  String get baseUrl => throw UnimplementedError();

  @override
  // TODO: implement homePageList
  Iterable<HomePageData> get homePageList => throw UnimplementedError();

  @override
  String? homePageHasNextPageSelector(int page, HomePageRequest request) {
    // TODO: implement homePageHasNextPageSelector
    throw UnimplementedError();
  }

  @override
  SearchResponse homePageListDataFromElement(
      int page, HomePageRequest request, Element element) {
    // TODO: implement homePageListDataFromElement
    throw UnimplementedError();
  }

  @override
  String homePageListDataSelector(int page, HomePageRequest request) {
    // TODO: implement homePageListDataSelector
    throw UnimplementedError();
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    // TODO: implement homePageRequest
    throw UnimplementedError();
  }

  @override
  FilterList getFilterList() {
    // TODO: implement getFilterList
    throw UnimplementedError();
  }

  @override
  String searchListSelector() {
    // TODO: implement searchListSelector
    throw UnimplementedError();
  }

  @override
  Request searchRequest(int page, String query, FilterList filters) {
    // TODO: implement searchRequest
    throw UnimplementedError();
  }

  @override
  SearchResponse searchResponseFromElement(Element element) {
    // TODO: implement searchResponseFromElement
    throw UnimplementedError();
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

''';
}
