// ignore_for_file: unnecessary_cast

import 'dart:convert';

import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/interceptor.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';
import 'package:yomiroll/src/access_token_interceptor.dart';

class Yomiroll extends HttpSource {
  Yomiroll(NetworkHelper networkHelper) : super(networkHelper);

  @override
  final String name = "Yomiroll";

  @override
  final String baseUrl = "https://crunchyroll.com";

  final String crUrl = "https://beta-api.crunchyroll.com";

  String get crApiUrl => "${this.crUrl}/content/v2";

  @override
  final String lang = "all";

  @override
  int get id => 7463514907068706782;

  @override
  OkHttpClient get client => super
      .client
      .newBuilder()
      .addInterceptor(Interceptor(
        (chain) => AccessTokenInterceptor(
          crUrl: this.crUrl,
          preferences: this.preferences,
          pref_use_local_token: Yomiroll.pref_use_local_token_key,
        ).intercept(chain),
      ))
      .build();

  OkHttpClient get noTokenClient => super.client;

  static const String pref_use_local_token_key = "preferred_local_Token";

  @override
  Iterable<HomePageData> get homePageList => HomePageData.fromMap({
        'popluar': 'sort_by=popularity',
        'latest': 'sort_by=newly_added',
      });

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    final start = (page != 1) ? "start=${(page - 1) * 36}&" : "";
    return GET(
        "${this.crApiUrl}/discover/browse?${start}n=36&${request.data}&locale=en-US");
  }

  SearchResponse toSearchResponse(dynamic json) {
    final images = (json['images']['poster_tall'] as List).first as List;

    final poster = ListUtils.getOrElse(
            images, images.length - 4, (index) => images.first)?['source']
        as String?;
    final title = json['title'];
    final type =
        (json['type'] == 'movie') ? ShowType.AnimeMovie : ShowType.Anime;

    final metaData = json['series_metadata'] ?? json['movie_metadata'];

    final List<String>? genres = runCatching(() {
      return ListUtils.mapList(
          metaData['tenant_categories'], (genre) => genre.toString());
    }).getOrNull();

    final description = buildString((it) {
      it as StringBuffer;
      it.writeln(json['description']);
      it.writeln();
      it.write('Language:');
      if ((metaData['subtitle_locales'] as List?)?.isNotEmpty == true ||
          metaData['is_subbed'] == true) {
        it.write(' Sub');
      }
      if ((metaData['audio_locales'] as List?)?.isNotEmpty == true ||
          metaData['is_dubbed'] == true) {
        it.write(' Dub');
      }
      it.writeln();
      it.write('Maturity Ratings: ');
      it.writeln((metaData['maturity_ratings'] as List?)?.join(' , ') ?? '-');
      if (metaData['is_simulcast'] == true) {
        it.writeln('Simulcast');
      }
      it.writeln();

      it.write('Audio: ');
      it.writeln((metaData['audio_locales'] as List?)?.join(' , ') ?? '-');
      it.writeln();

      it.write('Subs: ');
      it.writeln((metaData['subtitle_locales'] as List?)?.join(' , ') ?? '-');
    });

    return SearchResponse(
      title: title,
      url: jsonEncode({'id': json['id'], 'type': json['type'].toString()}),
      poster: poster!,
      type: type,
      description: description,
      generes: genres,
      current: metaData['episode_count'],
    );
  }

  @override
  HomePage homePageParse(int page, HomePageRequest request, Response response) {
    return response.body.json((json) {
      final data = ListUtils.mapList(
          json['data'] as List, (json) => toSearchResponse(json));

      final position = StringUtils.toIntOrNull(
              response.request.url.queryParameters["start"]) ??
          0;
      final total = json['total'] as int;
      return HomePage(
        data: HomePageList(name: request.name, data: data),
        page: page,
        hasNextPage: position + 36 < total,
      );
    });
  }

  @override
  FilterList getFilterList() {
    return FilterList([]);
  }

  @override
  Request linksRequest(String url) {
    // TODO: implement linksRequest
    throw UnimplementedError();
  }

  @override
  List<ExtractorLink> linksParse(Response response) {
    // TODO: implement linksParse
    throw UnimplementedError();
  }

  @override
  Future<MediaDetails> getMediaDetails(SearchResponse searchResponse) async {
    final media = MediaDetails()..copyFromSearchResponse(searchResponse);
    // media.status = await fetchStatusByTitle(media.name);
    return media;
  }

  @override
  MediaDetails mediaDetailsParse(Response response) {
    throw UnsupportedError('Not Used');
  }

  @override
  Request mediaDetailsRequest(SearchResponse searchResponse) {
    throw UnsupportedError('Not Used');
  }

  @override
  MediaItem? mediaItemParse(SearchResponse searchResponse, Response response) {
    throw UnsupportedError('not used');
  }

  @override
  Request? mediaItemRequest(SearchResponse searchResponse, Response response) {
    final decoded = jsonDecode(searchResponse.url);
    final id = decoded['id'] as String;
    final type = decoded['type'] as String;
    if (type == "series") {
      return GET("${this.crApiUrl}/cms/series/$id/seasons");
    } else {
      return GET("${this.crApiUrl}/cms/movie_listings/$id/movies");
    }
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

  @override
  List<SearchResponse> searchParse(Response response) {
    return response.body.json((json) {
      final data = (json['data'] as List).first;
      return ListUtils.mapList(
          data['items'] as List, (json) => toSearchResponse(json));
    });
  }

  @override
  Request searchRequest(int page, String query, FilterList filters) {
    // val params = YomirollFilters.getSearchParameters(filters)
    final start = (page != 1) ? "start=${(page - 1) * 36}&" : "";
    final cleanQuery = query.replaceFirst(" ", "+").toLowerCase();
    final String url =
        "$crApiUrl/discover/search?${start}n=36&q=$cleanQuery&type=top_results";
    // if (query.isNotEmpty) {
    // }
    return GET(url);
  }
}
