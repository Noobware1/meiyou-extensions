// ignore_for_file: unnecessary_this, unnecessary_cast

import 'dart:async';

import 'package:html/dom.dart';
import 'package:meiyou_extensions/extractors/mega_cloud.dart';
import 'package:meiyou_extensions/multisrc/video/zoro/zoro.dart';
import 'package:meiyou_extensions_lib/models.dart';

class HiAnime extends Zoro {
  HiAnime()
      : super(
          id: 4844379015355361939,
          baseUrl: "https://hianime.to",
          lang: "en",
          name: "HiAnime",
          hosterNames: ["HD-1", "HD-2", "StreamTape"],
          ajaxRoute: '/v2',
        );

  @override
  Future<MediaAsset?> getMediaAsset(MediaLink link) async {
    if (link.name == "HD-1" || link.name == "HD-2") {
      return await MegaCloud(
        client: this.client,
        headers: this.headers,
        preferences: this.preferences,
      ).getVideoFromLink(link);
    }
    return null;
  }
}
