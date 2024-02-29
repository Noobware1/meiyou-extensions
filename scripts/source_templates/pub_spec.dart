part of '../make_source.dart';

String pubSpecTemplate(String sourceName, String lang) {
  return '''
name: ${sourceName.toLowerCase()}
sourceName: $sourceName
description: No description
lang: $lang
version: 1.0.0
nsfw: 0
publish_to: none

environment:
  sdk: ^3.2.6

dependencies:
  meiyou_extensions:
    path: ../../../../
  okhttp:
    git:
      url: https://github.com/Noobware1/okhttp.git
      ref: master
  crypto_dart:
    git:
      url: https://github.com/Noobware1/crypto_dart.git
      ref: master
  meiyou_extensions_lib:
    git:
      url: https://github.com/Noobware1/meiyou_extensions_lib.git
      ref: models
  html: ^0.15.4

dev_dependencies:
  lints: ^2.1.0

''';
}
