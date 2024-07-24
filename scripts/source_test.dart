// // // ignore_for_file: no_leading_underscores_for_local_identifiers

// import 'dart:async';
// import 'dart:collection';
// import 'dart:io';
// import 'package:meiyou_extensions_lib/models.dart';
// import 'package:meiyou_extensions_lib/utils.dart';
// import '../package_reader/package_reader.dart';
// import 'utils.dart';
// import 'package:path/path.dart' as p;

// const _resetColor = '\x1B[0m';

// extension on MediaPreview {
//   MediaDetails toMediaDetails() {
//     return MediaDetails(
//       title: title,
//       description: description,
//       poster: poster,
//       format: format,
//       genres: generes,
//       url: url,
//     );
//   }
// }

// extension on String? {
//   bool isEmptyOrNull() => this == null || this!.isEmpty;
// }

// extension<T> on List<T>? {
//   bool isEmptyOrNull() => this == null && this!.isEmpty;
// }

// extension on MediaDetailsAndContent {
//   String get name =>
//       "${details.title} - ${content.runtimeType.toString().replaceFirst('\$', '')}";
// }

// extension on MediaDetails {
//   void mergeWithPreview(MediaPreview preview) {
//     title = title.isEmpty ? preview.title : title;
//     description =
//         description.isEmptyOrNull() ? preview.description : description;
//     poster = poster.isEmptyOrNull() ? preview.poster : poster;
//     format =
//         format == MediaFormat.others && preview.format != MediaFormat.others
//             ? preview.format
//             : format;
//     genres = genres.isEmptyOrNull() ? preview.generes : genres;
//     url = url.isEmptyOrNull() ? preview.url : url;
//   }
// }

// void writeInfo(String info) {
//   stdout.writeln('\x1B[34m[Info]$_resetColor $info');
// }

// String askForInput(String question) {
//   stdout.write('\x1B[36m[Input]$_resetColor $question: ');
//   return stdin.readLineSync()!;
// }

// void writeSuccess(String success) {
//   stdout.writeln('\x1B[32m[Success]$_resetColor $success');
// }

// void writeWarning(String warning) {
//   stdout.writeln('\x1B[33m[Warning]$_resetColor $warning');
// }

// void writeError(Object error, [StackTrace? stackTrace]) {
//   stderr.writeln('\x1B[31m[Error]$_resetColor $error');
// }

// void askForLangaugeFolder({
//   required String srcPath,
//   required Cache cache,
// }) {
//   final entries = cache.categoryAndLangauges.entries.toList();
//   for (var i = 0; i < entries.length; i++) {
//     final entry = entries[i];
//     writeInfo('${i + 1}: Category: ${entry.key}');
//     writeInfo(
//         'Available Languages: ${ListUtils.mapListIndexed(entry.value, (index, lang) => '{ ${index + 1}: $lang }')}');
//   }
//   final categoryIndex = runCatching(() =>
//       int.parse(askForInput(
//           'Enter category index you want to test [1 - ${entries.length}] : ')) -
//       1);

//   if (categoryIndex.isFailure) {
//     writeError('Invalid category index');
//     askForLangaugeFolder(
//       srcPath: srcPath,
//       cache: cache,
//     );
//   }

//   final category = entries[categoryIndex.getOrThrow()].key;

//   final languages = entries[categoryIndex.getOrThrow()].value;

//   final langIndex = runCatching(() =>
//       int.parse(askForInput(
//           'Enter language index you want to test [1 - ${languages.length}] : ')) -
//       1);

//   if (langIndex.isFailure) {
//     writeError('Invalid language index');
//     askForLangaugeFolder(
//       srcPath: srcPath,
//       cache: cache,
//     );
//   }

//   final language = languages[langIndex.getOrThrow()];

//   writeSuccess('Selected: $category/$language');

//   final packagesDir = p.join(srcPath, category, language).toDirectory();

//   getSource(
//     srcPath: srcPath,
//     packagesDir: packagesDir,
//     cache: cache,
//   );
// }

// void useSource({
//   required String srcPath,
//   required Directory packagesDir,
//   required Cache cache,
//   required ReadResult selectedPackage,
// }) {
//   final sources = selectedPackage.sources;

