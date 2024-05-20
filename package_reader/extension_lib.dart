// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:meiyou_extensions_lib/utils.dart';

import '../scripts/utils.dart';

Map<String, String> getAllExtensionLibFiles() {
  final lib = '${getRepoPath()}/lib'.toDirectory();
  final libraries = <String, String>{};

  for (var entity in lib.listSync(recursive: true).whereType<File>()) {
    final path = StringUtils.substringAfter(
            entity.path, lib.path + Platform.pathSeparator)
        .split(Platform.pathSeparator)
        .join('/');
    libraries[path] = entity.readAsStringSync();
  }
  return libraries;
}
