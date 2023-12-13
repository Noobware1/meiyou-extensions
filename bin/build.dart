import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:meiyou_extenstions/extenstions.dart';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

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
    Directory('$sourceFolder/image'),
    Directory('$sourceFolder/text'),
  ];

  final buildDir = getBuildsDirectory()..createSync();

  final icons = Directory('${buildDir.fixedPath}/icons')..createSync();

  final IndexJson index = IndexJson(video: [], image: [], text: []);

  for (var folders in directories) {
    if (folders.existsSync()) {
      for (var subfolder in folders.listSync().whereType<Directory>()) {
        try {
          final plugin = build(buildDir, icons, subfolder);
          switch (plugin.type.toLowerCase()) {
            case 'video':
              index.video.add(plugin);
              break;
            case 'image':
              index.image.add(plugin);
              break;
            case 'text':
              index.text.add(plugin);
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
  'plugin.json',
  'code.evc',
  'icon.png',
];

OnlinePlugin build(Directory builds, Directory icons, Directory folder) {
  final plugin = OnlinePlugin.decode(
      File('${folder.fixedPath}/info.json').readAsStringSync());
  print('Building ${plugin.name}...');

  print('Creating plugin.json.... ');

  File(filePaths[0]).writeAsStringSync(plugin.encode);
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

  File(filePaths[1]).writeAsBytesSync(code);

  print('Copying icon.png.... ');
  final icon = File('${folder.fixedPath}/icon.png');
  icon.copySync(filePaths[2]);

  icon.copySync(
      '${icons.fixedPath}/${folder.fixedPath.substringAfterLast('/')}.png');

  List<ArchiveFile> archiveFiles = [];

  print('Building plugin...');
  for (String filePath in filePaths) {
    File file = File(filePath);
    List<int> fileContent = file.readAsBytesSync();
    archiveFiles.add(ArchiveFile(filePath, fileContent.length, fileContent));

    file.deleteSync();
  }

  final outputFile = "${folder.fixedPath.substringAfterLast('/')}.plugin";
  // Create the archive and write it to a file
  Archive archive = Archive()..files.addAll(archiveFiles);
  File outputZipFile = File('${builds.fixedPath}/$outputFile');
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

  final List<OnlinePlugin> image;
  final List<OnlinePlugin> text;

  IndexJson({required this.video, required this.image, required this.text});

  factory IndexJson.decode(String json) => IndexJson.fromJson(jsonDecode(json));

  String get encode => JsonEncoder.withIndent('    ').convert(toJson());

  factory IndexJson.fromJson(dynamic json) {
    final video = json['video'] as List? ?? [];

    final image = json['image'] as List? ?? [];

    final text = json['text'] as List? ?? [];

    return IndexJson(
      video: video.mapAsList((it) => OnlinePlugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
      image: image.mapAsList((it) => OnlinePlugin.fromJson(
          (it as Map).map((key, value) => MapEntry(key.toString(), value)))),
      text: text.mapAsList((it) => OnlinePlugin.fromJson(
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