//   if (sources.isEmpty) {
//     writeWarning('No sources found in selected package');
//     getSource(
//       srcPath: srcPath,
//       packagesDir: packagesDir,
//       cache: cache,
//     );
//   }

//   final sourceNames = ListUtils.mapListIndexed(
//       sources, (index, source) => '{ ${index + 1}: ${source.name} }');

//   writeInfo('Available Sources: $sourceNames');

//   final sourceIndex = runCatching(() =>
//       int.parse(askForInput(
//           'Enter source index you want to test [1 - ${sources.length}] : ')) -
//       1);

//   if (sourceIndex.isFailure) {
//     writeError('Invalid source index');
//     useSource(
//       srcPath: srcPath,
//       packagesDir: packagesDir,
//       cache: cache,
//       selectedPackage: selectedPackage,
//     );
//   }

//   final selectedSource = sources[sourceIndex.getOrThrow()];

//   try {
//     writeSuccess('Selected: ${selectedSource.name} - ${selectedSource.lang}');
//   } catch (e, s) {
//     writeError(
//         'Failed to access source properties. Please re-check source code and check for errors in name and lang getters');
//     writeError(e, s);
//   }

//   askForCommand(
//     srcPath: srcPath,
//     packagesDir: packagesDir,
//     cache: cache,
//     selectedSource: selectedSource,
//   );
// }

// void askForCommand({
//   required String srcPath,
//   required Directory packagesDir,
//   required Cache cache,
//   required CatalogueSource selectedSource,
// }) {
//   final commands = [
//     'id',
//     'name',
//     'homePageRequestTimeout',
//     'lang',
//     'homePageRequests',
//     'getHomePage',
//     'getMediaDetails',
//     'getMediaContent',
//     'getMediaLinks',
//     'getMedia',
//     'getSearchPage',
//     'getFilterList',
//     'preferences',
//     'setupPreferences',
//   ];

//   writeInfo('Available Commands - ${commands.length}');
//   for (var i = 0; i < commands.length; i++) {
//     writeInfo('${i + 1}: ${commands[i]}');
//   }

//   final commandIndex = int.parse(askForInput(
//           'Enter command index you want to test [1 - ${commands.length}] : ')) -
//       1;

//   final selectedCommand = commands[commandIndex];

//   writeSuccess('Selected: $selectedCommand');

//   runCommand(
//     command: selectedCommand,
//     selectedSource: selectedSource,
//     srcPath: srcPath,
//     packagesDir: packagesDir,
//     cache: cache,
//   );
// }

// class Cache {
//   final Map<String, List<ReadResult>> loadedPackages = {};
//   final Map<String, List<String>> categoryAndLangauges = {};
//   final Map<int, Map<String, MediaPreview>> mediaPreviews = {};
//   final Map<int, Map<String, MediaDetailsAndContent>> mediaDetailsAndContent =
//       {};
//   final Map<int, Map<String, List<MediaLink>>> mediaLinks = {};

//   Cache();
// }

// class MediaDetailsAndContent {
//   final MediaDetails details;
//   MediaContent? content;

//   MediaDetailsAndContent(this.details, [this.content]);
// }

// Future<void> runCommand({
//   required String command,
//   required CatalogueSource selectedSource,
//   required String srcPath,
//   required Directory packagesDir,
//   required Cache cache,
// }) async {
//   void runSafe(void Function() f, {String? errorMessage}) {
//     try {
//       return f();
//     } catch (e, s) {
//       writeError(e, s);
//     }
//   }

//   Future<void> runAsyncSafe(Future<void> Function() f,
//       {required String errorMessage, required void Function() onError}) async {
//     try {
//       return await f();
//     } catch (e, s) {
//       writeError(errorMessage);
//       writeError(e, s);
//       onError();
//     }
//   }

//   void printHomepageRequest(List<HomePageRequest> requests,
//       {bool isInfo = false}) {
//     writeSuccess('Available HomePageRequests: ${requests.length}');
//     for (var i = 0; i < requests.length; i++) {
//       var name = isInfo ? requests[i].title : requests[i];
//       final str = '${i + 1}: HomePageRequest $name';
//       if (isInfo) {
//         writeInfo(str);
//       } else {
//         writeSuccess(str);
//       }
//     }
//   }

//   var completer = Completer<void>();
//   bool futureRunning = false;

