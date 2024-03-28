// ignore_for_file: unnecessary_this, unnecessary_cast

import 'package:kickassanime/src/kickassanime_extractor.dart';
import 'package:kickassanime/src/preferences.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';

import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

class KickAssAnime extends HttpSource {
  KickAssAnime();

  @override
  int get id => 2081771513481539599;

  @override
  String get name => 'KickAssAnime';

  @override
  String get lang => 'en';

  @override
  String get baseUrl => this
      .preferences
      .getString(Preferences.pref_domain_key, Preferences.pref_domain_default)!;

  String get apiUrl => '${this.baseUrl}/api/show';

  @override
  List<HomePageRequest> homePageRequests() {
    return [
      HomePageRequest(name: 'Popular', data: '${this.apiUrl}/popular'),
      HomePageRequest(
          name: 'Latest Sub', data: '${this.apiUrl}/recent?type=sub'),
      HomePageRequest(
          name: 'Latest Dub', data: '${this.apiUrl}/recent?type=dub'),
      HomePageRequest(
          name: 'Latest Donghua', data: '${this.apiUrl}/recent?type=chinese'),
    ];
  }

  @override
  Request homePageRequest(int page, HomePageRequest request) {
    final String url = buildString((it) {
      it as StringBuffer;
      it.write(request.data);
      it.write(request.name == 'Popular' ? '?' : '&');
      it.write('page=$page');
    });
    print(url);
    return GET(url);
  }

  @override
  HomePage homePageParse(int page, HomePageRequest request, Response response) {
    final json = response.body.json();

    final bool hasNext;
    if (request.name == 'Popular') {
      final int pageCount = json['page_count'];
      final page = StringUtils.toIntOrNull(
              response.request.url.queryParameters['page']) ??
          0;
      hasNext = pageCount > page;
    } else {
      hasNext = json['hadNext'] as bool;
    }

    return HomePage.fromRequest(
      reqeust: request,
      items: contentItemsFromJson(json),
      hasNextPage: hasNext,
    );
  }

  List<ContentItem> contentItemsFromJson(dynamic json) {
    final useEnglish = this.preferences.getBool(
        Preferences.pref_use_english_key,
        Preferences.PREF_USE_ENGLISH_DEFAULT)!;

    return ListUtils.mapList(json['result'] as List, (json) {
      final List<String>? genres = runCatching(
        () => ListUtils.mapList(json['genres'], (it) => it.toString()),
      ).getOrNull();

      final String title;
      // final String? englishTitle = json['title_en'];
      // if (useEnglish && englishTitle != null && englishTitle.isNotEmpty) {
      //   title = englishTitle;
      // } else {
      title = json['title'];
      // }

      return ContentItem(
        title: title,
        url: json['slug'],
        description: json['synopsis'],
        // currentCount:
        //     StringUtils.toIntOrNull(json['episode_number'].toString()),
        poster: '${this.baseUrl}${Poster.fromJson(json['poster'])!.poster}',
        category: getCategory(json['type']),
        generes: genres,
      );
    });
  }

  @override
  Request infoPageRequest(ContentItem contentItem) =>
      GET('${this.apiUrl}/${contentItem.url}');

  @override
  Future<InfoPage> infoPageParse(
      ContentItem contentItem, Response response) async {
    return response.body.json((json) {
      final startDate =
          DateTime.tryParse(StringUtils.valueToString(json['start_date']));

      String? banner = Poster.fromJson(json["banner"])?.banner;
      if (banner != null) {
        banner = this.baseUrl + banner;
      }

      final status = getStatus(json['status']);

      final duration = Duration(
        milliseconds: StringUtils.toInt(json['episode_duration'].toString()),
      );
      List<String>? otherTitles;
      final originalTitle = json['title_original'] as String?;
      if (originalTitle != null) {
        otherTitles = [originalTitle];
      }

      return InfoPage.withItem(
        contentItem,
        bannerImage: banner,
        startDate: startDate,
        otherTitles: otherTitles,
        status: status,
        duration: duration,
        content: Anime.lazy(() {
          final String slug = json['slug'];
          final List<String> locales = json['locales'];

          return getAnime(slug, locales);
        }),
      );
    });
  }

  Request episodeListRequest(String url, int page, String lang) =>
      GET("$apiUrl/$url/episodes?ep=1&page=$page&lang=$lang");

