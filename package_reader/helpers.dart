import 'package:dart_eval/dart_eval.dart';
import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/preference.dart';

extension on Source {
  AvailableSource toAvailableSource() {
    return AvailableSource(
      id: id,
      name: name,
      lang: lang,
      baseUrl: this is HttpSource ? (this as HttpSource).baseUrl : '',
    );
  }
}

List<AvailableSource> getSources(String pakage, Program program) {
  final network = NetworkHelper(MockNetworkPrefrences());
  final $instance = ExtensionLoader.ofProgram(program).getSource(
    'package:$pakage/main.dart',
    'getSource',
    network,
  );
  if ($instance is SourceFactory) {
    return $instance
        .getSources(network)
        .map((source) => source.toAvailableSource())
        .toList();
  } else if ($instance is Source) {
    return [$instance.toAvailableSource()];
  } else {
    throw Exception('Invalid source type');
  }
}

class MockNetworkPrefrences implements NetworkPreferences {
  @override
  Preference<String> defaultUserAgent() =>
      MockPreference('default_useragent', '');

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
