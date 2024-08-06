import 'dart:convert';

import 'package:html/dom.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/response.dart';

class Turkish123Extractor {
  final OkHttpClient client;

  Turkish123Extractor(this.client);

  Future<Video?> extract(MediaLink link) async {
    final name = link.name;

    final response = await client
        .newCall(
          GET(
            link.url,
            headers: link.headers!
                .newBuilder()
                .add('Referer', link.referer!)
                .build(),
          ),
        )
        .execute();

    print(response.body.string);

    if (name == 'Engifuosi') {
      return extractEngifuosi(response);
    } else if (name == 'Tukipasti') {
      return extractTukipasti(response);
    }
  }

  Video extractTukipasti(Response response) {
    final playUrl = RegExp(r"var urlPlay = '(.*?)'")
        .firstMatch(response.body.string)!
        .group(1)!;

    return Video(
      sources: [VideoSource.hls(url: playUrl)],
    );
  }

  Video extractEngifuosi(Response response) {
    final packedRegex = RegExp(r'eval\(function\(p,a,c,k,e,.*\)\)');

    final unpacked = AppUtils.unpackJS(
        packedRegex.firstMatch(response.body.string)!.group(0)!);

    final file =
        RegExp(r'file\s*:\s*"([^"]+)').firstMatch(unpacked!)!.group(1)!;

    return Video(
      sources: [VideoSource.hls(url: file)],
    );
  }
}
