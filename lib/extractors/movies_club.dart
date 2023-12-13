// ignore_for_file: unnecessary_this

import 'dart:convert';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';

class MoviesClub extends ExtractorApi {
  MoviesClub(ExtractorLink extractorLink) : super(extractorLink);

  @override
  String get name => 'MoviesClub';

  final key = '1ftYriZmgY8qS0i';

  @override
  Future<Video> extract() async {
    final referer = this.extractorLink.referer ?? '';
    final response = (await AppUtils.httpRequest(
            url: this.extractorLink.url, method: 'GET', referer: referer))
        .text;

    final jsScript = _JsScript.fromHtml(response);

    final decrypted = CryptoUtils.AES(
      ciphertext: jsScript.ciphertext,
      key: this.key,
      encrypt: false,
      options: CryptoOptions(
          ivEncoding: 'hex', salt: jsScript.salt, iv: jsScript.iv),
    ).replaceAll('\\n', '\n').replaceAll('\\', '');

    final sources = ListUtils.mapList(
        json.decode(
            RegExp(r'sources: ([^\]]*\])').firstMatch(decrypted)?.group(1) ??
                '') as List, (e) {
      return toVideoSource(e);
    });
    final subtitleMatch =
        RegExp(r'tracks: ([^]*?\}\])').firstMatch(decrypted)?.group(1);

    final subtitles = subtitleMatch != null
        ? ListUtils.mapList(json.decode(subtitleMatch), (e) {
            return toSubtitle(e);
          })
        : null;

    return Video(subtitles: subtitles, videoSources: sources);
  }

  Subtitle toSubtitle(dynamic json) {
    final file = json['file'];
    return Subtitle(
        url: file,
        langauge: json['label'],
        format: AppUtils.getSubtitleFromatFromUrl(file));
  }

  VideoSource toVideoSource(dynamic json) {
    final labelStr = StringUtils.valueToString(json['label']).toLowerCase();
    final typeStr = StringUtils.valueToString(json['type']);
    return VideoSource(
      url: json['file'],
      format: getVidFormat(typeStr),
      quality: getVidQuality(labelStr),
    );
  }

  VideoFormat getVidFormat(String str) {
    if (str == 'hls') {
      return VideoFormat.hls;
    }
    return VideoFormat.mp4;
  }

  VideoQuality? getVidQuality(String str) {
    if (str == 'auto') {
      return null;
    }
    return VideoQuality.getFromString(str);
  }
}

class _JsScript {
  final String ciphertext;
  final String iv;
  final String salt;

  _JsScript({required this.ciphertext, required this.iv, required this.salt});

  factory _JsScript.fromHtml(String html) {
    final script = json.decode(
        RegExp(r"JScript\s*=\s*'([^']*)'").firstMatch(html)?.group(1) ?? '');

    return _JsScript(
      ciphertext: StringUtils.valueToString(script['ct']),
      iv: StringUtils.valueToString(script['iv']),
      salt: StringUtils.valueToString(script['s']),
    );
  }
}
