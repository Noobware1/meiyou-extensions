import 'dart:convert';
import 'dart:io';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';
import 'package:meiyou_extenstions/ok_http/ok_http.dart';

Future<File> updateIndexJson(Plugin plugin) async {
  final client = OKHttpClient();
  final indexUrl =
      "https://raw.githubusercontent.com/Noobware1/meiyou_extensions_repo/builds/index.json";

  final index = (await client.get(indexUrl)).json(IndexJson.fromJson);
  switch (plugin.type.toLowerCase()) {
    case 'video':
      index.video.removeWhere((e) => e.id == plugin.id);
      index.video.add(plugin);
      break;
    case 'image':
      index.image.removeWhere((e) => e.id == plugin.id);
      index.image.add(plugin);
      break;
    case 'text':
      index.text.removeWhere((e) => e.id == plugin.id);
      index.text.add(plugin);
      break;
  }
  final file = File(
      "${Directory.current.path.substringBefore("meiyou_extensions_repo")}meiyou_extensions_repo\\builds\\index.json");
  await file.writeAsString(index.encode);
  return file;
}

class IndexJson {
  final List<Plugin> video;

  final List<Plugin> image;
  final List<Plugin> text;

  IndexJson({required this.video, required this.image, required this.text});

  factory IndexJson.decode(String json) => IndexJson.fromJson(jsonDecode(json));

  String get encode => JsonEncoder.withIndent('    ').convert(toJson());

  factory IndexJson.fromJson(dynamic json) {
    final video = json['video'] as List? ?? [];

    final image = json['image'] as List? ?? [];

    final text = json['text'] as List? ?? [];

    return IndexJson(
      video: video.mapAsList((it) => Plugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
      image: image.mapAsList((it) => Plugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
      text: text.mapAsList((it) => Plugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video': video.mapAsList((it) => it.toJson()),
      'image': image.mapAsList((it) => it.toJson()),
      'text': text.mapAsList((it) => it.toJson()),
    };
  }
}
