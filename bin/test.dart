import 'dart:io';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';

void main(List<String> args) {
  final compiled = ExtenstionComplier().compilePackages({
    'meiyou': {
      'main.dart': File(
              'C:/Users/freem/OneDrive/Desktop/Projects/meiyou_extensions_repo/lib/extractors/gogo_cdn.dart')
          .readAsStringSync()
    }
  });

  final extractorApi = ExtenstionLoader()
      .runtimeEval(compiled)
      .executeLib('package:meiyou/main.dart', 'main') as $ExtractorApi;

  print(extractorApi);
  print(extractorApi.extract().then(print));
}