//   void completeFuture() {
//     futureRunning = false;
//     completer.complete();
//   }

//   switch (command) {
//     case 'id':
//       runSafe(() => writeSuccess('ID: ${selectedSource.id}'),
//           errorMessage: 'Failed to get id');
//       break;
//     case 'name':
//       runSafe(() => writeSuccess('Name: ${selectedSource.name}'),
//           errorMessage: 'Failed to get name');
//       break;
//     case 'homePageRequestTimeout':
//       runSafe(
//           () => writeSuccess(
//               'homePageRequestTimeout: ${selectedSource.homePageRequestTimeout}'),
//           errorMessage: 'Failed to get homePageRequestTimeout');
//       break;
//     case 'lang':
//       runSafe(() => writeSuccess('Language: ${selectedSource.lang}'),
//           errorMessage: 'Failed to get lang');
//       break;
//     case 'homePageRequests':
//       runSafe(() {
//         printHomepageRequest(selectedSource.homePageRequests());
//       }, errorMessage: 'Failed to get homePageRequests');
//       break;
//     case 'getHomePage':
//       runAsyncSafe(
//         () async {
//           final requests = selectedSource.homePageRequests();
//           printHomepageRequest(requests, isInfo: true);
//           final requestIndex = runCatching(() =>
//               int.parse(askForInput(
//                   'Enter request index you want to test [1 - ${requests.length}] : ')) -
//               1);

//           if (requestIndex.isFailure) {
//             writeError('Invalid request index');
//             runCommand(
//               command: command,
//               selectedSource: selectedSource,
//               srcPath: srcPath,
//               packagesDir: packagesDir,
//               cache: cache,
//             );
//           }

//           final page =
//               runCatching(() => int.parse(askForInput('Enter page number: ')));

//           if (page.isFailure) {
//             writeError('Invalid page number');
//             runCommand(
//               command: command,
//               selectedSource: selectedSource,
//               srcPath: srcPath,
//               packagesDir: packagesDir,
//               cache: cache,
//             );
//           }

//           final homePage = await selectedSource.getHomePage(
//               page.getOrThrow(), requests[requestIndex.getOrThrow()]);

//           writeSuccess('HomePage: $homePage');

//           runCatching(() {
//             final key = selectedSource.id;
//             final _cache = cache.mediaPreviews[key] ?? {};
//             IterableUtils.forEachIndexed(
//                 IterableUtils.flatten(homePage.items.map((e) => e.list)),
//                 (index, preview) {
//               _cache[preview.title] = preview;
//             });
//             cache.mediaPreviews[key] = _cache;
//           });

//           completeFuture();
//         },
//         errorMessage: 'Failed to get homePage',
//         onError: completeFuture,
//       );
//       futureRunning = true;
//       break;

//     case 'getMediaDetails':
//       runAsyncSafe(
//         () async {
//           final key = selectedSource.id;
//           final _cache = cache.mediaPreviews[key] ?? {};
//           final previews = _cache.values.toList();

//           if (previews.isEmpty) {
//             writeWarning(
//                 'No previews found! Please run getHomePage or getSearchPage command first');
//             return;
//           }

//           writeInfo('Available Previews: ${previews.length}');

//           for (var i = 0; i < previews.length; i++) {
//             writeInfo('${i + 1}: ${previews[i].title}');
//           }

//           final previewIndex = runCatching(() =>
//               int.parse(askForInput(
//                   'Enter preview index you want to test [1 - ${previews.length}] : ')) -
//               1);

//           if (previewIndex.isFailure) {
//             writeError('Invalid preview index');
//             runCommand(
//               command: command,
//               selectedSource: selectedSource,
//               srcPath: srcPath,
//               packagesDir: packagesDir,
//               cache: cache,
//             );
//           }

//           final preview = previews[previewIndex.getOrThrow()];

//           final details =
//               await selectedSource.getMediaDetails(preview.toMediaDetails());

//           writeSuccess('MediaDetails: $details');

//           runCatching(() {
//             final _cache = cache.mediaDetailsAndContent[key] ?? {};
//             _cache[preview.title] =
//                 MediaDetailsAndContent(details..mergeWithPreview(preview));
//             cache.mediaDetailsAndContent[key] = _cache;
//           });

