// ignore_for_file: unnecessary_cast, unnecessary_this

import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

class Animepahe extends BasePluginApi {
  Animepahe();

  @override
  String get baseUrl => 'https://animepahe.ru';

  // ============================== HomePage ===================================
  @override
  Iterable<HomePageData> get homePage => HomePageData.fromMap({});

  // ============================== LoadHomePage ===============================
  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) {
    throw UnimplementedError();
  }

  // =========================== LoadMediaDetails ==============================
  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) {
    throw UnimplementedError();
  }

  // =============================== LoadLinks =================================
  @override
  Future<List<ExtractorLink>> loadLinks(String url) {
    throw UnimplementedError();
  }

  // =============================== LoadMedia =================================
  @override
  Future<Media?> loadMedia(ExtractorLink link) {
    throw UnimplementedError();
  }

  // ================================ Search ===================================
  @override
  Future<List<SearchResponse>> search(String query) {
    throw UnimplementedError();
  }

  // ================================ Helpers ==================================
}

main() {
  return Animepahe();
}
