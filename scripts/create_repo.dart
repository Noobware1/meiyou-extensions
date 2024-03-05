// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';
import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:archive/archive.dart';
import '../package_reader/helpers.dart';
import '../package_reader/package_reader.dart';
import 'utils.dart';

const _repoUrl = "https://github.com/Noobware1/meiyou-extensions/repo";
void main(List<String> args) async {
  final name = args[0];
  final mainPath =
      StringUtils.substringBeforeLast(Directory.current.path, 'scripts');

  final repoFolderPath = Directory(mainPath + Platform.pathSeparator + 'repo')
    ..createSync();

  final iconDir =
      Directory(repoFolderPath.path + Platform.pathSeparator + 'icon')
        ..createSync();

  final pluginDir =
      Directory(repoFolderPath.path + Platform.pathSeparator + 'plugin')
        ..createSync();

  final mainDir = Directory(
    StringUtils.substringBeforeLast(Directory.current.path, 'scripts') +
        'src' +
        Platform.pathSeparator +
        name,
  );

  final List<AvailableExtension> extensions = [];

  for (var languageDir in mainDir.listSync()) {
    if (languageDir is Directory) {
      readLanguageFolder(
        extensions,
        languageDir,
        iconDir,
        pluginDir,
      );
    } else {
      continue;
    }
  }

  File('${repoFolderPath.path}${Platform.pathSeparator}$name-index.json')
      .writeAsStringSync(extensions.toJsonEncode(true));
  File('${repoFolderPath.path}${Platform.pathSeparator}$name-index.min.json')
      .writeAsStringSync(extensions.toJsonEncode());
}

void readLanguageFolder(
  List<AvailableExtension> list,
  Directory directory,
  Directory iconDirectory,
  Directory pluginDirectory,
) {
  print('Current language folder: ${directory.name}');
  for (var entity in directory.listSync()) {
    if (entity is Directory) {
      try {
        final readResults = PackageReader(entity.path).read();
        list.add(readResults.info);

        print('Copying icon for source: ${entity.name}');
        File(iconDirectory.path +
                Platform.pathSeparator +
                readResults.info.iconUrl)
            .writeAsBytesSync(readResults.iconBytes);

        print('Creating plugin for source: ${entity.name}');

        final info = InstalledExtension(
          name: readResults.info.name,
          pkgName: readResults.info.pkgName,
          versionName: readResults.info.versionName,
          lang: readResults.info.lang,
          isNsfw: readResults.info.isNsfw,
          repoUrl: _repoUrl,
          isOnline: readResults.sources.any((source) => source is HttpSource),
          sources: readResults.sources.map((source) {
            return ExtensionSource(
              id: source.id,
              name: source.name,
              lang: source.lang,
              isUsedLast: false,
              supportsHomepage: source.supportsHomePage,
            );
          }).toList(),
          hasUpdate: false,
          icon: const [],
          evc: const [],
        );

        final evc = readResults.program.write();
        Archive plugin = Archive();
        plugin.addFile(ArchiveFile('code.evc', evc.length, evc));
        plugin.addFile(ArchiveFile(
            'icon.png', readResults.iconBytes.length, readResults.iconBytes));
        plugin.addFile(
            ArchiveFile.string('info.json', jsonEncode(info.toJson())));

        File(pluginDirectory.path +
                Platform.pathSeparator +
                readResults.info.pluginName)
            .writeAsBytesSync(ZipEncoder().encode(plugin)!);

        print('Successfully created entry for source: ${entity.name}');
      } catch (e, s) {
        print('Error while creating entry for: ${entity.name}');
        print('Error: $e');
        print('Stacktrace: $s');
      }
    } else {
      continue;
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