//           completeFuture();
//         },
//         errorMessage: 'Failed to get media details',
//         onError: completeFuture,
//       );
//       futureRunning = true;
//       break;
//     case 'getMediaContent':
//       runAsyncSafe(
//         () async {
//           final key = selectedSource.id;
//           final _cache = cache.mediaPreviews[key] ?? {};
//           final previews = _cache.values.toList();

//           if (previews.isEmpty) {
//             writeWarning(
//                 'No previews found! Please run getHomePage or getSearchPage command first');
//             return;
//           }

//           writeInfo('Available Previews: ${previews.length}');

//           for (var i = 0; i < previews.length; i++) {
//             writeInfo('${i + 1}: ${previews[i].title}');
//           }

//           final previewIndex = runCatching(() =>
//               int.parse(askForInput(
//                   'Enter preview index you want to test [1 - ${previews.length}] : ')) -
//               1);

//           if (previewIndex.isFailure) {
//             writeError('Invalid preview index');
//             runCommand(
//               command: command,
//               selectedSource: selectedSource,
//               srcPath: srcPath,
//               packagesDir: packagesDir,
//               cache: cache,
//             );
//           }

//           final preview = previews[previewIndex.getOrThrow()];

//           final content =
//               await selectedSource.getMediaContent(preview.toMediaDetails());

//           writeSuccess(
//               '${content.runtimeType.toString().replaceFirst('\$', '')}: $content');

//           runCatching(() {
//             final _cache = cache.mediaDetailsAndContent[key] ?? {};
//             final detailsAndContent = (_cache[preview.title]
//                   ?..content = content) ??
//                 MediaDetailsAndContent(preview.toMediaDetails(), content);
//             _cache[preview.title] = detailsAndContent;
//             cache.mediaDetailsAndContent[key] = _cache;
//           });

//           completeFuture();
//         },
//         errorMessage: 'Failed to get media details',
//         onError: completeFuture,
//       );
//       futureRunning = true;
//       break;
//     case 'getMediaLinks':
//       runAsyncSafe(
//         () async {
//           final key = selectedSource.id;
//           final _cache = cache.mediaDetailsAndContent[key] ?? {};
//           final contents =
//               _cache.values.where((e) => e.content != null).toList();

//           if (contents.isEmpty) {
//             writeWarning(
//                 'No media content found! Please run getMediaContent command first');
//             return;
//           }

//           final contentNames = ListUtils.mapListIndexed(
//               contents, (index, content) => '${index + 1}: ${content.name}');

//           writeInfo('Available MediaContent: $contentNames');

//           final contentIndex = runCatching(() =>
//               int.parse(askForInput(
//                   'Enter content index you want to test [1 - ${contentNames.length}] : ')) -
//               1);

//           if (contentIndex.isFailure) {
//             writeError('Invalid content index');
//             runCommand(
//               command: command,
//               selectedSource: selectedSource,
//               srcPath: srcPath,
//               packagesDir: packagesDir,
//               cache: cache,
//             );
//           }

//           final content = contents[contentIndex.getOrThrow()];

//           writeSuccess('Selected: ${content.name}');
//           var data = '';
//           List<Episode>? episodes;
//           if (content.content is Movie) {
//             data = (content.content as Movie).playUrl;
//           } else if (data is TvSeries) {
//             final seasons = (content.content as TvSeries).seasons;
//             final seasonNames = ListUtils.mapListIndexed(
//                 seasons,
//                 (index, season) =>
//                     '${index + 1}: Season ${season.number ?? index}');

//             writeInfo('Available Seasons: $seasonNames');

//             final seasonIndex = runCatching(() =>
//                 int.parse(askForInput(
//                     'Enter season index you want to test [1 - ${seasonNames.length}] : ')) -
//                 1);

//             if (seasonIndex.isFailure) {
//               writeError('Invalid season index');
//               runCommand(
//                 command: command,
//                 selectedSource: selectedSource,
//                 srcPath: srcPath,
//                 packagesDir: packagesDir,
//                 cache: cache,
//               );
//             }

//             final season = seasons[seasonIndex.getOrThrow()];
//             episodes = season.episodes;
//           } else if (content.content is Anime) {
//             episodes = (content.content as Anime).episodes;
//           }

