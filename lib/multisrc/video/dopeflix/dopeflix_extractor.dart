// ignore_for_file: unnecessary_cast

import 'dart:convert';

import 'package:crypto_dart/crypto_dart.dart';
import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';

void main(List<String> args) {
  final MediaLink link = MediaLink.fromJson(jsonDecode(r'''
{
  "name": "Vidcloud",
  "data": "https://rabbitstream.net/v2/embed-4/EDUZMCvBvyxq?z=",
  "headers": null,
  "referer": null,
  "extra": null
}
'''));

  final client = ExtensionlibOverrides.networkHelper.client;

  final extractor = DopeFlixExtractor(client);

  extractor.extract(link).then((value) {
    print(value);
  });
}

class DopeFlixExtractor {
  final OkHttpClient client;

  DopeFlixExtractor(this.client);

  static const sourcePath = "/ajax/v2/embed-4/getSources?id=";
  static const scriptUrl =
      "https://rabbitstream.net/js/player/prod/e4-player.min.js";

  Future<Video> extract(MediaLink link) async {
    final id = StringUtils.substringBefore(
        StringUtils.substringAfter(link.data, '/embed-4/'), '?');

    final uri = Uri.parse(link.data);
    print("${uri.scheme}://${uri.host}$sourcePath$id");
    final response = await client
        .newCall(
          GET(
            "${uri.scheme}://${uri.host}$sourcePath$id",
            headers: Headers.fromMap({"x-requested-with": "XMLHttpRequest"}),
          ),
        )
        .execute();

    print(response.body.string);

    final json = response.body.json() as Map;

    final List<VideoSource> sources;

    if (json['encrypted'] == false) {
      sources =
          ListUtils.mapList((json['sources'] as List), (e) => toVideoSource(e));
    } else {
      final indexPairs = await generateIndexPairs();

      final decrypted =
          tryDecrypting(indexPairs, StringUtils.valueToString(json['sources']));

      sources = ListUtils.mapList(
          (jsonDecode(decrypted) as List), (e) => toVideoSource(e));
    }
    final List<Subtitle>? tracks;

    if (json['tracks'] == null) {
      tracks = null;
    } else {
      tracks = ListUtils.mapList((json['tracks'] as List), (e) {
        return toSubtitle(e);
      });

      tracks.removeWhere((element) => element.language == 'thumbnails');
    }

    return Video(
      sources: sources,
      subtitles: tracks,
    );
  }

  VideoSource toVideoSource(dynamic e) {
    return VideoSource.hls(url: e['file']);
  }

  Subtitle toSubtitle(dynamic e) {
    return Subtitle(
      url: e['file'],
      language: e['label'] ?? 'thumbnails',
      format: AppUtils.getSubtitleFormatFromUrl(e['file']),
    );
  }

  String tryDecrypting(List<List<int>> indexPairs, String ciphered,
      [int attempts = 0]) {
    if (attempts > 2) {
      throw Exception("PLEASE NUKE DOPEBOX AND SFLIX");
    }
    final data = cipherTextCleaner(indexPairs, ciphered);
    try {
      return CryptoDart.enc.Utf8
          .stringify(CryptoDart.AES.decrypt(data[0], data[1]));
    } catch (_) {
      return tryDecrypting(indexPairs, ciphered, attempts + 1);
    }
  }

  Future<List<List<int>>> generateIndexPairs() async {
    final script = (await client.newCall(GET(scriptUrl)).execute()).body.string;
    final list = StringUtils.substringBeforeLast(
            StringUtils.substringBefore(
                StringUtils.substringAfter(script, "const "), '()'),
            ',')
        .split(',');

    final indexes = ListUtils.mapList(list, (e) {
      final value = StringUtils.substringAfter(e, '=');
      if (value.contains('0x')) {
        return int.parse(StringUtils.substringAfter(value, '0x'), radix: 16);
      } else {
        return int.parse(value);
      }
    }).sublist(1);

    return ListUtils.mapList(
        chunked(indexes, 2), (e) => (e as List<int>).reversed.toList());
  }

  List<String> cipherTextCleaner(List<List<int>> indexPairs, String data) {
    var password = '';
    String ciphertext = data;
    int index = 0;
    for (List<int> item in indexPairs) {
      int start = item.first + index;
      int end = start + item.last;
      String passSubstr = data.substring(start, end);
      password += passSubstr;
      ciphertext = ciphertext.replaceFirst(passSubstr, "");
      index += item.last;
    }

    return [ciphertext, password];
  }

  List<List<int>> chunked(List<int> list, int size) {
    List<List<int>> chunks = [];
    for (int i = 0; i < list.length; i += size) {
      int end = list.length;
      if (i + size < list.length) {
        end = i + size;
      }
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
}
