import 'dart:convert';
import 'dart:io';
import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import '../package_reader/package_reader.dart';
import 'create_repo.dart';
import 'utils.dart';
import 'dart:mirrors';

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

  // final search = await runAsyncCatching(
  //         () => source.getSearchPage(1, 'one piece', FilterList([])))
  //     .then((value) => value.getOrNull()?.json());
  // print(search);

  // try {
  //   print(await source.getInfoPage(ContentItem.fromJson(jsonDecode('''
  // '''))));
  // } catch (e, s) {
  //   print(e);
  //   print(s);
  // }

  try {
    print(await source.getContentDataLinks(
        '/jaku-chara-tomozaki-kun-2nd-stage-dub-episode-9'));
  } catch (e, s) {
    print(e);
    print(s);
  }

  // for (var request in source.homePageRequests().skip(1)) {
  //   try {
  //     print((await source.getHomePage(1, request)));
  //   } catch (e, s) {
  //     print(e);
  //     print(s);
  //   }
  //   break;
  // }
  print('done');

  prefsDir.deleteSync();
}
