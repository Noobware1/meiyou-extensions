// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import '../package_reader/package_reader.dart';
import 'utils.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final name = args[0];
  final mainPath = () {
    final split = p.split(Directory.current.path);
    final index = split.lastIndexOf('scripts');
    return p.joinAll(split.sublist(0, index));
  }();

  final mainDir = Directory(p.join(mainPath, 'src', name));

  final repoFolderPath = Directory(p.join(mainPath, 'repo', name))
    ..createSync(recursive: true);

  final iconDir = Directory(p.join(repoFolderPath.path, 'icon'))..createSync();

  final pluginDir = Directory(p.join(repoFolderPath.path, 'plugin'))
    ..createSync();

  final List<AvailableExtension> extensions = [];

  for (var languageDir in mainDir.listSync().whereType<Directory>()) {
    _readLanguageFolder(
      extensions,
      languageDir,
      iconDir,
      pluginDir,
    );
  }

  File(p.join(repoFolderPath.path, 'index.json'))
      .writeAsStringSync(extensions.toJsonEncode(true));
  File(p.join(repoFolderPath.path, 'index.min.json'))
      .writeAsStringSync(extensions.toJsonEncode());
}

void _readLanguageFolder(
  List<AvailableExtension> list,
  Directory directory,
  Directory iconDirectory,
  Directory pluginDirectory,
) {
  print('Current language folder: ${directory.name}');
  for (var dir in directory.listSync().whereType<Directory>()) {
    try {
      final readResults = PackageReader(dir).read();
      list.add(readResults.info);

      print('Copying icon for source: ${dir.name}');
      File(p.join(iconDirectory.path, readResults.info.iconUrl))
          .writeAsBytesSync(readResults.iconBytes);

      print('Creating plugin for source: ${dir.name}');

      final Plugin plugin = Plugin(
        code: readResults.program.write(),
        icon: readResults.iconBytes,
        metadata: PluginMetaData(
          name: readResults.info.name,
          pkgName: readResults.info.pkgName,
          versionName: readResults.info.versionName,
          lang: readResults.info.lang,
          isNsfw: readResults.info.isNsfw,
          isOnline: readResults.sources.any((source) => source is HttpSource),
        ),
      );

      File(p.join(pluginDirectory.path, readResults.info.pluginName))
          .writeAsBytesSync(plugin.encode());

      print('Successfully created entry for source: ${dir.name}');
    } catch (e, s) {
      print('Error while creating entry for: ${dir.name}');
      print('Error: $e');
      print('Stacktrace: $s');
    }
  }
}

JsonEncoder prettyEncoder() {
  return JsonEncoder.withIndent('  ');
}

extension on List<AvailableExtension> {
  String toJsonEncode([bool pretty = false]) {
    final list = map((e) => e.toJsonWithoutRepoUrl()).toList()
      ..sort((a, b) => a['pkg'].toString().compareTo(b['pkg'].toString()));
    if (pretty) {
      return prettyEncoder().convert(list);
    }
    return jsonEncode(list);
  }
}

extension on AvailableExtension {
  String prettyEncode() => prettyEncoder().convert(toJsonWithoutRepoUrl());

  Map<String, dynamic> toJsonWithoutRepoUrl() {
    return toJson()..remove('repoUrl');
  }
}
