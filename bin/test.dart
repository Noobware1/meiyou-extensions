import 'dart:io';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';

void main(List<String> args) {
  final compiled = ExtenstionComplier().compilePackages({
    'meiyou': {
      'main.dart': '''
import 'gogo_cdn.dart';

main() {
  return GogoCDN(ExtractorLink(
      url:
          'https://goone.pro/streaming.php?id=MjE1NTk1&title=Kibou+no+Chikara%3A+Otona+Precure+%2723+Episode+7',
      name: ''));
}

''',
      'gogo_cdn.dart': File(
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

