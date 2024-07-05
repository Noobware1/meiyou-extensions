// ignore_for_file: unnecessary_this, unnecessary_cast

import 'dart:convert';

import 'package:crypto_dart/crypto_dart.dart';
import 'package:html/dom.dart';
import 'package:meiyou_extensions_lib/html_extensions.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/response.dart';

class GogoCDNExtractor {
  GogoCDNExtractor(this.client);

  final OkHttpClient client;

  Future<Video> extract(MediaLink link) async {
    final Document document = await this
        .client
        .newCall(GET(link.data))
        .execute()
        .then((response) => (response as Response).body.document);

    final iv = StringUtils.substringAfter(
        document.selectFirst("div.wrapper")!.className, ' container-');
    final secretKey = StringUtils.substringAfter(
        document.selectFirst("body[class]")!.className, 'container-');
    final decryptionKey = StringUtils.substringAfter(
        document.selectFirst("div.videocontent")!.className, 'videocontent-');

    final decryptedAjaxParams = cryptoHandler(
      document.selectFirst("script[data-value]")!.attr("data-value")!,
      iv,
      secretKey,
      false,
    );

    final httpUrl = Uri.parse(link.data);
    final host = "https://${httpUrl.host}";

    final id = httpUrl.queryParameters["id"]!;

    final encryptedId = cryptoHandler(id, iv, secretKey, true);
    final headers =
        Headers.Builder().add("X-Requested-With", "XMLHttpRequest").build();

    final String encryptedData = await this
        .client
        .newCall(
          GET(
            "$host/encrypt-ajax.php?id=$encryptedId&$decryptedAjaxParams&alias=$id",
            headers: headers,
          ),
        )
        .execute()
        .then((res) => (res.body as ResponseBody).json((json) => json['data']));

    final decrypted =
        json.decode(cryptoHandler(encryptedData, iv, decryptionKey, false));

    final List<VideoSource> list = [];
    for (var e in (decrypted['source'] as List)) {
      list.add(toVideoSource(e, false));
    }

    if (decrypted['source_bk'] != null && decrypted['source_bk'] is List) {
      for (var e in (decrypted['source_bk'] as List)) {
        list.add(toVideoSource(e, true));
      }
    }
    return Video(
        sources: list, headers: Headers.fromMap({'Referer': 'https://$host'}));
  }

  String cryptoHandler(String text, String iv, String secretKey, encrypt) {
    final textEncoding = (encrypt) ? 'utf8' : 'base64';

    final options = CipherOptions(
      iv: iv,
      keyEncoding: 'utf8',
      ivEncoding: 'utf8',
      textEncoding: textEncoding,
    );

    if (encrypt) {
      return CryptoDart.AES
          .encrypt(text, secretKey, options: options)
          .toString();
    }
    return CryptoDart.enc.Utf8
        .stringify(CryptoDart.AES.decrypt(text, secretKey, options: options));
  }

  VideoSource toVideoSource(dynamic j, bool backup) {
    print(j);
    final fileLabel = StringUtils.valueToString(j['label']).toLowerCase();

    final url = j['file'];
    if (fileLabel == 'hls p' || fileLabel == 'auto p') {
      return VideoSource.hls(
        url: url,
        isBackup: backup,
      );
    } else {
      return VideoSource(
        url: url,
        quality: Quality.getFromString(fileLabel),
        format: VideoFormat.mp4,
        isBackup: backup,
      );
    }
  }
}
