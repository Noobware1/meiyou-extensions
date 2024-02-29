part of '../make_source.dart';

String getHttpSourceTemplate(String sourceName) {
  return '''
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:$sourceName/src/$sourceName.dart';

HttpSource getSource(NetworkHelper network) {
  return ${StringUtils.capitalize(sourceName)}(network);
}
''';
}

String httpSourceTemplate(String sourceName) {
  return '''  
// ignore_for_file: unnecessary_this, unnecessary_cast
  
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';

import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

class ${StringUtils.capitalize(sourceName)} extends HttpSource {
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
  Request homePageRequest(int page, HomePageRequest request) {
    // TODO: implement homePageRequest
    throw UnimplementedError();
  }

  @override
  HomePage homePageParse(int page, HomePageRequest request, Response response) {
    // TODO: implement homePageParse
    throw UnimplementedError();
  }

  @override
  FilterList getFilterList() {
    // TODO: implement getFilterList
    throw UnimplementedError();
  }

  @override
  List<SearchResponse> searchParse(Response response) {
    // TODO: implement searchParse
    throw UnimplementedError();
  }

  @override
  Request searchRequest(int page, String query, FilterList filters) {
    // TODO: implement searchRequest
    throw UnimplementedError();
  }

  @override
  MediaDetails mediaDetailsParse(Response response) {
    // TODO: implement mediaDetailsParse
    throw UnimplementedError();
  }

  @override
  Request mediaDetailsRequest(SearchResponse searchResponse) {
    // TODO: implement mediaDetailsRequest
    throw UnimplementedError();
  }

  @override
  MediaItem? mediaItemParse(SearchResponse searchResponse, Response response) {
    // TODO: implement mediaItemParse
    throw UnimplementedError();
  }

  @override
  Request? mediaItemRequest(SearchResponse searchResponse, Response response) {
    // TODO: implement mediaItemRequest
    throw UnimplementedError();
  }

  @override
  List<ExtractorLink> linksParse(Response response) {
    // TODO: implement linksParse
    throw UnimplementedError();
  }

  @override
  Request linksRequest(String url) {
    // TODO: implement linksRequest
    throw UnimplementedError();
  }

  @override
  Media? mediaParse(Response response) {
    // TODO: implement mediaParse
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
