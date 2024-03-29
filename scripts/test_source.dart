import 'dart:io';
import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/network.dart';
import '../package_reader/package_reader.dart';
import 'utils.dart';

void main(List<String> args) async {
  // ignore: prefer_interpolation_to_compose_strings
  final prefsDir = (Directory.current.path + Platform.pathSeparator + 'prefs')
      .toDirectory()
    ..createSync();

  ExtensionlibOverrides.networkHelper = NetworkHelper(Prefs());
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

  final source = ExtensionLoader.ofProgram(results.program)
      .loadCatalogueSource(results.info.pkgName);

  for (var request in source.homePageRequests()) {
    try {
      print(await source.getHomePage(1, request));
    } catch (e, s) {
      print(e);
      print(s);
    }
    break;
  }
  print('done');

  prefsDir.deleteSync();
}
