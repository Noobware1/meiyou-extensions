import 'dart:convert';

import 'package:meiyou_extensions_lib/extenstions.dart';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    throw ArgumentError(
        'Please Provide plugin name and plugin type like: dart run make_plugin.dart example_plugin video');
  }

  final type = args[1].toLowerCase();
  try {
    final folderName = args[0];

    print('Creating $folderName....');

    final folder = Directory(
        '${Directory.current.path.substringBeforeLast('bin').replaceAll('\\', '/')}src/$type/$folderName'); // ..createSync(recursive: true);

    print('Creating build.info.json....');

    //Name
    stdout.write('Enter plugin name: ');
    final name = stdin.readLineSync() ?? '';

    //Author
    stdout.write('Enter plugin author: ');
    final author = stdin.readLineSync() ?? '';

    //Description
    stdout.write('Enter plugin Description: ');
    final description = stdin.readLineSync() ?? '';

    //Lang
    stdout.write('Enter plugin language: ');
    final lang = stdin.readLineSync() ?? '';

    //Description
    stdout.write('Enter plugin baseUrl: ');
    final baseUrl = stdin.readLineSync() ?? '';

    final OnlinePlugin plugin = OnlinePlugin(
      name: name,
      type: type,
      author: author,
      description: description,
      lang: lang,
      baseUrl: baseUrl,
      version: '0.0.1',
      downloadUrl:
          "https://raw.githubusercontent.com/Noobware1/meiyou_extensions_repo/builds/$folderName.plugin",
      iconUrl:
          "https://raw.githubusercontent.com/Noobware1/meiyou_extensions_repo/builds/icons/$folderName.png",
    );

    folder.createSync(recursive: true);

    File('${folder.path}/info.json')
      ..createSync()
      ..writeAsStringSync(
          JsonEncoder.withIndent('    ').convert(plugin.toJson()));

    print('Generating plugin temeplate....');

    File('${folder.path}/$folderName.dart')
      ..createSync()
      ..writeAsStringSync(codeTemplate(plugin.name));

    print('Successfully created plugin at ${folder.path}');
  } catch (e, s) {
    print('Failed to create plugin: $e');
    print(s);
  }
}

String codeTemplate(String className) => '''
// ignore_for_file: unnecessary_cast, unnecessary_this

import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

class $className extends BasePluginApi {
  $className();

  @override
  String get baseUrl => throw UnimplementedError();

  // ============================== HomePage ===================================

  @override
  Iterable<HomePageData> get homePage => throw UnimplementedError();

  // ============================== LoadHomePage ===============================

  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) {
    throw UnimplementedError();
  }

  // =========================== LoadMediaDetails ==============================

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse)  {
    throw UnimplementedError();
  }

  // =============================== LoadLinks =================================

  @override
  Future<List<ExtractorLink>> loadLinks(String url)  {
    throw UnimplementedError();
  }

  // =============================== LoadMedia =================================

  @override
  Future<Media?> loadMedia(ExtractorLink link)  {
    throw UnimplementedError();
  }

  // ================================ Search ===================================

  @override
  Future<List<SearchResponse>> search(String query) {
    throw UnimplementedError();
  }

  // ================================ Helpers ==================================

}

main() {
  return $className();
}

''';