  EpisodeResponse episodeListParse(String url, Response response) {
    return response.body.json((json) {
      final total = (json['pages'] as List).length;
      final episodes = ListUtils.mapList(json['result'] as List, (json) {
        final int number = json['episode_number'];
        return Episode(
          number: number,
          name: json['title'],
          data: '$url/ep-$number-${json['slug'].toString()}',
          image: this.baseUrl + Poster.fromJson(json['thumbnail'])!.thumbnail,
        );
      });

      return EpisodeResponse(episodes: episodes, total: total);
    });
  }

  Future<EpisodeResponse> getEpisodeRsponse(
      Request episodeRequest, String url) {
    return this.client.newCall(episodeRequest).execute().then((response) {
      return episodeListParse(url, response);
    });
  }

  Future<Anime> getAnime(String url, List<String> locales) async {
    final prefLang = this.preferences.getString(
        Preferences.pref_audio_lang_key, Preferences.pref_audio_lang_default)!;
    final lang = locales.firstWhere((element) => element == prefLang,
        orElse: () => locales.first);

    final List<Episode> episodes = [];
    final first =
        await getEpisodeRsponse(episodeListRequest(url, 1, lang), url);

    episodes.addAll(first.episodes);

    for (var i = 1; i < first.total; i++) {
      final episodeResponse =
          await getEpisodeRsponse(episodeListRequest(url, i + 1, lang), url);

      episodes.addAll(episodeResponse.episodes);
    }

    return Anime(episodes);
  }

  @override
  FilterList getFilterList() => FilterList([]);

  @override
  Request searchPageRequest(int page, String query, FilterList filters) {
    final newHeaders = this
        .headers
        .newBuilder()
        .add("Accept", "application/json, text/plain, */*")
        .add("Host", Uri.parse(this.baseUrl).host)
        .add("Referer", "${this.baseUrl}/anime")
        .build();

    final body = RequestBody.fromMap(
      {"query": query, "page": page},
      RequestBodyType.JSON,
    );

    return POST("$baseUrl/api/fsearch", headers: newHeaders, body: body);
  }

  @override
  SearchPage searchPageParse(
      int page, String query, FilterList filters, Response response) {
    return response.body.json((json) {
      return SearchPage(
          hasNextPage: json['maxPage'] > page,
          items: contentItemsFromJson(json));
    });
  }

  @override
  Request contentDataLinksRequest(String url) =>
      GET('${this.apiUrl}/${url.replaceFirst("/ep-", "/episode/ep-")}');

  @override
  List<ContentDataLink> contentDataLinksParse(String url, Response response) {
    final hosterselection = this.preferences.getStringList(
        Preferences.pref_hoster_key, Preferences.pref_hoster_default)!;

    return response.body.json((json) {
      final List<ContentDataLink> links = [];
      final List<dynamic> servers = json['servers'];

      for (var server in servers) {
        final String name = server['name'];
        if (hosterselection.contains(name)) {
          links.add(ContentDataLink(
            name: name,
            data: server['src'],
            extra: {'shortName': server['shortName'].toString()},
          ));
        }
      }

      return links;
    });
  }

  @override
  Future<ContentData?> getContentData(ContentDataLink link) {
    return KickAssAnimeExtractor(this.client, this.headers).extract(link);
  }

  ContentCategory getCategory(String str) {
    if (str == 'tv') {
      return ContentCategory.Anime;
    } else if (str == 'ona') {
      return ContentCategory.Ona;
    } else if (str == 'movie') {
      return ContentCategory.AnimeMovie;
    } else {
      return ContentCategory.Anime;
    }
  }

  Status getStatus(String str) {
    if (str == 'currently_airing') {
      return Status.Ongoing;
    } else if (str == 'finished_airing') {
      return Status.Completed;
    } else {
      return Status.Unknown;
    }
  }
}

class EpisodeResponse {
  final List<Episode> episodes;
  final int total;

  EpisodeResponse({required this.episodes, required this.total});
}

class Poster {
  final String format;
  final String? sm;
  final String? hq;

  Poster({
    required this.format,
    required this.sm,
    required this.hq,
  });

  static Poster? fromJson(dynamic json) {
    if (AppUtils.isNotNull(json)) {
      return Poster(
        format: (json["formats"] as List).last.toString(),
        sm: json["sm"],
        hq: json["hq"],
      );
    } else {
      return null;
    }
  }

  String get poster => '/image/poster/${hq ?? sm ?? ''}.$format';
  String get banner => '/image/banner/${hq ?? sm ?? ''}.$format';
  String get thumbnail => '/image/thumbnail/${sm ?? hq ?? ''}.$format';
}
