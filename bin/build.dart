import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

import 'dart:convert';

import 'package:meiyou_extenstions/ok_http/ok_http.dart';

extension on Directory {
  String get fixedPath =>
      path.contains('\\') ? path.replaceAll('\\', '/') : path;
}

void main(List<String> args) {
  print(Directory.current);
  final sourceFolder =
      '${Directory.current.fixedPath.substringBefore('bin')}/src';
  print(Directory(sourceFolder).existsSync());
  final directories = [
    Directory('$sourceFolder/video'),
    Directory('$sourceFolder/image'),
    Directory('$sourceFolder/text'),
  ];

  final buildDir = getBuildsDirectory()..createSync();

  for (var folders in directories) {
    for (var subfolders in folders.listSync().whereType<Directory>()) {
      build(buildDir, subfolders);
    }
  }
}

build(Directory builds, Directory folder) {
  final filePaths = [
    'plugin.json',
    'code.evc',
    'icon.png',
  ];

  print('Creating plugin.json.... ');
  final plugin =
      Plugin.decode(File('${folder.fixedPath}/info.json').readAsStringSync());

  File(filePaths[0]).writeAsStringSync(plugin.encode);

  print('Compiling code.... ');

  final mainCode = File(
          '${folder.fixedPath}/${folder.fixedPath.substringAfterLast('/')}.dart')
      .readAsStringSync();
  final packages = {
    'meiyou': {'main.dart': fixImports(mainCode), ...getAllExtractors(mainCode)}
  };

  final code = ExtenstionComplier().compilePackages(packages);

  print('Creating code.evc.... ');
  File(filePaths[1]).writeAsBytesSync(code);

  print('Creating icon.png.... ');

  List<ArchiveFile> archiveFiles = [];

  File(filePaths[2])
      .writeAsBytesSync(File('${folder.fixedPath}/icon.png').readAsBytesSync());

  print('Building...');
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

  print('Creating updated index.json....');
  updateIndexJson(plugin).then((value) {
    print('Successfully updated index.json');
  });
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

Map<String, String> getAllExtractors(String code) {
  final extractors = RegExp(r"..extractors\/(.*)';")
      .allMatches(code)
      .map((it) => it.group(1))
      .nonNulls;

  final extractorsDir = getExtractorsDirectory();

  final allImports = <String, String>{};
  for (var e in extractors) {
    allImports[e] = File('${extractorsDir.fixedPath}/$e').readAsStringSync();
  }
  return allImports;
}

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
      "${Directory.current.fixedPath.substringBefore("bin")}builds/index.json");
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
