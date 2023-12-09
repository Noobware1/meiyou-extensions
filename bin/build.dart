import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:meiyou_extensions_repo/utils/directory.dart';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';
import 'update_index.json.dart';

void main(List<String> args) {
  final sourceFolder =
      '${Directory.current.path.substringBefore('meiyou_extensions_repo')}meiyou_extensions_repo\\src';

  final directories = [
    Directory('$sourceFolder\\video'),
    Directory('$sourceFolder\\image'),
    Directory('$sourceFolder\\text'),
  ];

  for (var folders in directories) {
    for (var subfolders in folders.listSync().whereType<Directory>()) {
      build(subfolders);
    }
  }
}

build(Directory folder) {
  final filePaths = [
    'plugin.json',
    'code.evc',
    'icon.png',
  ];

  print('Creating plugin.json.... ');
  final plugin =
      Plugin.decode(File('${folder.path}/info.json').readAsStringSync());

  File(filePaths[0]).writeAsStringSync(plugin.encode);

  print('Compiling code.... ');

  final mainCode =
      File('${folder.path}/${folder.path.substringAfterLast('\\')}.dart')
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
      .writeAsBytesSync(File('${folder.path}/icon.png').readAsBytesSync());

  print('Building...');
  for (String filePath in filePaths) {
    File file = File(filePath);
    List<int> fileContent = file.readAsBytesSync();
    archiveFiles.add(ArchiveFile(filePath, fileContent.length, fileContent));

    file.deleteSync();
  }

  final outputFile = "${folder.path.substringAfterLast('\\')}.plugin";
  // Create the archive and write it to a file
  Archive archive = Archive()..files.addAll(archiveFiles);
  File outputZipFile = File(outputFile);
  outputZipFile.writeAsBytesSync(ZipEncoder().encode(archive)!);

  print('Successfully built $outputFile');

  print('Creating updated index.json....');
  updateIndexJson(plugin).then((value) {
    print('Successfully updated index.json');
  });
}

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
    allImports[e] = File('${extractorsDir.path}\\$e').readAsStringSync();
  }
  return allImports;
}
