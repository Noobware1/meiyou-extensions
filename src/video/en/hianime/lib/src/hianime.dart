// ignore_for_file: unnecessary_this, unnecessary_cast

import 'package:meiyou_extensions/extractors/mega_cloud.dart';
import 'package:meiyou_extensions/multisrc/video/zoro/zoro.dart';
import 'package:meiyou_extensions_lib/models.dart';

class HiAnime extends Zoro {
  HiAnime()
      : super(
            baseUrl: "https://hianime.to",
            lang: "en",
            name: "HiAnime",
            hosterNames: ["HD-1", "HD-2", "StreamTape"],
            ajaxRoute: '/v2');

  @override
  Future<Media?> getMedia(MediaLink link) async {
    if (link.name == "HD-1" || link.name == "HD-2") {
      return await MegaCloud(
        client: this.client,
        headers: this.headers,
        preferences: this.preferences,
      ).getVideoFromLink(link);
    } else {
      return null;
    }
  }
}
