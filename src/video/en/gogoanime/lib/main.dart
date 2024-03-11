import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:gogoanime/src/gogoanime.dart';

ParsedHttpSource getSource(NetworkHelper network) {
  return GogoAnime(network);
}
