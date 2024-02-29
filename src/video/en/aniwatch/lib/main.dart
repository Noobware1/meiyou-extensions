import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:aniwatch/src/aniwatch.dart';

ParsedHttpSource getSource(NetworkHelper network) {
  return AniWatch(network);
}
