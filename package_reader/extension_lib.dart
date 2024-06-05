// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:meiyou_extensions_lib/utils.dart';

import '../scripts/utils.dart';
import 'package:path/path.dart' as p;

Map<String, String> getAllExtensionLibFiles() {
  final lib = Directory(p.join(getRepoPath(), 'lib'));
  final libraries = <String, String>{};

  for (var entity in lib.listSync(recursive: true).whereType<File>()) {
    final path = () {
      final split = p.split(entity.path);
      final index = split.lastIndexOf('meiyou-extensions');
      return split.sublist(index + 2).join('/');
    }();
    libraries[path] = entity.readAsStringSync();
  }
  return libraries;
}
