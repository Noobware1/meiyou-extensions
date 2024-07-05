part of '../make_source.dart';

String getParsedHttpSourceTemplate(String sourceName) {
  return '''
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:$sourceName/src/$sourceName.dart';

ParsedHttpSource main() {
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
  // TODO: implement baseUrl
  String get name => throw UnimplementedError();

  @override
  // TODO: implement baseUrl
  String get baseUrl => throw UnimplementedError();

  @override
  List<HomePageRequest> homePageRequests() {
    // TODO: implement homePageRequests
    throw UnimplementedError();
  }

  @override
  String? homeNextPageSelector(HomePageRequest request) {
    // TODO: implement homeNextPageSelector
    throw UnimplementedError();
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    // TODO: implement homePageRequest
    throw UnimplementedError();
  }

  @override
  Future<MediaDetails> mediaDetailsFromDocument(Document document) {
    // TODO: implement mediaDetailsFromDocument
    throw UnimplementedError();
  }

  @override
  MediaLink mediaLinkFromElement(Element element) {
    // TODO: implement mediaLinkFromElement
    throw UnimplementedError();
  }

  @override
  String mediaLinkSelector() {
    // TODO: implement mediaLinkSelector
    throw UnimplementedError();
  }

  @override
  Request mediaLinksRequest(String url) {
    // TODO: implement mediaLinksRequest
    throw UnimplementedError();
  }

  @override
  MediaPreview searchItemFromElement(Element element) {
    // TODO: implement searchItemFromElement
    throw UnimplementedError();
  }

  @override
  String searchItemSelector() {
    // TODO: implement searchItemSelector
    throw UnimplementedError();
  }

  @override
  String? searchNextPageSelector() {
    // TODO: implement searchNextPageSelector
    throw UnimplementedError();
  }

  @override
  Request searchPageRequest(int page, String query, FilterList filters) {
    // TODO: implement searchPageRequest
    throw UnimplementedError();
  }

  
  @override
  FilterList getFilterList() {
    // TODO: implement getFilterList
    throw UnimplementedError();
  }
}

''';
}
