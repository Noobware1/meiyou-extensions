// ignore_for_file: unnecessary_string_interpolations

import 'dart:convert';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';
import 'package:meiyou_extenstions/ok_http/ok_http.dart';

class Dailymotion extends BasePluginApi {
  @override
  String get baseUrl => 'https://www.dailymotion.com';

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
  Future<List<SearchResponse>> search(String query) async {
    final body = {
      "operationName": "SEARCH_QUERY",
      "variables": {
        "query": "$query",
        "shouldIncludeVideos": true,
        "page": 1,
        "limit": 20
      },
      "query": searchQuery
    };

    final res = await AppUtils.httpRequest(
        url: 'https://graphql.api.dailymotion.com/',
        method: 'POST',
        body: json.encode(body),
        headers: {
          'Accept': "*/*, */*",
          'Authorization':
              "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhaWQiOiJmMWEzNjJkMjg4YzFiOTgwOTljNyIsInJvbCI6ImNhbi1tYW5hZ2UtcGFydG5lcnMtcmVwb3J0cyBjYW4tcmVhZC12aWRlby1zdHJlYW1zIGNhbi1zcG9vZi1jb3VudHJ5IGNhbi1hZG9wdC11c2VycyBjYW4tcmVhZC1jbGFpbS1ydWxlcyBjYW4tbWFuYWdlLWNsYWltLXJ1bGVzIGNhbi1tYW5hZ2UtdXNlci1hbmFseXRpY3MgY2FuLXJlYWQtbXktdmlkZW8tc3RyZWFtcyBjYW4tZG93bmxvYWQtbXktdmlkZW9zIGFjdC1hcyBhbGxzY29wZXMgYWNjb3VudC1jcmVhdG9yIGNhbi1yZWFkLWFwcGxpY2F0aW9ucyIsInNjbyI6InJlYWQgd3JpdGUgZGVsZXRlIGVtYWlsIHVzZXJpbmZvIGZlZWQgbWFuYWdlX3ZpZGVvcyBtYW5hZ2VfY29tbWVudHMgbWFuYWdlX3BsYXlsaXN0cyBtYW5hZ2VfdGlsZXMgbWFuYWdlX3N1YnNjcmlwdGlvbnMgbWFuYWdlX2ZyaWVuZHMgbWFuYWdlX2Zhdm9yaXRlcyBtYW5hZ2VfbGlrZXMgbWFuYWdlX2dyb3VwcyBtYW5hZ2VfcmVjb3JkcyBtYW5hZ2Vfc3VidGl0bGVzIG1hbmFnZV9mZWF0dXJlcyBtYW5hZ2VfaGlzdG9yeSBpZnR0dCByZWFkX2luc2lnaHRzIG1hbmFnZV9jbGFpbV9ydWxlcyBkZWxlZ2F0ZV9hY2NvdW50X21hbmFnZW1lbnQgbWFuYWdlX2FuYWx5dGljcyBtYW5hZ2VfcGxheWVyIG1hbmFnZV9wbGF5ZXJzIG1hbmFnZV91c2VyX3NldHRpbmdzIG1hbmFnZV9jb2xsZWN0aW9ucyBtYW5hZ2VfYXBwX2Nvbm5lY3Rpb25zIG1hbmFnZV9hcHBsaWNhdGlvbnMgbWFuYWdlX2RvbWFpbnMgbWFuYWdlX3BvZGNhc3RzIiwibHRvIjoiYm5wbWZUSUZYMlpxZkNONVFRc05YaDhaZGh3WUJXUjRIa01iZEEiLCJhaW4iOjEsImFkZyI6MSwiaWF0IjoxNzAyNzM1MzQxLCJleHAiOjE3MDI3NzEwMjIsImRtdiI6IjEiLCJhdHAiOiJicm93c2VyIiwiYWRhIjoid3d3LmRhaWx5bW90aW9uLmNvbSIsInZpZCI6ImU0OGI2ZmI0LTgwYzktNGYyMy05NTE3LWYyZjZiYzU1NDZlMyIsImZ0cyI6MTM0MjM2LCJjYWQiOjIsImN4cCI6MiwiY2F1IjoyLCJraWQiOiJBRjg0OURENzNBNTg2M0NEN0Q5N0QwQkFCMDcyMjQzQiJ9.xA9f_WEdCqGA8IYwr8BNx2yBES3V5k0M2ssqlDzy9gg",
          'Connection': "keep-alive",
          'Content-Type': "application/json, application/json",
          'Origin': "https://www.dailymotion.com",
          'Referer': "https://www.dailymotion.com/search/shincham/videos",
          'Sec-Fetch-Dest': "empty",
          'Sec-Fetch-Mode': "cors",
          'Sec-Fetch-Site': "same-site",
          'User-Agent':
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0",
          'X-DM-AppInfo-Id': "com.dailymotion.neon",
          'X-DM-AppInfo-Type': "website",
          'X-DM-AppInfo-Version': "v2023-12-14T11:28:07.907Z",
          'X-DM-Neon-SSR': "0",
          'X-DM-Preferred-Country': "in",
          'accept-language': "en-US",
          'x-dm-visit-id': "1702735339220",
          'x-dm-visitor-id': "e48b6fb4-80c9-4f23-9517-f2f6bc5546e3"
        });

    return res.json((json) {
      final list = json['data']?['search']?['videos']['edges'] as List;

      return ListUtils.mapList(list, (e) => toSearchResponse(e['node']));
    });
  }

  SearchResponse toSearchResponse(dynamic e) {
    final img = e['thumbnailx720'] ??
        e['thumbnailx60'] ??
        e['thumbnailx240'] ??
        e['thumbnailx120'];

    return SearchResponse(
        title: e['title'],
        url: e['xid'],
        poster: StringUtils.valueToString(img),
        type: ShowType.Others);
  }
}

// BasePluginApi main() {
//   return Dailymotion();
// }
final searchQuery = '''
fragment VIDEO_BASE_FRAGMENT on Video {
  id
  xid
  title
  createdAt
  stats {
    id
    views {
      id
      total
      __typename
    }
    __typename
  }
  channel {
    id
    xid
    name
    displayName
    accountType
    __typename
  }
  duration
  thumbnailx60: thumbnailURL(size: "x60")
  thumbnailx120: thumbnailURL(size: "x120")
  thumbnailx240: thumbnailURL(size: "x240")
  thumbnailx720: thumbnailURL(size: "x720")
  aspectRatio
  __typename
}

query SEARCH_QUERY(\$query: String!, \$shouldIncludeVideos: Boolean!, \$page: Int, \$limit: Int, \$sortByVideos: SearchVideoSort, \$durationMinVideos: Int, \$durationMaxVideos: Int, \$createdAfterVideos: DateTime) {
  search {
    id
    videos(
      query: \$query
      first: \$limit
      page: \$page
      sort: \$sortByVideos
      durationMin: \$durationMinVideos
      durationMax: \$durationMaxVideos
      createdAfter: \$createdAfterVideos
    ) @include(if: \$shouldIncludeVideos) {
      pageInfo {
        hasNextPage
        nextPage
        __typename
      }
      totalCount
      edges {
        node {
          id
          ...VIDEO_BASE_FRAGMENT
          __typename
        }
        __typename
      }
      __typename
    }
  }
}
''';
