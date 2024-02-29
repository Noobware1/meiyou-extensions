import 'dart:io';

extension IoExtensions on String {
  String fixPath() {
    return this.replaceAll('/', Platform.pathSeparator);
  }

  Directory toDirectory() {
    return Directory(fixPath());
  }

  File toFile() {
    return File(fixPath());
  }
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
      .sublist(0, path.indexOf('meiyou_extensions_repo') + 1)
      .join(Platform.pathSeparator);
}
