// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';
import 'package:meiyou_extensions_lib/extensions_lib.dart';
import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import '../package_reader/package_reader.dart';
import 'utils.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  stdout.writeln('Test Source');

  final sourceCategories = ['Manga', 'Novel', 'Video'];

  stdout.writeln('Select Source Category: $sourceCategories');

  final index = int.parse(stdin.readLineAndCheckForExit());

  final sourceCategory = sourceCategories[index].toLowerCase();

  final srcPath = getSourceFolderPath();

  stdout.write('Enter Source Language: ');

  final sourceLanguage = stdin.readLineAndCheckForExit().toLowerCase();

  stdout.write('Enter Source Name: ');

  final sourceName = stdin.readLineAndCheckForExit().toLowerCase();

  final directory =
      p.join(srcPath, sourceCategory, sourceLanguage, sourceName).toDirectory();

  stdout.writeln('Selected Path: ${directory.path}');

  // ignore: prefer_interpolation_to_compose_strings
  final prefsDir = p.join(Directory.current.path, 'prefs').toDirectory()
    ..createSync();

  ExtensionlibOverrides.networkHelper = NetworkHelper(Prefs());
  ExtensionlibOverrides.sharedPreferencesDir = prefsDir.path;

  stdout.writeln('Loading Source...');

  final results = PackageReader(directory).read();

  final source = ExtensionLoader.ofProgram(results.program)
      .loadCatalogueSource(results.info.pkgName);

  stdout.writeln('Loaded Source ${source.name}');

  final commands = {
    'Get Home Page': 'gethome',
    'Get Search Page': 'getsearch',
    'Get Info Page': 'getinfo',
    'Get Content Data Link': 'getlinks',
    'Get Content Data': 'getdata',
    'Reset': 'r',
    'Quit': 'q',
    'Back': 'b',
  };
  for (var command in commands.entries) {
    stdout.writeln('${command.key}: ${command.value}');
  }

  final Set<MediaPreview> items = {};
  final Set<MediaContent> contents = {};
  final Set<MediaLink> contentDataLink = {};

  await runCommand(
    source: source,
    items: items,
    contents: contents,
    contentDataLink: contentDataLink,
  );

  prefsDir.deleteSync();
}

Future<void> runCommand({
  required CatalogueSource source,
  required Set<MediaPreview> items,
  required Set<MediaContent> contents,
  required Set<MediaLink> contentDataLink,
}) async {
  stdout.writeln('Enter Command: ');
  final command = stdin.readLineAndCheckForExit();

  switch (command) {
    case 'gethome':
      stdout.writeln('Enter Page: ');
      final _page = stdin.readLineAndCheckForExit();
      final page = int.parse(_page);
      stdout.writeln('Enter Request Index: ');
      final _requestIndex = stdin.readLineAndCheckForExit();
      final requestIndex = int.parse(_requestIndex);
      try {
        final res = await source.getHomePage(
            page, source.homePageRequests().elementAt(requestIndex));
        items.addAll(IterableUtils.flatten(res.items.map((e) => e.list)));
        print(res);
      } catch (e, s) {
        print(e);
        print(s);
      }
      break;
    case 'getsearch':
      stdout.write('Enter Page: ');
      final _page = stdin.readLineAndCheckForExit();
      if (_page == 'b') break;
      final page = int.parse(_page);
      stdout.write('Enter Query: ');
      final query = stdin.readLineAndCheckForExit();
      if (query == 'b') break;
      try {
        final res =
            await source.getSearchPage(page, query, source.getFilterList());
        items.addAll(res.list);
        print(res);
      } catch (e, s) {
        print(e);
        print(s);
      }
      break;
    case 'getinfo':
      for (var i = 0; i < items.length; i++) {
        final item = items.elementAt(i);
        stdout.writeln('$i: ${item.title}');
      }
      stdout.write('ContentItem index: ');
      final index = stdin.readLineAndCheckForExit();
      if (index == 'b') break;
      final item = items.elementAt(int.parse(index));
      try {
        final res = await source.getMediaDetails(item.url);
        if (res.content != null && res.content is! LazyMediaContent) {
          contents.add(res.content!);
        }
        print(res);
        if (res.content is LazyMediaContent) {
          try {
            final content = await (res.content as LazyMediaContent).call();
            contents.add(content);
            print(content);
          } catch (e, s) {
            print(e);
            print(s);
          }
        }
      } catch (e, s) {
        print(e);
        print(s);
      }
      break;
    case 'getlinks':
      final List<String Function(int)> list = [];
      for (var i = 0; i < contents.length; i++) {
        final (str, callback) = contentToString(contents.elementAt(i));
        list.add(callback);
        stdout.writeln('$i: $str');
      }
      stdout.write('Enter Content index: ');
      final _contentIndex = stdin.readLineAndCheckForExit();
      if (_contentIndex == 'b') break;
      final contentIndex = int.parse(_contentIndex);
      final callback = list[contentIndex];
      stdout.write('Enter Url Index: ');
      final _urlIndex = stdin.readLineAndCheckForExit();
      final urlIndex = int.parse(_urlIndex);
      final url = callback(urlIndex);

      try {
        final res = await source.getMediaLinks(url);
        contentDataLink.addAll(res);
        print(res);
      } catch (e, s) {
        print(e);
        print(s);
      }
      break;
    case 'getdata':
      for (var i = 0; i < contentDataLink.length; i++) {
        final link = contentDataLink.elementAt(i);
        stdout.writeln('$i: ${link.name}');
      }
      stdout.write('ContentDataLink index: ');
      final index = stdin.readLineAndCheckForExit();
      if (index == 'b') break;
      final link = contentDataLink.elementAt(int.parse(index));
      try {
        final res = await source.getMedia(link);
        print(res);
      } catch (e, s) {
        print(e);
        print(s);
      }
      break;
    case 'r':
      await runCommand(
        source: source,
        items: items,
        contents: contents,
        contentDataLink: contentDataLink,
      );
      break;
    case 'q':
      return;
    default:
      stdout.writeln('Invalid Command');
      break;
  }
  await runCommand(
    source: source,
    items: items,
    contents: contents,
    contentDataLink: contentDataLink,
  );
}

(String, String Function(int) callback) contentToString(MediaContent content) {
  final StringBuffer buffer = StringBuffer();
  if (content is EpisodicContent) {
    buffer.write('EpisodicContent: [');
    for (var i = 0; i < content.episodes.length; i++) {
      buffer.write('$i: ${content.episodes[i].data}');
      if (i != content.episodes.length - 1) buffer.write(', ');
    }
    buffer.write(']');

    return (buffer.toString(), (index) => content.episodes[index].data);
  } else if (content is Movie) {
    buffer.write('Movie: ${content.playUrl}');
    return (buffer.toString(), (index) => content.playUrl);
  } else if (content is TvSeries) {
    buffer.write('Series: [');
    for (var i = 0; i < content.seasons.length; i++) {
      final season = content.seasons[i];

      buffer.write('Season ${season.season.number ?? i}: [');
      for (var j = 0; j < season.episodes.length; j++) {
        buffer.write('${j + i}: ${season.episodes[j].data}');
      }
    }

    return (
      buffer.toString(),
      (index) => IterableUtils.flatten(content.seasons.map((e) => e.episodes))
          .elementAt(index)
          .data
    );
  } else {
    throw Exception('Invalid Content Type');
  }
}

extension on Stdin {
  String readLineAndCheckForExit() {
    final line = readLineSync()!;
    if (line == 'q') {
      exit(0);
    }
    return line;
  }
}
