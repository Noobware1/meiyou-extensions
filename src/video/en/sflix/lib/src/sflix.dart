import 'package:meiyou_extensions/multisrc/video/dopeflix/dopeflix.dart';
import 'package:meiyou_extensions_lib/models.dart';

class Sflix extends Dopeflix {
  Sflix()
      : super(
          name: "SFlix",
          lang: "en",
          domainList: ["sflix.to", "sflix.se"],
          defaultDomain: "sflix.to",
        );

  @override
  int get id => 8615824918772726940;
}
