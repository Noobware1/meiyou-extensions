import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:meiyou_extensions_lib/extenstions.dart';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

import 'dart:convert';

extension on Directory {
  String get fixedPath =>
      path.contains('\\') ? path.replaceAll('\\', '/') : path;
}

void main(List<String> args) {
  final sourceFolder =
      '${Directory.current.fixedPath.substringBefore('bin')}src';

  final directories = [
    Directory('$sourceFolder/video'),
    Directory('$sourceFolder/manga'),
    Directory('$sourceFolder/novel'),
  ];

  final buildDir = getBuildsDirectory()..createSync();

  final icons = Directory('${buildDir.fixedPath}/icons')..createSync();
  final plugins = Directory('${buildDir.fixedPath}/plugins')..createSync();

  final IndexJson index = IndexJson(video: [], manga: [], novel: []);

  for (var folders in directories) {
    if (folders.existsSync()) {
      for (var subfolder in folders.listSync().whereType<Directory>()) {
        try {
          final plugin = build(plugins, icons, subfolder);
          switch (plugin.type.toLowerCase()) {
            case 'video':
              index.video.add(plugin);
              break;
            case 'manga':
              index.manga.add(plugin);
              break;
            case 'novel':
              index.novel.add(plugin);
              break;
            default:
          }
        } catch (e, s) {
          print(
              'Failed to build ${subfolder.fixedPath.substringAfterLast('/')}');
          print(e);
          print(s);
        }
      }
    }
  }

  final file = File("${buildDir.fixedPath}/index.json");
  file.writeAsStringSync(index.encode);
}

const filePaths = [
  'code.evc',
  'plugin.json',
  'icon.png',
];

OnlinePlugin build(Directory pluginsFolder, Directory icons, Directory folder) {
  final plugin = OnlinePlugin.decode(
      File('${folder.fixedPath}/info.json').readAsStringSync());
  final files = <String, Uint8List>{};
  print('Building ${plugin.name}...');

  final codeFileName = '${folder.fixedPath.substringAfterLast('/')}.dart';

  print('Compiling $codeFileName.... ');

  final mainCode = File('${folder.fixedPath}/$codeFileName').readAsStringSync();

  final packages = {
    'meiyou': {
      'main.dart': fixImports(mainCode),
      ...getAllRelativeImports(folder.fixedPath, mainCode, {}),
      ...getAllExtractors(mainCode, {})
    }
  };
  print('Compiling packages....');

  print('{\n  meiyou\n   --${packages['meiyou']!.keys.join('\n   --')}\n}');

  final code = ExtenstionComplier().compilePackages(packages);

  print('Creating code.evc.... ');
  files[filePaths[0]] = code;

  print('Copying icon.png.... ');
  final icon = File('${folder.fixedPath}/${filePaths[2]}');
  files[filePaths[2]] = icon.readAsBytesSync();

  icon.copySync(
      '${icons.fixedPath}/${folder.fixedPath.substringAfterLast('/')}.png');

  print('Creating plugin.json.... ');
  files[filePaths[1]] = Uint8List.fromList(utf8.encode(plugin.encode));

  List<ArchiveFile> archiveFiles = [];

  print('Building plugin...');
  for (var file in files.entries) {
    final fileContent = file.value;
    archiveFiles.add(ArchiveFile(file.key, fileContent.length, fileContent));
  }

  final outputFile = "${folder.fixedPath.substringAfterLast('/')}.plugin";
  // Create the archive and write it to a file
  Archive archive = Archive()..files.addAll(archiveFiles);
  File outputZipFile = File('${pluginsFolder.fixedPath}/$outputFile');
  outputZipFile.writeAsBytesSync(ZipEncoder().encode(archive)!);

  print('Successfully built $outputFile');

  return plugin;
}

Directory getExtractorsDirectory() => Directory(
    '${Directory.current.fixedPath.substringBefore('bin')}lib/extractors');

Directory getBuildsDirectory() =>
    Directory('${Directory.current.fixedPath.substringBefore('bin')}builds');

String fixImports(String code) {
  final importRegex = RegExp(
      r"""import\s+['"]([^'"]*extractors[^'"]*)['"](?:\s+as\s+([a-zA-Z_]\w*))?\s*;""");

  importRegex.allMatches(code).nonNulls.forEach((e) {
    final i = e.group(1)!;
    code = code.replaceFirst(i, i.substringAfterLast('/'));
  });
  return code;
}

Map<String, String> getAllRelativeImports(
  String folderPath,
  String code,
  Map<String, String> files,
) {
  Iterable<String> getImports(String codeFile) {
    final regex = RegExp(r"""import\s+['"](\w+\.\w+)['"]\s*;""");
    final imports =
        regex.allMatches(codeFile).map((it) => it.group(1)).nonNulls;
    return imports.where((e) => !e.startsWith('dart:'));
  }

  var allImports = getImports(code);
  for (var e in allImports) {
    final codeFile = File('$folderPath/$e').readAsStringSync();
    files[e] = codeFile;
  }
  return files;
}

Map<String, String> getAllExtractors(
    String code, Map<String, String> extractors) {
  Iterable<String> getExtractors(String codeFile) {
    final regex = RegExp(r"..extractors\/(.*)';");
    final extractors =
        regex.allMatches(codeFile).map((it) => it.group(1)).nonNulls;
    return extractors;
  }

  final extractorsDir = getExtractorsDirectory();

  var allImports = getExtractors(code);
  extractors = getAllRelativeImports(extractorsDir.fixedPath, code, extractors);

  for (var e in allImports) {
    final codeFile = File('${extractorsDir.fixedPath}/$e').readAsStringSync();
    extractors[e] = fixImports(codeFile);

    extractors =
        getAllRelativeImports(extractorsDir.fixedPath, codeFile, extractors);

    allImports = getExtractors(codeFile);
    if (allImports.isNotEmpty) {
      getAllExtractors(codeFile, extractors);
    }
  }
  return extractors;
}

class IndexJson {
  final List<OnlinePlugin> video;

  final List<OnlinePlugin> manga;
  final List<OnlinePlugin> novel;

  IndexJson({required this.video, required this.manga, required this.novel});

  factory IndexJson.decode(String json) => IndexJson.fromJson(jsonDecode(json));

  String get encode => JsonEncoder.withIndent('    ').convert(toJson());

  factory IndexJson.fromJson(dynamic json) {
    final video = json['video'] as List? ?? [];

    final manga = json['manga'] as List? ?? [];

    final novel = json['novel'] as List? ?? [];

    return IndexJson(
      video: video.mapAsList((it) => OnlinePlugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
      manga: manga.mapAsList((it) => OnlinePlugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
      novel: novel.mapAsList((it) => OnlinePlugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video': video.mapAsList((it) => it.toJson()),
      'manga': manga.mapAsList((it) => it.toJson()),
      'novel': novel.mapAsList((it) => it.toJson()),
    };
  }
}
