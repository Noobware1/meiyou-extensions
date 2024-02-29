part of '../make_source.dart';

String getCatalogueSourceTemplate(String sourceName) {
  return '''
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:$sourceName/src/$sourceName.dart';

CatalogueSource getSource(NetworkHelper network) {
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
  String get name => "$sourceName";

  @override
  // TODO: implement id
  int get id => throw UnimplementedError();

  
  @override
  // TODO: implement lang
  String get lang => throw UnimplementedError();

  @override
  // TODO: implement homePageList
  Iterable<HomePageData> get homePageList => throw UnimplementedError();

  @override
  Future<HomePage> getHomePage(int page, HomePageRequest request) {
    // TODO: implement getHomePage
    throw UnimplementedError();
  }

   @override
  FilterList getFilterList() {
    // TODO: implement getFilterList
    throw UnimplementedError();
  }

  @override
  Future<List<SearchResponse>> getSearch(
      int page, String query, FilterList filters) {
    // TODO: implement getSearch
    throw UnimplementedError();
  }

  @override
  Future<MediaDetails> getMediaDetails(SearchResponse searchResponse) {
    // TODO: implement getMediaDetails
    throw UnimplementedError();
  }

  @override
  Future<List<ExtractorLink>> getLinks(String url) {
    // TODO: implement getLinks
    throw UnimplementedError();
  }

  @override
  Future<Media?> getMedia(ExtractorLink link) {
    // TODO: implement getMedia
    throw UnimplementedError();
  }
}
''';
}
