// ignore_for_file: unnecessary_this

import 'mega_cloud.dart';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

class RabbitStream extends MegaCloud {
  RabbitStream(ExtractorLink extractorLink) : super(extractorLink);

  @override
  String getUrl() {
    final serverUrl = this.extractorLink.url;
    final embed = RegExp(r'embed-\d').firstMatch(serverUrl)?.group(0);
    final id = StringUtils.substringBefore(
        StringUtils.substringAfterLast(serverUrl, "/"), "?");

    return '$hostUrl/ajax/$embed/getSources?id=$id';
  }

  @override
  String get keyUrl =>
      'https://raw.githubusercontent.com/Noobware1/zoro-keys/e4/key';
}
