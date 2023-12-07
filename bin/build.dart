import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

import 'update_index.json.dart';

void main(List<String> args) {
  final folder = Directory(args[0]);

  final filePaths = [
    'plugin.json',
    'code.evc',
    'icon.png',
  ];

  print('Creating plugin.json.... ');
  final plugin =
      Plugin.decode(File('${folder.path}/build.info.json').readAsStringSync());

  File(filePaths[0]).writeAsStringSync(plugin.encode);

  print('Compiling code.... ');

  final code = ExtenstionComplier().compilePackages({
    'meiyou': {
      'main.dart':
          File('${folder.path}/${folder.path.substringAfterLast('\\')}.dart')
              .readAsStringSync(),
    }
  });

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
