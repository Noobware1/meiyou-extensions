import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:kickassanime/src/kickassanime.dart';

HttpSource getSource(NetworkHelper network) {
  return KickAssAnime(network);
}
