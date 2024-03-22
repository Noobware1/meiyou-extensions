import 'dart:io';

import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/preference.dart';

import '../package_reader/helpers.dart';
import '../package_reader/package_reader.dart';
import 'utils.dart';

void main(List<String> args) async {
  // ignore: prefer_interpolation_to_compose_strings
  final prefsDir = (Directory.current.path + Platform.pathSeparator + 'prefs')
      .toDirectory()
    ..createSync();

  ExtensionlibOverrides.sharedPreferencesDir = prefsDir.path;

  var path = args[0].toLowerCase().replaceAll('/', Platform.pathSeparator);
  final segs = args[0].split('/');
  if (segs.length < 3) {
    throw Exception(
        'The path must be in format <type[video|text|image]>/<language[multi|en|etc]>/<name> but got $path');
  }

  final results =
      PackageReader(getSourceFolderPath() + Platform.pathSeparator + path)
          .read();

  // final info = results.info;

  final source = ExtensionLoader.ofProgram(results.program)
      .loadCatalogueSource(results.info.pkgName);

  // print(await source.getHomePage(1, source.homePageRequests().first));
  print(await source.getSearchPage(1, 'one piece', FilterList([])));

  // print(await source.getInfoPage());
}
