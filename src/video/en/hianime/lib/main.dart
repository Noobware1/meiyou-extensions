import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_video_extensions_en_hianime/src/hianime.dart';

ParsedHttpSource getSource(NetworkHelper network) {
  return HiAnime(network);
}
