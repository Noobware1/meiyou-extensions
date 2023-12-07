import 'package:meiyou_extenstions/meiyou_extenstions.dart';

class ExamplePlugin extends BasePluginApi {
  @override
  // TODO: implement homePage
  Iterable<HomePageData> get homePage => throw UnimplementedError();

  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) {
    // TODO: implement loadHomePage
    throw UnimplementedError();
  }

  @override
  Future<List<ExtractorLink>> loadLinks(String url) {
    // TODO: implement loadLinks
    throw UnimplementedError();
  }

  @override
  Future<Media?> loadMedia(ExtractorLink link) {
    // TODO: implement loadMedia
    throw UnimplementedError();
  }

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) {
    // TODO: implement loadMediaDetails
    throw UnimplementedError();
  }

  @override
  Future<List<SearchResponse>> search(String query) {
    // TODO: implement search
    throw UnimplementedError();
  }
}


BasePluginApi main() {
  return ExamplePlugin();
}

