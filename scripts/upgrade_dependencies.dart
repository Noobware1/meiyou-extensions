import 'dart:io';

import 'package:meiyou_extensions_lib/utils.dart';
import 'package:path/path.dart' as p;
import 'utils.dart';

void main(List<String> args) async {
  print('Upgrading dependencies...');
  final repo = getRepoPath().toDirectory();
  Directory.current = repo;
  _runUpgradeCommand();

  final folderNames = [
    'novel',
    'manga',
    'video',
  ];

  for (var name in folderNames) {
    final mainFolder = Directory(p.join(repo.path, 'src', name));

    for (var langFolder in mainFolder.listSync().whereType<Directory>()) {
      for (var folder in langFolder.listSync().whereType<Directory>()) {
        final pubspec = runCatching(() => folder
                .listSync()
                .firstWhere((file) => file.path.endsWith('pubspec.yaml')))
            .getOrNull();
        if (pubspec != null) {
          print(
              'Upgrading dependencies for $name/${langFolder.name}/${folder.name}');
          Directory.current = folder;
          _runUpgradeCommand();
        }
      }
    }
  }

  print('Dependencies upgraded.');
}

void _runUpgradeCommand() {
  final result = Process.runSync('dart', ['pub', 'upgrade']);
  print(result.stdout);
}
