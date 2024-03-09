import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:hianime/src/hianime.dart';

ParsedHttpSource getSource(NetworkHelper network) {
  return HiAnime(network);
}
