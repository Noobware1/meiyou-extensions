// ignore_for_file: unnecessary_this

import 'dart:convert';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

//Copied from mega_cloud.dart because dart_eval won't let me extend it :(
class RabbitStream extends ExtractorApi {
  RabbitStream(ExtractorLink extractorLink) : super(extractorLink);

  String get hostUrl =>
      StringUtils.substringBefore(this.extractorLink.url, '/embed');

  String getUrl() {
    final serverUrl = this.extractorLink.url;
    final embed = RegExp(r'embed-\d').firstMatch(serverUrl)?.group(0);
    final id = StringUtils.substringBefore(
        StringUtils.substringAfterLast(serverUrl, "/"), "?");

    return '$hostUrl/ajax/$embed/getSources?id=$id';
  }

  @override
  Future<Video> extract() async {
    final jsonLink = getUrl();

    final response =
        (await AppUtils.httpRequest(url: jsonLink, method: 'GET', headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'Referer': this.extractorLink.url,
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:101.0) Gecko/20100101 Firefox/101.0',
    }))
            .json();

    final List<VideoSource> sources;

    if (response['encrypted'] == false) {
      sources = ListUtils.mapList(
          (response['sources'] as List), (e) => toVideoSource(e));
    } else {
      final decryptKey = await getDecryptKey();

      List<String> sourcesArray =
          StringUtils.valueToString(response['sources']).split('');

      var extractedKey = '';
      var currentIndex = 0;
      for (var index in decryptKey) {
        var start = index[0] + currentIndex;
        var end = start + index[1];

        for (var i = start; i < end; i++) {
          extractedKey += sourcesArray[i];
          sourcesArray[i] = '';
        }

        currentIndex += index[1];
      }
      final decrypted = CryptoUtils.AES(
          ciphertext: sourcesArray.join(''), key: extractedKey, encrypt: false);

      sources = ListUtils.mapList(
          (json.decode(decrypted) as List), (e) => toVideoSource(e));
    }
    final List<Subtitle>? tracks;

    if (response['tracks'] == null) {
      tracks = null;
    } else {
      tracks = ListUtils.mapList((response['tracks'] as List), (e) {
        return toSubtitle(e);
      }).where((e) => removeThumbnail(e)).toList();
    }

    return Video(
      videoSources: sources,
      subtitles: tracks,
    );
  }

  String get keyUrl =>
      'https://raw.githubusercontent.com/Noobware1/zoro-keys/e4/key';

  Future<List<List<int>>> getDecryptKey() async {
    return (await AppUtils.httpRequest(url: keyUrl, method: 'GET'))
        .json<List<List<int>>>((json) {
      return ListUtils.mapList(
        json as List,
        (l) => ListUtils.mapList(
            l, (l) => StringUtils.toInt(StringUtils.valueToString(l))),
      );
    });
  }

  VideoSource toVideoSource(dynamic e) {
    return VideoSource(
      url: e['file'],
      quality: VideoQuality.hlsMaster,
      format: getVideoFormat(StringUtils.valueToString(e['type'])),
    );
  }

  bool removeThumbnail(Subtitle e) {
    return e.language != 'thumbnails';
  }

  VideoFormat getVideoFormat(String type) {
    if (type == 'hls') {
      return VideoFormat.hls;
    }
    return VideoFormat.mp4;
  }

  Subtitle toSubtitle(dynamic e) {
    return Subtitle(
      url: e['file'],
      language: e['label'] ?? 'thumbnails',
      format: AppUtils.getSubtitleFormatFromUrl(e['file']),
    );
  }

  @override
  String get name => 'MegaCloud';
}
