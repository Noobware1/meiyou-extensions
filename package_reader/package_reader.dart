// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';
import 'dart:typed_data';
import 'package:dart_eval/dart_eval.dart';
import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:yaml/yaml.dart';
import '../scripts/utils.dart';
import 'helpers.dart';

class ReadResult {
  final AvailableExtension info;
  final Program program;
  final Uint8List iconBytes;
  final Map<String, Map<String, String>> packages;

  ReadResult({
    required this.program,
    required this.iconBytes,
    required this.info,
    required this.packages,
  });
}

class PackageReader {
  final Directory _packageFolder;

  PackageReader(String path) : _packageFolder = path.toDirectory();

  final Map<String, Map<String, String>> _packages = {};

  String get _packageName => _info!.pkgName;

  late final _libPath =
      _packageFolder.absolute.path + Platform.pathSeparator + 'lib';

  late final _pubspecPath =
      _packageFolder.absolute.path + Platform.pathSeparator + 'pubspec.yaml';

  late final _iconPath = _packageFolder.absolute.path +
      Platform.pathSeparator +
      'icon' +
      Platform.pathSeparator +
      'icon.png';

  final List<String> _extensionsImports = [];

  AvailableExtension? _info;

  final _meiyouExtensionRegex = RegExp(
      r"""import\s'package:meiyou_extensions\/([^'"]*['"](?:\s+as\s+([a-zA-Z_]\w*))?\s*);""");

  ReadResult read() {
    _readYaml(File(_pubspecPath).readAsStringSync());

    _packages[_info!.pkgName] = {};

    _read(Directory(_libPath));

    _addExtensionImports();

    final program = ExtensionComplier().compile(_packages);

    _info!.sources.addAll(getSources(
      _info!.pkgName,
      program,
    ));

    final iconBytes = _getIconBytes();

    return ReadResult(
      info: _info!,
      packages: _packages,
      program: program,
      iconBytes: iconBytes,
    );
  }

  void _addExtensionImports() {
    final Map<String, String> files = {};
    final lib =
        getRepoPath() + Platform.pathSeparator + 'lib' + Platform.pathSeparator;
    for (var import in _extensionsImports) {
      files[import] = (lib + import).toFile().readAsStringSync();
    }

    if (files.isNotEmpty) {
      _packages['meiyou_extensions'] = files;
    }
  }

  void _readYaml(String file) {
    final yaml = loadYaml(file);

    final String name = yaml['sourceName'];
    final String pkg = yaml['name'];
    // final String description = yaml['description'];
    final String version = yaml['version'];
    final int nsfw = yaml['nsfw'];
    final String lang = yaml['lang'];

    _info = AvailableExtension(
      pkgName: pkg,
      name: 'Meiyou: $name',
      versionName: version,
      isNsfw: nsfw == 1,
      lang: lang,
      pluginName: 'meiyou-$pkg-v$version.plugin',
      iconUrl: '$pkg-v$version.png',
      sources: List.empty(growable: true),
      repoUrl: '',
    );
  }

  void _read(Directory folder) {
    for (var entity in folder.listSync()) {
      if (entity is File && entity.name.endsWith('.dart')) {
        final code = entity.readAsStringSync();

        if (code.isNotEmpty) {
          _extensionsImports.addAll(
            _meiyouExtensionRegex
                .allMatches(code)
                .map((e) => Scopes.let(e.group(1), (it) {
                      if (it == null) return null;
                      return it.substring(0, it.length - 1);
                    }))
                .nonNulls,
          );
          _packages[_packageName]![entity.pathInPackage(_packageName)] = code;
        }
      } else if (entity is Directory) {
        _read(entity);
      } else {
        continue;
      }
    }
  }

  Uint8List _getIconBytes() {
    return File(_iconPath).readAsBytesSync();
  }
}

extension on File {
  String pathInPackage(String sourceName) {
    var seg = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    seg = seg.sublist(seg.indexOf(sourceName) + 2);

    return seg.join('/');
  }
}
