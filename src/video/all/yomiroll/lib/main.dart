import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_video_extensions_all_yomiroll/src/yomiroll.dart';

HttpSource getSource(NetworkHelper network) {
  return Yomiroll(network);
}
