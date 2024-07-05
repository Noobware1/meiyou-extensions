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
  // TODO: implement id
  int get id => throw UnimplementedError();

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();

  @override
  List<HomePageRequest> homePageRequests() {
    // TODO: implement homePageRequests
    throw UnimplementedError();
  }

  @override
  Future<HomePage> getHomePage(int page, HomePageRequest request) {
    // TODO: implement getHomePage
    throw UnimplementedError();
  }

  @override
  Future<MediaDetails> getMediaDetails(String url) {
    // TODO: implement getMediaDetails
    throw UnimplementedError();
  }

  @override
  Future<List<MediaLink>> getMediaLinks(String url) {
    // TODO: implement getMediaLinks
    throw UnimplementedError();
  }

  @override
  Future<Media?> getMedia(MediaLink link) {
    // TODO: implement getMedia
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getSearchPage(int page, String query, FilterList filters) {
    // TODO: implement getSearchPage
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
