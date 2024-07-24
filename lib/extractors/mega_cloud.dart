// ignore_for_file: unnecessary_this, unnecessary_cast

import 'dart:convert';
import 'package:crypto_dart/crypto_dart.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/preference.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/response.dart';

class MegaCloud {
  MegaCloud({
    required this.client,
    required this.headers,
    required this.preferences,
  });

  final OkHttpClient client;
  final Headers headers;
  final SharedPreferences preferences;

  static const serverUrls = ['https://megacloud.tv', 'https://rapid-cloud.co'];
  static const sourcesUrls = [
    '/embed-2/ajax/e-1/getSources?id=',
    '/ajax/embed-6-v2/getSources?id='
  ];
  static const sourcesSplitters = ['/e-1/', '/embed-6-v2/'];
  static const sourcesKeys = ['1', '6'];
  static const e1ScriptUrl =
      'https://megacloud.tv/js/player/a/prod/e1-player.min.js';
  static const e6ScriptUrl =
      'https://rapid-cloud.co/js/player/prod/e6-player-v2.min.js';

  bool shouldUpdateKey = false;

  static const prefKeyKey = 'megacloud_key_';
  static const prefKeyDefault = '[[0,0]]';

  String _getScriptUrl(String type) {
    if (type == '1') {
      return e1ScriptUrl;
    } else {
      return e6ScriptUrl;
    }
  }

  Future<List<List<int>>> _getKey(String type) async {
    if (shouldUpdateKey) {
      await _updateKey(type);
      shouldUpdateKey = false;
    }
    final decoded = json.decode(
      preferences.getString(prefKeyKey + type, prefKeyDefault)!,
    );

    return ListUtils.mapList(
        decoded, (e) => ListUtils.mapList(e as List, (e) => e as int));
  }

  Future<void> _updateKey(String type) async {
    final scriptUrl = _getScriptUrl(type);

    final script = await client
        .newCall(GET(scriptUrl))
        .execute()
        .then((res) => (res as Response).body.string);

    final regex = RegExp(
        "case\\s*0x[0-9a-f]+:(?![^;]*=partKey)\\s*\\w+\\s*=\\s*(\\w+)\\s*,\\s*\\w+\\s*=\\s*(\\w+);");
    final matches = regex.allMatches(script).toList();

    final indexPairs = matches
        .map((match) {
          match as RegExpMatch;

          final var1 = match.group(1);
          final var2 = match.group(2);

          final regexVar1 = RegExp(",$var1=((?:0x)?([0-9a-fA-F]+))");
          final regexVar2 = RegExp(",$var2=((?:0x)?([0-9a-fA-F]+))");

          final matchVar1 =
              regexVar1.firstMatch(script)?.group(1)?.replaceFirst("0x", "");
          final matchVar2 =
              regexVar2.firstMatch(script)?.group(1)?.replaceFirst("0x", "");

          if (matchVar1 != null && matchVar2 != null) {
            try {
              return [
                int.parse(matchVar1 as String, radix: 16),
                int.parse(matchVar2 as String, radix: 16)
              ];
            } catch (e) {
              return [];
            }
          } else {
            return [];
          }
        })
        .where((e) => (e as List).isNotEmpty)
        .toList();

    final encoded = json.encode(indexPairs);
    preferences.setString(prefKeyKey + type, encoded);
  }

  Future<Video> getVideoFromLink(MediaLink link) async {
    final serverUrl = link.url;

    final type = (serverUrl.startsWith("https://megacloud.tv")) ? 0 : 1;
    final keyType = sourcesKeys[type];

    final id = StringUtils.substringBefore(
        StringUtils.substringAfter(serverUrl, MegaCloud.sourcesSplitters[type]),
        '?');

    final _EncryptedResponse data = await client
        .newCall(GET(serverUrls[type] + sourcesUrls[type] + id))
        .execute()
        .then((res) => (res as Response)
            .body
            .json((json) => _EncryptedResponse.fromJson(json)));

    final List<VideoSource> videoSources;

    if (!data.encrypted) {
      videoSources = toVideoSourceList(data.sources);
    } else {
      final ciphered = StringUtils.valueToString(data.sources);

      final decrypted = json.decode(await tryDecrypting(ciphered, keyType));

      videoSources = toVideoSourceList(decrypted);
    }

    data.tracks?.removeWhere((sub) => sub.language == 'thumbnails');

    return Video(
      sources: videoSources,
      subtitles: data.tracks,
    );
  }

  Future<String> tryDecrypting(String ciphered, String type,
      [attempts = 0]) async {
    if (attempts > 2) throw Exception("PLEASE NUKE ANIWATCH AND CLOUDFLARE");
    final result = await cipherTextCleaner(ciphered, type);
    final cipherText = result[0];
    final extractedKey = result[1];

    final decrypted = CryptoDart.enc.Utf8
        .stringify(CryptoDart.AES.decrypt(cipherText, extractedKey));

    if (decrypted.isEmpty) {
      shouldUpdateKey = true;
      return tryDecrypting(ciphered, type, attempts + 1);
    }

    return decrypted;
  }

  Future<List<String>> cipherTextCleaner(String data, String type) async {
    final decryptKey = await _getKey(type);

    List<String> sourcesArray = StringUtils.valueToString(data).split('');

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

    return [sourcesArray.join(''), extractedKey];
  }

  List<VideoSource> toVideoSourceList(dynamic sources) {
    return ListUtils.mapList(sources, (e) => toVideoSource(e));
  }

  VideoSource toVideoSource(dynamic e) {
    return VideoSource.hls(
      url: e['file'] as String,
    );
  }

  VideoFormat getVideoFormat(String type) {
    if (type == 'hls') {
      return VideoFormat.hls;
    }
    return VideoFormat.mp4;
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
