// ignore_for_file: unnecessary_this, unnecessary_cast

import 'dart:convert';
import 'package:crypto_dart/crypto_dart.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/response.dart';

class MegaCloud {
  MegaCloud(this.client);

  final OkHttpClient client;

  String getUrl(String serverUrl) {
    final baseUrl = StringUtils.substringBefore(serverUrl, "/embed");
    final embed = RegExp(r'embed-\d').firstMatch(serverUrl)!.group(0);
    final id = StringUtils.substringBefore(
        StringUtils.substringAfterLast(serverUrl, "/"), "?");

    final e = RegExp(r'e-\d').firstMatch(serverUrl)?.group(0) ?? '1';
    return '$baseUrl/$embed/ajax/$e/getSources?id=$id';
  }

  Future<Video> getVideoFromLink(ContentDataLink link) async {
    final serverUrl = link.data;
    final _EncryptedResponse response = await this
        .client
        .newCall(GET(
          getUrl(serverUrl),
          headers: getHeaders(serverUrl),
        ))
        .execute()
        .then((response) {
      response as Response;
      return response.body.json((json) => _EncryptedResponse.fromJson(json));
    });
    List<VideoSource> videoSources;
    if (!response.encrypted) {
      videoSources =
          ListUtils.mapList(response.sources, (e) => toVideoSource(e));
    } else {
      final decryptKey = await getDecryptKey();

      List<String> sourcesArray =
          StringUtils.valueToString(response.sources).split('');

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
      final decrypted = CryptoDart.enc.Utf8.stringify(
        CryptoDart.AES.decrypt(sourcesArray.join(''), extractedKey),
      );

      print(decrypted);

      videoSources =
          ListUtils.mapList(json.decode(decrypted), (e) => toVideoSource(e));
    }
    response.tracks?.removeWhere((sub) => sub.language == 'thumbnails');

    return Video(
      sources: videoSources,
      subtitles: response.tracks,
    );
  }

  String get keyUrl =>
      'https://raw.githubusercontent.com/Noobware1/zoro-keys/e1/key';

  Future<List<List<int>>> getDecryptKey() {
    return this.client.newCall(GET(keyUrl)).execute().then((response) {
      response as Response;
      return ListUtils.mapList(
        response.body.json((json) => json as List),
        (l) => ListUtils.mapList(
          l,
          (l) => StringUtils.toInt(StringUtils.valueToString(l)),
        ),
      );
    });
  }

  VideoSource toVideoSource(dynamic e) {
    return VideoSource.hls(
      url: e['file'] as String,
    ).copyWith(format: getVideoFormat(e['type']));
  }

  VideoFormat getVideoFormat(String type) {
    if (type == 'hls') {
      return VideoFormat.hls;
    }
    return VideoFormat.mp4;
  }

  Headers getHeaders(String referer) {
    return Headers.Builder()
        .add('X-Requested-With', 'XMLHttpRequest')
        .add('Referer', referer)
        .add('User-Agent',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:101.0) Gecko/20100101 Firefox/101.0')
        .build();
  }
}

class _EncryptedResponse {
  final dynamic sources;
  final List<Subtitle>? tracks;
  final bool encrypted;

  _EncryptedResponse({
    required this.sources,
    required this.tracks,
    required this.encrypted,
  });

  factory _EncryptedResponse.fromJson(Map<String, dynamic> json) {
    return _EncryptedResponse(
      sources: json['sources'],
      tracks: (AppUtils.isNotNull(json['tracks']))
          ? ListUtils.mapList(
              json['tracks'] as List,
              (e) => _EncryptedResponse.subtitleFromJson(e),
            )
          : null,
      encrypted: json['encrypted'],
    );
  }

  static Subtitle subtitleFromJson(dynamic e) {
    return Subtitle(
      url: e['file'],
      language: (AppUtils.isNotNull(e['label']))
          ? StringUtils.valueToString(e['label'])
          : 'thumbnails',
      format: AppUtils.getSubtitleFormatFromUrl(e['file']),
    );
  }
}