//           if (episodes != null) {
//             final episodeNames = ListUtils.mapListIndexed(
//                 episodes,
//                 (index, episode) =>
//                     '${index + 1}: Episode ${episode.number ?? index}');

//             writeInfo('Available Episodes: $episodeNames');

//             final episodeIndex = runCatching(() =>
//                 int.parse(askForInput(
//                     'Enter episode index you want to test [1 - ${episodeNames.length}] : ')) -
//                 1);

//             if (episodeIndex.isFailure) {
//               writeError('Invalid episode index');
//               runCommand(
//                 command: command,
//                 selectedSource: selectedSource,
//                 srcPath: srcPath,
//                 packagesDir: packagesDir,
//                 cache: cache,
//               );
//             }

//             data = episodes[episodeIndex.getOrThrow()].data;
//           }

//           final links = await selectedSource.getMediaLinks(data);

//           writeSuccess('MediaLinks: $links');

//           runCatching(() {
//             final _cache = cache.mediaLinks[key] ?? {};
//             _cache[content.details.title] = links;
//             cache.mediaLinks[key] = _cache;
//           });

//           completeFuture();
//         },
//         errorMessage: 'Failed to get media Links',
//         onError: completeFuture,
//       );
//       futureRunning = true;
//       break;
//     case 'getMedia':
//       runAsyncSafe(
//         () async {
//           final key = selectedSource.id;
//           final _cache = cache.mediaLinks[key] ?? {};
//           final previewsNames = _cache.keys.toList();

//           if (previewsNames.isEmpty) {
//             writeWarning(
//                 'No media links content found! Please run getMediaLinks command first');
//             return;
//           }

//           for (var i = 0; i < previewsNames.length; i++) {
//             writeInfo('${i + 1}: ${previewsNames[i]}');
//           }

//           final previewIndex = runCatching(() =>
//               int.parse(askForInput(
//                   'Enter preview index you want to test [1 - ${previewsNames.length}] : ')) -
//               1);

//           if (previewIndex.isFailure) {
//             writeError('Invalid preview index');
//             runCommand(
//               command: command,
//               selectedSource: selectedSource,
//               srcPath: srcPath,
//               packagesDir: packagesDir,
//               cache: cache,
//             );
//           }

//           final previewKey = previewsNames[previewIndex.getOrThrow()];

//           final links = _cache[previewKey] ?? [];

//           if (links.isEmpty) {
//             writeWarning(
//                 'No media links content found! Please run getMediaLinks command first');
//             return;
//           }

//           final linksNames = ListUtils.mapListIndexed(
//               links, (index, link) => '${index + 1}: ${link.name}');

//           writeInfo('Available MediaLinks: $linksNames');

//           final linkIndex = runCatching(() =>
//               int.parse(askForInput(
//                   'Enter media link index you want to test [1 - ${linksNames.length}] : ')) -
//               1);

//           if (linkIndex.isFailure) {
//             writeError('Invalid media link index');
//             runCommand(
//               command: command,
//               selectedSource: selectedSource,
//               srcPath: srcPath,
//               packagesDir: packagesDir,
//               cache: cache,
//             );
//           }

//           final link = links[linkIndex.getOrThrow()];

//           writeSuccess('Selected: ${link.name}');

//           final media = await selectedSource.getMedia(link);

//           writeSuccess(
//               '${media.runtimeType.toString().replaceFirst('\$', '')}: $media');

//           completeFuture();
//         },
//         errorMessage: 'Failed to get media',
//         onError: completeFuture,
//       );
//       futureRunning = true;
//       break;

//     case 'q':
//       exit(0);
//     case 'b':
//       writeInfo('Going back to command selection');
//       break;
//     default:
//       writeWarning('Command not found');
//       break;
//   }

//   if (futureRunning) {
//     writeInfo('Waiting for future to complete');
//     await completer.future;
//   }
//   askForCommand(
//     srcPath: srcPath,
//     packagesDir: packagesDir,
//     cache: cache,
//     selectedSource: selectedSource,
//   );
// }

// void getSource({
//   required String srcPath,
//   required Directory packagesDir,
//   required Cache cache,
// }) {
//   writeInfo('Analyzing language folder...');

//   final dirName = packagesDir.name;

