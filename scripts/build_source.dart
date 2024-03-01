import 'dart:io';

import '../package_reader/package_reader.dart';
import 'utils.dart';

void main(List<String> args) async {
  var path = args[0].toLowerCase();
  final segs = args[0].split('/');
  if (segs.length < 3) {
    throw Exception(
        'The path must be in format <type[video|text|image]>/<language[multi|en|etc]>/<name> but got $path');
  }

  final results =
      PackageReader(getSourceFolderPath() + Platform.pathSeparator + path)
          .read();

  final info = results.info;

  print(info.toJson());
}
