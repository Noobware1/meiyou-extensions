part of '../make_source.dart';

String getCatalogueSourceTemplate(String sourceName) {
  return '''
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:$sourceName/src/$sourceName.dart';

CatalogueSource main() {
  return ${StringUtils.capitalize(sourceName)}();
}
''';
}

String catalogueSourceTemplate(String sourceName) {
  return '''
// ignore_for_file: unnecessary_this, unnecessary_cast

import 'package:meiyou_extensions_lib/models.dart';

class ${StringUtils.capitalize(sourceName)} extends CatalogueSource {
  @override
  int get id => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();
  
  @override
  String get lang => throw UnimplementedError();

   @override
  List<HomePageRequest> homePageRequests() {
    throw UnimplementedError();
  }

  @override
  Future<HomePage> getHomePage(int page, HomePageRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<InfoPage> getInfoPage(ContentItem contentItem) {
    throw UnimplementedError();
  }

  @override
  FilterList getFilterList() {
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getSearchPage(int page, String query, FilterList filters) {
    throw UnimplementedError();
  }

  @override
  Future<List<ContentDataLink>> getContentDataLinks(String url) {
    throw UnimplementedError();
  }

  @override
  Future<ContentData?> getContentData(ContentDataLink link) {
    throw UnimplementedError();
  }

}
''';
}
