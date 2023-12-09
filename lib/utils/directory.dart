import 'dart:io';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';

Directory getExtractorsDirectory() => Directory(
    '${Directory.current.path.substringBefore('meiyou_extensions_repo')}meiyou_extensions_repo\\lib\\extractors');
