import 'dart:io';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';

void main(List<String> args) {
  final filePath = args[0];

  final compiled = ExtenstionComplier().compilePackages({
    'meiyou': {'main.dart': File(filePath).readAsStringSync()}
  });

  final plugin = ExtenstionLoader()
      .runtimeEval(compiled)
      .executeLib('package:meiyou/main.dart', 'main') as $BasePluginApi;

  print(plugin);
}
