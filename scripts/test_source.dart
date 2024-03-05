import 'dart:io';

import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/preference.dart';

import '../package_reader/helpers.dart';
import '../package_reader/package_reader.dart';
import 'utils.dart';

void main(List<String> args) async {
  final prefsDir = (Directory.current.path + Platform.pathSeparator + 'prefs')
      .toDirectory()
    ..createSync();
  SharedPreferences.initialize(prefsDir.path);

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

  final source = ExtensionLoader.ofProgram(results.program).loadCatalogueSource(
      'package:${results.info.pkgName}/main.dart',
      NetworkHelper(MockNetworkPrefrences()));

  // print(await source.getSearch(1, 'astra', FilterList([])));

  print(await source.getMediaDetails(
    SearchResponse(
        title: "ASTRA LOST IN SPACE",
        url: """{"id":"GMEHMEWZM","type":"series"}""",
        poster:
            "https://www.crunchyroll.com/imgsrv/display/thumbnail/960x1440/catalog/crunchyroll/e1e7a80baf33f97172a732732cb9caaf.jpe",
        type: ShowType.Anime,
        description:
            """Eight high school students and a kid are flown out to Planet Camp, tasked with surviving on their own for a few days. But shortly after arriving, an ominous glowing orb warps them to an unknown quadrant of space, nearly 5,012 light years away.
null
Language: Sub Dubnull
Maturity Ratings: TV-14
null
Audio: en-US , ja-JP
null
Subs: en-US , fr-FR , es-419 , pt-BR , ar-SA""",
        generes: ["Sci-Fi"],
        rating: null,
        current: 12,
        total: null),
  ));
}
