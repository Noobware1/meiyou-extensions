import 'dart:convert';

import 'package:meiyou_extenstions/meiyou_extenstions.dart';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    throw ArgumentError(
        'Please Provide folder name like: dart run make_plugin.dart example_plugin');
  }
  try {
    final folderName = args[0];

    print('Creating $folderName....');

    final folder = Directory(
        '${Directory.current.path.substringBeforeLast('bin').replaceAll('\\', '/')}lib/$folderName')
      ..createSync(recursive: true);

    print('Generating plugin temeplate....');

    File('${folder.path}/$folderName.dart')
      ..createSync()
      ..writeAsStringSync(codeTemplate('ExamplePlugin'));

    print('Creating build.info.json....');

    //Name
    stdout.write('Enter plugin name: ');
    final name = stdin.readLineSync() ?? '';

    //Type
    stdout.write('Enter plugin type: ');
    final type = stdin.readLineSync() ?? '';

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

    final Plugin plugin = Plugin(
        name: name,
        type: type,
        author: author,
        description: description,
        lang: lang,
        baseUrl: baseUrl,
        version: '0.0.1',
        downloadUrl: '');

    File('${folder.path}/build.info.json')
      ..createSync()
      ..writeAsStringSync(
          JsonEncoder.withIndent('    ').convert(plugin.toJson()));
    print('Successfully created plugin at ${folder.path}');
  } catch (e, s) {
    print('Failed to create plugin: $e');
    print(s);
  }
}

String codeTemplate(String className) => '''
import 'package:meiyou_extenstions/meiyou_extenstions.dart';

class $className extends BasePluginApi {
  @override
  // TODO: implement homePage
  Iterable<HomePageData> get homePage => throw UnimplementedError();

  @override
  Future<HomePage> loadHomePage(int page, HomePageRequest request) {
    // TODO: implement loadHomePage
    throw UnimplementedError();
  }

  @override
  Future<List<ExtractorLink>> loadLinks(String url) {
    // TODO: implement loadLinks
    throw UnimplementedError();
  }

  @override
  Future<Media?> loadMedia(ExtractorLink link) {
    // TODO: implement loadMedia
    throw UnimplementedError();
  }

  @override
  Future<MediaDetails> loadMediaDetails(SearchResponse searchResponse) {
    // TODO: implement loadMediaDetails
    throw UnimplementedError();
  }

  @override
  Future<List<SearchResponse>> search(String query) {
    // TODO: implement search
    throw UnimplementedError();
  }
}


BasePluginApi main() {
  return $className();
}

''';
