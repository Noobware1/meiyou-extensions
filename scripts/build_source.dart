import 'dart:io';

import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';

import '../package_reader/helpers.dart';
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
  final source =
      ExtensionLoader.ofProgram(ExtensionComplier().compile(results.packages))
          .loadSource('package:${info.pkgName}/main.dart', 'getSource',
              NetworkHelper(MockNetworkPrefrences())) as HttpSource;

  print(source.getSearch(1, 'one piece', FilterList([])));
}
