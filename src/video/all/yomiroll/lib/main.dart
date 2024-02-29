import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:yomiroll/src/yomiroll.dart';

HttpSource getSource(NetworkHelper network) {
  return Yomiroll(network);
}
