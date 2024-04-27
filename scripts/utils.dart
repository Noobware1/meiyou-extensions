import 'dart:io';

import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/preference.dart';
import 'package:meiyou_extensions_lib/utils.dart';

extension IoExtensions on String {
  Directory toDirectory() =>
      Directory(this.replaceAll('/', Platform.pathSeparator));

  File toFile() => File(this.replaceAll('/', Platform.pathSeparator));
}

extension DirectoryUtils on Directory {
  String get name => uri.pathSegments.where((e) => e.isNotEmpty).last;
}

extension FileUtils on File {
  String get name => uri.pathSegments.where((e) => e.isNotEmpty).last;
}

String getSourceFolderPath() => '${getRepoPath()}${Platform.pathSeparator}src';

String getRepoPath() {
  var path =
      File.fromUri(Platform.script).absolute.path.split(Platform.pathSeparator);

  return path
      .sublist(0, path.indexOf('meiyou-extensions') + 1)
      .join(Platform.pathSeparator);
}

class Prefs implements NetworkPreferences {
  @override
  Preference<String> defaultUserAgent() {
    return PreferenceImpl(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3');
  }

  @override
  Preference<int> dohProvider() {
    return PreferenceImpl(-1);
  }

  @override
  Preference<bool> verboseLogging() {
    return PreferenceImpl(false);
  }
}

class PreferenceImpl<T> implements Preference<T> {
  final T value;
  PreferenceImpl(this.value);
  @override
  Stream<T> changes() {
    throw UnimplementedError();
  }

  @override
  T defaultValue() {
    return value;
  }

  @override
  void delete() {
    // TODO: implement delete
  }

  @override
  T get() {
    return value;
  }

  @override
  bool isSet() {
    // TODO: implement isSet
    throw UnimplementedError();
  }

  @override
  String key() {
    // TODO: implement key
    throw UnimplementedError();
  }

  @override
  void set(value) {
    // TODO: implement set
  }
}

Future<Result<T>> runAsyncCatching<T>(Future<T> Function() f) async {
  try {
    return Result.success(await f());
  } catch (e) {
    return Result.failure(e is Exception ? e : Exception(e.toString()));
  }
}
