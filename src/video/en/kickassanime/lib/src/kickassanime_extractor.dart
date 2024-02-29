// ignore_for_file: unnecessary_cast

import 'dart:convert';

import 'package:crypto_dart/crypto_dart.dart';
import 'package:crypto_dart/hashers.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/response.dart';

class KickAssAnimeExtractor {
  final OkHttpClient client;
  final Headers headers;
  KickAssAnimeExtractor(this.client, this.headers);

  static const Map<String, String> keysMap = {
    "duck": "4504447b74641ad972980a6b8ffd7631",
    "bird": "4b14d0ff625163e3c9c7a47926484bf2",
    "vid": "e13d38099bf562e8b9851a652d2043d3",
  };

  Future<Video> extract(ExtractorLink link) async {
    final String shortName = link.extra!['shortName'];
    final uri = Uri.parse(link.url);
    final String key = keysMap[shortName]!;
    final source = await this
        .client
        .newCall(GET(getSourceUrl(shortName, uri, key)))
        .execute()
        .then((response) {
      response as Response;
      return response.body.json((json) => (json['data'] as String).split(':'));
    });

    final decrypted = SourceDecrypted.decode(
        CryptoDart.enc.UTF8.stringify(CryptoDart.AES.decrypt(
      source[0],
      key,
      options: CipherOptions(
        iv: source[1],
        ivEncoding: 'hex',
        keyEncoding: 'utf8',
        textEncoding: 'base64',
      ),
    )));

    final List<VideoSource> videosSources = [];

    if (decrypted.hls != null) {
      videosSources.add(decrypted.hls!);
    }
    if (decrypted.dash != null) {
      videosSources.add(decrypted.dash!);
    }

    return Video(
      videoSources: videosSources,
      subtitles: decrypted.subtitles,
      headers: getVideoHeaders(this.headers, uri.host),
    );
  }

  Headers getVideoHeaders(Headers baseHeaders, String host) {
    return baseHeaders
        .newBuilder()
        .add("Accept", "*/*")
        .add("Accept-Language", "en-US,en;q=0.5")
        .add("Origin", "https://$host")
        .add("Sec-Fetch-Dest", "empty")
        .add("Sec-Fetch-Mode", "cors")
        .add("Sec-Fetch-Site", "cross-site")
        .build();
  }

  Future<String> getSourceUrl(String shortName, Uri uri, String key) async {
    final host = uri.host;
    final mid = (shortName == "duck") ? "mid" : "id";
    final query = uri.queryParameters[mid] ?? '';
    final playerConfig = await this
        .client
        .newCall(GET(uri))
        .execute()
        .then((response) => (response as Response).body.string);

    final signature = getSignature(playerConfig, shortName, query, key);

    final sourceUrl = buildString((it) {
      it as StringBuffer;
      it.write('https://$host${signature.route}?$mid=$query');
      if (shortName != "bird") {
        it.write('&e=${signature.timeStamp}');
      }
      it.write('&s=${signature.signature}');
    });

    return sourceUrl;
  }

  Signature getSignature(
      String html, String shortName, String query, String key) {
    final encodedCid = StringUtils.substringBefore(
        StringUtils.substringAfter(html, "cid: '"), "'");

    final cid = CryptoDart.enc.UTF8
        .stringify(CryptoDart.enc.HEX.parse(encodedCid))
        .split('|');

    final route = cid[1].replaceFirst("player.php", "source.php");
    final timeStamp = StringUtils.valueToString(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60));

    var signature = buildString((it) {
      it as StringBuffer;
      for (var item in KickAssAnimeExtractor.order[shortName] ?? []) {
        if (item == 'IP') {
          it.write(cid[0]);
        } else if (item == 'USERAGENT') {
          it.write(this.headers.get('User-Agent') ?? '');
        } else if (item == 'ROUTE') {
          it.write(route);
        } else if (item == 'MID') {
          it.write(query);
        } else if (item == 'TIMESTAMP') {
          it.write(timeStamp);
        } else if (item == 'ID') {
          it.write(query);
        } else if (item == 'KEY') {
          it.write(key);
        }
      }
    });

    return Signature(SHA1(signature).toString(), route, timeStamp);
  }

  static const order = {
    'duck': ['IP', 'USERAGENT', 'ROUTE', 'MID', 'TIMESTAMP', 'KEY'],
    'bird': ['IP', 'USERAGENT', 'ROUTE', 'ID', 'KEY'],
    'vid': ['IP', 'USERAGENT', 'ROUTE', 'ID', 'TIMESTAMP', 'KEY'],
  };
}

class SourceDecrypted {
  final VideoSource? hls;
  final VideoSource? dash;
  final List<Subtitle>? subtitles;

  SourceDecrypted({this.hls, this.dash, this.subtitles});

  factory SourceDecrypted.decode(String jsonString) {
    return SourceDecrypted.fromJson(jsonDecode(jsonString));
  }

  factory SourceDecrypted.fromJson(dynamic json) {
    final host = SourceDecrypted.getHost(json);
    final List? subtitles = json['subtitles'];
    return SourceDecrypted(
      hls: SourceDecrypted.toVideoSource(json['hls'], true),
      dash: SourceDecrypted.toVideoSource(json['dash'], false),
      subtitles: (subtitles != null)
          ? ListUtils.mapList(
              subtitles, (e) => SourceDecrypted.toSubtitle(host, e))
          : null,
    );
  }

  static String getHost(dynamic json) {
    final String url;
    if (AppUtils.isNotNull(json['hls'])) {
      url = StringUtils.valueToString(json['hls']);
    } else {
      url = StringUtils.valueToString(json['dash']);
    }
    return Uri.parse(AppUtils.httpify(url)).host;
  }

  static VideoSource? toVideoSource(dynamic url, bool isHLS) {
    if (AppUtils.isNotNull(url)) {
      return VideoSource(
          format: (isHLS) ? VideoFormat.hls : VideoFormat.dash,
          quality: (isHLS) ? VideoQuality.hlsMaster : VideoQuality.unknown,
          url: AppUtils.httpify(url.toString()));
    }
    return null;
  }

  static Subtitle toSubtitle(String host, dynamic json) {
    var subtitleUrl = AppUtils.httpify(json['src'].toString());

    if (subtitleUrl.startsWith('/')) {
      subtitleUrl = 'https://$host$subtitleUrl';
    }
    return Subtitle(
      url: subtitleUrl,
      language: json['name'],
      format: AppUtils.getSubtitleFormatFromUrl(subtitleUrl),
    );
  }
}

class Signature {
  final String signature;
  final String route;
  final String timeStamp;

  Signature(this.signature, this.route, this.timeStamp);
}
