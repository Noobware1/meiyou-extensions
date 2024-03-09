import 'package:dart_eval/dart_eval.dart';
import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/preference.dart';

List<CatalogueSource> getSources(String package, Program program) {
  final network = NetworkHelper(MockNetworkPrefrences());
  final $instance = ExtensionLoader.ofProgram(program).getSource(
    package,
    network,
  );
  if ($instance is SourceFactory) {
    return $instance
        .getSources(network)
        .map((source) => source as CatalogueSource)
        .toList();
  } else if ($instance is CatalogueSource) {
    return [$instance];
  } else {
    throw Exception('Invalid source type');
  }
}

class MockNetworkPrefrences implements NetworkPreferences {
  @override
  Preference<String> defaultUserAgent() => MockPreference('default_useragent',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0');

  @override
  Preference<int> dohProvider() => MockPreference('doh', -1);

  @override
  Preference<bool> verboseLogging() => MockPreference('verbose_logging', false);
}

class MockPreference<T> implements Preference<T> {
  final String _key;
  final T _value;

  MockPreference(this._key, this._value);

  @override
  T defaultValue() => _value;

  @override
  void delete() {
    // TODO: implement delete
  }

  @override
  T get() => _value;

  @override
  bool isSet() {
    return false;
  }

  @override
  String key() {
    return _key;
  }

  @override
  void set(value) {
    // TODO: implement set
  }
}