//   final _cache = cache.loadedPackages[dirName] ?? [];
//   final packages = packagesDir
//       .listSync()
//       .whereType<Directory>()
//       .map((package) {
//         final name = package.name;
//         final cachePackage = runCatching(() =>
//                 _cache.firstWhere((element) => element.info.pkgName == name))
//             .getOrNull();
//         if (cachePackage != null) {
//           return cachePackage;
//         }

//         try {
//           return PackageReader(package).read();
//         } catch (e, s) {
//           writeError('Failed to read package: ${package.name}');
//           writeError(e, s);
//           return null;
//         }
//       })
//       .nonNulls
//       .toList();

//   if (packages.isEmpty) {
//     writeWarning('No packages found in selected language folder');

//     askForLangaugeFolder(
//       srcPath: srcPath,
//       cache: cache,
//     );
//   }
//   cache.loadedPackages[dirName] = packages;

//   writeSuccess('Found ${packages.length} packages in selected language folder');

//   final packageNames = ListUtils.mapListIndexed(
//       packages, (index, package) => '{ ${index + 1}: ${package.info.name} }');

//   writeInfo('Available Packages: $packageNames');

//   final packageIndex = int.parse(askForInput(
//           'Enter package index you want to test [1 - ${packages.length}] : ')) -
//       1;

//   final selectedPackage = packages[packageIndex];

//   writeSuccess('Selected: ${selectedPackage.info.name}');

//   useSource(
//     srcPath: srcPath,
//     packagesDir: packagesDir,
//     cache: cache,
//     selectedPackage: selectedPackage,
//   );
// }

// void main(List<String> args) async {
//   try {
//     stdout.writeln('\x1B[32mSource Tester \x1B[32m $_resetColor');

//     writeInfo('Analyzing Repository...');

//     final srcPath = getSourceFolderPath();

//     const sourceCategories = ['manga', 'novel', 'video'];

//     final cache = Cache();

//     for (var category in sourceCategories) {
//       final categoryDir = p.join(srcPath, category).toDirectory();
//       if (!categoryDir.existsSync()) {
//         writeWarning('Category $category does not exist');
//         continue;
//       }

//       final languagesFolder = categoryDir.listSync().whereType<Directory>();
//       final languages = languagesFolder.map((e) => e.name).toList();

//       if (languages.isEmpty) {
//         writeWarning('No languages found for category: $category');
//       } else {
//         cache.categoryAndLangauges[category] = languages;
//         writeInfo(
//             'Found ${languages.length} languages for category: $category');
//       }
//     }

//     askForLangaugeFolder(srcPath: srcPath, cache: cache);
//   } catch (e, s) {
//     writeError(e, s);
//   }

// // (String, String Function(int) callback) contentToString(MediaContent content) {
// //   final StringBuffer buffer = StringBuffer();
// //   if (content is Anime) {
// //     buffer.write('Anime: [');
// //     for (var i = 0; i < content.episodes.length; i++) {
// //       buffer.write('$i: ${content.episodes[i].data}');
// //       if (i != content.episodes.length - 1) buffer.write(', ');
// //     }
// //     buffer.write(']');

// //     return (buffer.toString(), (index) => content.episodes[index].data);
// //   } else if (content is Movie) {
// //     buffer.write('Movie: ${content.playUrl}');
// //     return (buffer.toString(), (index) => content.playUrl);
// //   } else if (content is TvSeries) {
// //     buffer.write('Series: [');
// //     for (var i = 0; i < content.seasons.length; i++) {
// //       final season = content.seasons[i];

// //       buffer.write('Season ${season.number ?? i}: [');
// //       for (var j = 0; j < season.episodes.length; j++) {
// //         buffer.write('${j + i}: ${season.episodes[j].data}');
// //       }
// //     }

// //     return (
// //       buffer.toString(),
// //       (index) => IterableUtils.flatten(content.seasons.map((e) => e.episodes))
// //           .elementAt(index)
// //           .data
// //     );
// //   } else {
// //     throw Exception('Invalid Content Type');
// //   }
// // }

// // extension on Stdin {
// //   String readLineAndCheckForExit() {
// //     final line = readLineSync()!;
// //     if (line == 'q') {
// //       exit(0);
// //     }
// //     return line;
// //   }
// // }
// }
