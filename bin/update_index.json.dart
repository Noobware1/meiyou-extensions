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
    case 'anime':
      index.anime.removeWhere((e) => e.id == plugin.id);
      index.anime.add(plugin);
      break;
    case 'manga':
      index.manga.removeWhere((e) => e.id == plugin.id);
      index.manga.add(plugin);
      break;
    case 'movies':
      index.movies.removeWhere((e) => e.id == plugin.id);
      index.movies.add(plugin);
      break;
  }
  final file = File('index.json');
  await file.writeAsString(index.encode);
  return file;
}

class IndexJson {
  final List<Plugin> anime;

  final List<Plugin> movies;
  final List<Plugin> manga;

  IndexJson({required this.anime, required this.movies, required this.manga});

  factory IndexJson.decode(String json) => IndexJson.fromJson(jsonDecode(json));

  String get encode => JsonEncoder.withIndent('    ').convert(toJson());

  factory IndexJson.fromJson(dynamic json) {
    final anime = json['anime'] as List? ?? [];

    final movies = json['movies'] as List? ?? [];

    final manga = json['manga'] as List? ?? [];

    return IndexJson(
      anime: anime.mapAsList((it) => Plugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
      movies: movies.mapAsList((it) => Plugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
      manga: manga.mapAsList((it) => Plugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anime': anime.mapAsList((it) => it.toJson()),
      'movies': movies.mapAsList((it) => it.toJson()),
      'manga': manga.mapAsList((it) => it.toJson()),
    };
  }
}
