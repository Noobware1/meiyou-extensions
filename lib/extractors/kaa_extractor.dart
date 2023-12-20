// ignore_for_file: unnecessary_this

import 'dart:convert';

import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

class KickAssAnimeExtractor extends ExtractorApi {
  KickAssAnimeExtractor(ExtractorLink extractorLink) : super(extractorLink);

  @override
  String get name => 'KickAssAnime';

  static const _keysMap = {
    "duck": "4504447b74641ad972980a6b8ffd7631",
    "bird": "4b14d0ff625163e3c9c7a47926484bf2",
    "vid": "e13d38099bf562e8b9851a652d2043d3",
  };

  static const _useragent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0';

  @override
  Future<Video> extract() async {
    final shortName = this.extractorLink.headers?['shortName'] as String;
    final uri = Uri.parse(this.extractorLink.url);

    final source = (await AppUtils.httpRequest(
            url: await _getUrl(shortName, uri),
            method: 'GET',
            referer: this.extractorLink.url,
            headers: {'User-Agent': _useragent}))
        .json((json) => _parseJson(json));

    final key = StringUtils.valueToString(_keysMap[shortName]);

    final decrypted = _SourceDecrypted.decode(CryptoUtils.AES(
        ciphertext: source[0],
        key: key,
        encrypt: false,
        options: CryptoOptions(
          textEncoding: 'base64',
          iv: source[1],
          ivEncoding: 'hex',
          keyEncoding: 'utf8',
        )));

    final List<VideoSource> videosSources = [];

    ListUtils.addIfNotNull(videosSources, decrypted.hls);

    ListUtils.addIfNotNull(videosSources, decrypted.dash);

    return Video(
      videoSources: videosSources,
      subtitles: decrypted.subtitles,
      headers: _getVideoHeaders(uri.host),
    );
  }

  Map<String, String> _getVideoHeaders(String host) {
    return {
      'Accept': "*/*",
      'Accept-Language': "en-US,en;q=0.5",
      'Origin': "https://$host",
      'Sec-Fetch-Dest': "empty",
      'Sec-Fetch-Mode': "cors",
      'Sec-Fetch-Site': "cross-site"
    };
  }

  Future<String> _getUrl(String shortName, Uri uri) async {
    final host = uri.host;
    final mid = (shortName == "duck") ? "mid" : "id";
    final query = uri.queryParameters[mid] ?? '';
    final playerConfig =
        (await AppUtils.httpRequest(url: this.extractorLink.url, method: 'GET'))
            .text;

    final signature = _getSignature(playerConfig, shortName, query);

    if (shortName == "bird") {
      return 'https://$host${signature.route}?$mid=$query&s=${signature.signature}';
    } else {
      return 'https://$host${signature.route}?$mid=$query&e=${signature.timeStamp}&s=${signature.signature}';
    }
  }

  static _Signature _getSignature(String html, String shortName, String query) {
    final encodedCid = StringUtils.substringBefore(
        StringUtils.substringAfter(html, "cid: '"), "'");
    final cid = CryptoUtils.EncStringify(
            'utf8', CryptoUtils.EncParse('hex', encodedCid))
        .split('|');

    final route = cid[1].replaceFirst("player.php", "source.php");
    final timeStamp = StringUtils.valueToString(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60));
    var signature = '';
    for (var e in order[shortName] ?? []) {
      if (e == 'IP') {
        signature += cid[0];
      } else if (e == 'USERAGENT') {
        signature += _useragent;
      } else if (e == 'ROUTE') {
        signature += route;
      } else if (e == 'MID') {
        signature += query;
      } else if (e == 'TIMESTAMP') {
        signature += timeStamp;
      } else if (e == 'ID') {
        signature += query;
      } else if (e == 'KEY') {
        signature += KickAssAnimeExtractor._keysMap[shortName] ?? '';
      }
    }

    return _Signature(
        CryptoUtils.HashString('sha1', signature), route, timeStamp);
  }

  List<String> _parseJson(dynamic json) {
    return StringUtils.valueToString(json['data']).split(":");
  }

  static const order = {
    'duck': ['IP', 'USERAGENT', 'ROUTE', 'MID', 'TIMESTAMP', 'KEY'],
    'bird': ['IP', 'USERAGENT', 'ROUTE', 'ID', 'KEY'],
    'vid': ['IP', 'USERAGENT', 'ROUTE', 'ID', 'TIMESTAMP', 'KEY'],
  };
}

class _SourceDecrypted {
  final VideoSource? hls;
  final VideoSource? dash;
  final List<Subtitle>? subtitles;

  _SourceDecrypted({this.hls, this.dash, this.subtitles});

  factory _SourceDecrypted.decode(String jsonString) {
    return _SourceDecrypted.fromJson(json.decode(jsonString));
  }

  factory _SourceDecrypted.fromJson(dynamic json) {
    final host = _SourceDecrypted.getHost(json);

    return _SourceDecrypted(
      hls: _SourceDecrypted.toVideoSource(json['hls'], true),
      dash: _SourceDecrypted.toVideoSource(json['dash'], false),
      subtitles: ListUtils.mapNullable(
          json['subtitles'], (e) => _SourceDecrypted.toSubtitle(host, e)),
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
          format: _SourceDecrypted.getFormat(isHLS),
          quality: _SourceDecrypted.getQuality(isHLS),
          url: AppUtils.httpify(StringUtils.valueToString(url)));
    }
    return null;
  }

  static VideoFormat getFormat(bool isHLS) {
    if (isHLS) {
      return VideoFormat.hls;
    }
    return VideoFormat.dash;
  }

  static VideoQuality getQuality(bool isHLS) {
    if (isHLS) {
      return VideoQuality.hlsMaster;
    }
    return VideoQuality.unknown;
  }

  static Subtitle toSubtitle(String host, dynamic json) {
    var subtitleUrl = AppUtils.httpify(StringUtils.valueToString(json['src']));

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

class _Signature {
  final String signature;
  final String route;
  final String timeStamp;

  _Signature(this.signature, this.route, this.timeStamp);
}
