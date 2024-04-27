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
  String get name => throw UnimplementedError();

  @override
  String get lang => throw UnimplementedError();
  
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
  HomePage homePageParse(int page, HomePageRequest request, Response response) {
    throw UnimplementedError();
  }

  @override
  Request infoPageRequest(ContentItem contentItem) {
    throw UnimplementedError();
  }

  @override
  Future<InfoPage> infoPageParse(ContentItem contentItem, Response response) {
    throw UnimplementedError();
  }

  @override
  FilterList getFilterList() {
    throw UnimplementedError();
  }

  @override
  SearchPage searchPageParse(
      int page, String query, FilterList filters, Response response) {
    throw UnimplementedError();
  }

  @override
  Request searchPageRequest(int page, String query, FilterList filters) {
    throw UnimplementedError();
  }

  @override
  Request contentDataLinksRequest(String url) {
    throw UnimplementedError();
  }

  @override
  List<ContentDataLink> contentDataLinksParse(String url, Response response) {
    throw UnimplementedError();
  }
}

''';
}
