part of '../make_source.dart';

String getHttpSourceTemplate(String sourceName) {
  return '''
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:$sourceName/src/$sourceName.dart';

HttpSource main() {
  return ${StringUtils.capitalize(sourceName)}();
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
  ${StringUtils.capitalize(sourceName)}();

    @override
  // TODO: implement name
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
  HomePage homePageParse(HomePageRequest request, Response response) {
    // TODO: implement homePageParse
    throw UnimplementedError();
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    // TODO: implement homePageRequest
    throw UnimplementedError();
  }

  @override
  Future<MediaDetails> mediaDetailsParse(Response response) {
    // TODO: implement mediaDetailsParse
    throw UnimplementedError();
  }

  @override
  List<MediaLink> medialinksParse(Response response) {
    // TODO: implement medialinksParse
    throw UnimplementedError();
  }

  @override
  Request mediaLinksRequest(String url) {
    // TODO: implement mediaLinksRequest
    throw UnimplementedError();
  }

  @override
  SearchPage searchPageParse(Response response) {
    // TODO: implement searchPageParse
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
