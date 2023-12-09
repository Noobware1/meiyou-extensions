// ignore_for_file: unnecessary_this

import 'dart:convert';
import 'package:meiyou_extenstions/meiyou_extenstions.dart';



class GogoCDN extends ExtractorApi {
  GogoCDN(ExtractorLink extractorLink) : super(extractorLink);

  @override
  String get name => 'GogoCDN';

  @override
  Future<Video> extract() async {
    final doc =
        (await AppUtils.httpRequest(url: this.extractorLink.url, method: 'GET'))
            .document;

    final script =
        doc.selectFirst('script[data-name="episode"]').attr('data-value');
    final id = doc.selectFirst('#id').attr('value');

    final host = Uri.parse(this.extractorLink.url).host;

    final encryptedID = cryptoHandler(keysAndIV.key, keysAndIV.iv, id, true);

    final decryptedID =
        cryptoHandler(keysAndIV.key, keysAndIV.iv, script, false)
            .replaceFirst(id, encryptedID);

    final encryptedData = json.decode((await AppUtils.httpRequest(
            url: 'https://$host/encrypt-ajax.php?id=$decryptedID&alias=$id',
            method: 'GET',
            headers: {'x-requested-with': 'XMLHttpRequest'}))
        .text)['data'] as String;

    final decrypted = json.decode(
        cryptoHandler(keysAndIV.secondKey, keysAndIV.iv, encryptedData, false));

    final List<VideoSource> list = [];
    for (var e in decrypted['source'] as List) {
      list.add(toVideoSource(e, false));
    }

    if (decrypted['source_bk'] != null) {
      for (var e in decrypted['source_bk'] as List) {
        list.add(toVideoSource(e, true));
      }
    }

    return Video(videoSources: list, headers: {'referer': 'https://$host'});
  }

  VideoSource toVideoSource(dynamic j, bool backup) {
    final fileLabel = StringUtils.valueToString(j['label']).toLowerCase();

    final url = j['file'];

    if (isHLS(fileLabel)) {
      return VideoSource(
        url: url,
        quality: VideoQuality.hlsMaster,
        format: VideoFormat.hls,
        isBackup: backup,
      );
    } else {
      return VideoSource(
        url: url,
        quality: VideoQuality.getFromString(fileLabel),
        format: VideoFormat.other,
        isBackup: backup,
      );
    }
  }

  bool isHLS(dynamic filelabel) {
    if (filelabel == 'hls p') {
      return true;
    } else if (filelabel == 'auto p') {
      return true;
    } else {
      return false;
    }
  }

  static const keysAndIV = Keys('37911490979715163134003223491201',
      '54674138327930866480207815084989', '3134003223491201');

  String cryptoHandler(String key, String iv, String text, bool encrypt) {
    if (encrypt) {
      return CryptoUtils.AES(
          ciphertext: text,
          key: key,
          encrypt: encrypt,
          options: CryptoOptions(
            iv: iv,
            ivEncoding: 'utf8',
            keyEncoding: 'utf8',
            textEncoding: 'utf8',
            encoding: 'base64',
          ));
    } else {
      return CryptoUtils.AES(
          ciphertext: text,
          key: key,
          encrypt: encrypt,
          options: CryptoOptions(
            iv: iv,
            ivEncoding: 'utf8',
            keyEncoding: 'utf8',
            textEncoding: 'base64',
          ));
    }
  }
}

class Keys {
  final String key;
  final String secondKey;
  final String iv;

  const Keys(this.key, this.secondKey, this.iv);
}
