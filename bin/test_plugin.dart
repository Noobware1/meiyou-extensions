import 'dart:io';
import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

import 'build.dart';

void main(List<String> args) async {
  final file = File(args[0]).readAsStringSync();
  final query = args[1];

  final packages = {
    'meiyou': {'main.dart': fixImports(file), ...getAllExtractors(file, {})}
  };

  final compiled = ExtenstionComplier().compilePackages(packages);

  final pluginApi = ExtenstionLoader()
      .runtimeEval(compiled)
      .executeLib('package:meiyou/main.dart', 'main') as $BasePluginApi;

  print('Starting homePage');
  // try {
  //   for (var r in pluginApi.homePage) {
  //     final c = await pluginApi.loadHomePage(
  //         1,
  //         HomePageRequest(
  //             name: r.name,
  //             data: r.data,
  //             horizontalImages: r.horizontalImages));
  //     print(c);
  //     // break;
  //   }
  // } catch (e) {
  //   print(e);
  // }
  print('Starting search for $query');
  final search = await pluginApi.search(query);
  print(search);
  print('');

  print('Starting loadMediaDetails for $query');
  final media = await pluginApi.loadMediaDetails(search.first);

  print(media);
  print('');
  if (media.mediaItem == null) return;

  print('Start loadLinks for $query');

  printRest(pluginApi, media.mediaItem!);
}

printRest(BasePluginApi api, MediaItem mediaItem) async {
  List<ExtractorLink>? links;
  if (mediaItem is Anime) {
    links = await api.loadLinks((mediaItem).episodes.last.data);
  } else if (mediaItem is TvSeries) {
    links = await api.loadLinks((mediaItem).data[0].episodes.first.data);
  } else if (mediaItem is Movie) {
    links = await api.loadLinks(mediaItem.url);
  }

  if (links == null || links.isEmpty) {
    print('No links found');
    return;
  }
  print(links);

  print('Starting loadMedia with ${links[0].name}');
  print(await api.loadMedia(links[0]));
}
