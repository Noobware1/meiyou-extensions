import 'dart:io';

import 'package:meiyou_extensions_lib/utils.dart';

import 'utils.dart';
part 'source_templates/source.dart';
part 'source_templates/catalogue_source.dart';
part 'source_templates/http_source.dart';
part 'source_templates/parsed_http_source.dart';
part 'source_templates/pub_spec.dart';

extension on Directory {
  String get fixPath => path + Platform.pathSeparator;
}

void main(List<String> args) async {
  assert(args.isNotEmpty, 'Please provide a path to create the source');
  assert(args[0].split('/').length == 3,
      'The path must be in format <type[video|text|image]>/<language[all|en|etc]>/<name>');

  var path = args[0].toLowerCase().replaceAll('/', Platform.pathSeparator);

  final segs = args[0].split('/');

  final dir =
      (getSourceFolderPath() + Platform.pathSeparator + path.toLowerCase())
          .toDirectory();

  if (dir.existsSync()) {
    throw Exception(
        'The source with name ${segs[2]} already exists in language ${segs[1]} for ${segs[0]} please try a different name');
  }
  print('Creating source ${segs.last}...');
  final createdPath = Scopes.let(
      (getSourceFolderPath() +
              Platform.pathSeparator +
              segs.sublist(0, 2).join('/'))
          .toDirectory(), (it) {
    it as Directory;
    if (!it.existsSync()) it.createSync(recursive: true);
    return it.path;
  })!;

  print('Path: $createdPath');
  try {
    final results = await Process.run(
      'dart create',
      ['--no-pub', '-t', 'package', segs.last],
      runInShell: true,
      workingDirectory: createdPath,
    );
    print(results.stderr);
    print(results.stdout);
    final sourceName = segs.last;

    // delete trash
    ('${dir.fixPath}example').toDirectory().deleteSync(recursive: true);
    ('${dir.fixPath}test').toDirectory().deleteSync(recursive: true);
    ('${dir.fixPath}CHANGELOG.md').toFile().deleteSync();
    ('${dir.fixPath}README.md').toFile().deleteSync();
    '${dir.fixPath}lib/src/${sourceName}_base.dart'.toFile().deleteSync();
    '${dir.fixPath}lib/$sourceName.dart'.toFile().deleteSync();
    ('${dir.fixPath}analysis_options.yaml').toFile().writeAsStringSync('''

include: package:lints/recommended.yaml

linter:
  rules:
    non_constant_identifier_names: false
    unnecessary_this: false
    constant_identifier_names: false

''');
    final sourceType =
        StringUtils.toIntOrNull(ListUtils.getOrNull(args, 2)) ?? 0;

    ('${dir.fixPath}pubspec.yaml')
        .toFile()
        .writeAsStringSync(pubSpecTemplate(segs.last, segs[1]));

    '${dir.fixPath}lib/main.dart'
        .toFile()
        .writeAsStringSync(Scopes.let<int, String>(sourceType, (it) {
          switch (sourceType) {
            case 0:
              return getSourceTemplate(sourceName);
            case 1:
              return getCatalogueSourceTemplate(sourceName);
            case 2:
              return getHttpSourceTemplate(sourceName);
            case 3:
              return getParsedHttpSourceTemplate(sourceName);
            default:
              throw Exception('Unknown Source Type');
          }
        })!);

    '${dir.fixPath}lib/src/$sourceName.dart'
        .toFile()
        .writeAsStringSync(Scopes.let<int, String>(sourceType, (it) {
          switch (sourceType) {
            case 0:
              return sourceTemplate(sourceName);
            case 1:
              return catalogueSourceTemplate(sourceName);
            case 2:
              return httpSourceTemplate(sourceName);
            case 3:
              return parsedHttpSourceTemplate(sourceName);
            default:
              throw Exception('Unknown Source Type');
          }
        })!);

    print('SuccessFully created source at $path...');
    print(
        'Start by editing the file in $sourceName/lib/src/$sourceName.dart...');
  } catch (_, s) {
    print('$_\n$s');
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    print('Failed to created source at $path...');
  }
}
