part of '../make_source.dart';

String getSourceTemplate(String sourceName) {
  return '''
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:$sourceName/src/$sourceName.dart';

Source main() {
  return ${StringUtils.capitalize(sourceName)}();
}
''';
}

String sourceTemplate(String sourceName) {
  return '''
// ignore_for_file: unnecessary_this, unnecessary_cast

import 'package:meiyou_extensions_lib/models.dart';

class ${StringUtils.capitalize(sourceName)} extends Source {
  @override
  int get id => throw UnimplementedError();
 
  @override
  String get name => throw UnimplementedError();


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
