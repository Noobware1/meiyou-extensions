import 'package:meiyou_extensions_lib/models.dart';
import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/utils.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';

class Anilist {
  static Future<Status> fetchStatusByTitle(
      OkHttpClient client, String title) async {
    final query = """
            query {
            	Media(
                  search: "$title",
                  sort: STATUS_DESC,
                  status_not_in: [NOT_YET_RELEASED],
                  format_not_in: [SPECIAL, MOVIE],
                  isAdult: false,
                  type: ANIME
                ) {
                  id
                  idMal
                  title {
                    romaji
                    native
                    english
                  }
                  status
                }
            }
        """;

    final requestBody =
        FormBody.Builder().add("query", StringUtils.trimIndent(query)).build();

    final status = await client
        .newCall(
          POST("https://graphql.anilist.co", body: requestBody),
        )
        .execute()
        .then((value) {
      // ignore: unnecessary_cast
      value as Response;
      return value.body.json((json) {
        return json['data']?['Media']?['status'] as String?;
      });
    });

    if (status == "FINISHED") {
      return Status.completed;
    }
    if (status == "RELEASING") {
      return Status.ongoing;
    } else {
      return Status.unknown;
    }
  }
}
