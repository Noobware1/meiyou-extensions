import 'dart:io';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';

import 'build.dart';

// void main(List<String> args) {
//   final a = File(
//           'C:/Users/freem/OneDrive/Desktop/Projects/meiyou_extensions_repo/src/video/aniwatch/aniwatch.dart')
//       .readAsStringSync();
//   final packages = {
//     'meiyou': {
//       'main.dart': fixImports(a),
//       ...getAllRelativeImports(
//           'C:/Users/freem/OneDrive/Desktop/Projects/meiyou_extensions_repo/src/video/aniwatch',
//           a, {}),
//       ...getAllExtractors(a, {})
//     }
//   };

//   final compiled = ExtenstionComplier().compilePackages(packages);

//   final api = ExtenstionLoader()
//       .runtimeEval(compiled)
//       .executeLib('package:meiyou/main.dart', 'main') as $BasePluginApi;

//   print(api);
// }

void main(List<String> args) async {
  final a = File(
          "C:/Users/freem/OneDrive/Desktop/Projects/meiyou_extensions_repo/bin/lol.dart")
      .readAsStringSync();
  final packages = {
    'meiyou': {'main.dart': fixImports(a), ...getAllExtractors(a, {})}
  };

  final compiled = ExtenstionComplier().compilePackages(packages);

  final extractorApi = ExtenstionLoader()
      .runtimeEval(compiled)
      .executeLib('package:meiyou/main.dart', 'main');

  print(await extractorApi);
  // print(extractorApi.extract().then(print));
}
