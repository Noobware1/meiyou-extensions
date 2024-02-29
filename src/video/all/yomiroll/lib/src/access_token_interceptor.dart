// ignore_for_file: unnecessary_cast

import 'dart:io';

import 'package:meiyou_extensions_lib/network.dart';
import 'package:meiyou_extensions_lib/okhttp_extensions.dart';
import 'package:meiyou_extensions_lib/preference.dart';
import 'package:okhttp/interceptor.dart';
import 'package:okhttp/okhttp.dart';
import 'package:okhttp/request.dart';
import 'package:okhttp/response.dart';
import 'package:yomiroll/src/models.dart';

class AccessTokenInterceptor {
  final String crUrl;
  final SharedPreferences preferences;
  final String PREF_USE_LOCAL_Token;

  AccessTokenInterceptor({
    required this.crUrl,
    required this.preferences,
    required this.PREF_USE_LOCAL_Token,
  });

  Future<Response> intercept(Chain chain) async {
    final accessTokenN = await getAccessToken();
    final request = newRequestWithAccessToken(chain.request, accessTokenN);

    final response = await chain.proceed(request);

    if (response.statusCode == HttpStatus.unauthorized) {
      final refreshedToken = await getAccessToken(true);

      return chain.proceed(
        newRequestWithAccessToken(chain.request, refreshedToken),
      );
    }
    return response;
  }

  Future<AccessToken> getAccessToken([bool force = false]) async {
    final String? token =
        this.preferences.getString(AccessTokenInterceptor._TOKEN_PREF_KEY);
    if (!force && token != null) {
      return AccessToken.decode(token);
    } else {
      final bool useLocalToken = this.preferences.getBool(PREF_USE_LOCAL_Token, false)!;
      if (!useLocalToken) {
        return refreshAccessToken();
      } else {
        return refreshAccessToken(false);
      }
    }
  }

  void removeToken() {
    this.preferences.remove(AccessTokenInterceptor._TOKEN_PREF_KEY);
  }

  Future<AccessToken> refreshAccessToken([bool useProxy = true]) async {
    removeToken();
    final builder = OkHttpClient().newBuilder();
    if (useProxy) {
      builder.proxy(
        Proxy(
          type: ProxyType.SOCKS,
          sa: await InternetSocketAddress.fromHost("cr-unblocker.us.to", 1080),
          auth: PasswordAuthentication("crunblocker", "crunblocker"),
        ),
      );
    }

    final OkHttpClient client = builder.build();
    final parsedJson = await client.newCall(await getRequest()).execute().then(
        (value) => (value as Response)
            .body
            .json((json) => AccessToken.fromJson(json)));

    final AccessToken allTokens = await client
        .newCall(newRequestWithAccessToken(
            GET("${this.crUrl}/index/v2"), parsedJson))
        .execute()
        .then((value) {
      value as Response;
      return value.body.json((json) {
        final policy = Policy.fromJson(json);
        return AccessToken(
          accessToken: parsedJson.accessToken,
          tokenType: parsedJson.tokenType,
          policy: policy.policy,
          signature: policy.signature,
          keyPairId: policy.keyPairId,
          bucket: policy.bucket,
          policyExpire: DateTime.parse(policy.expires).millisecondsSinceEpoch,
        );
      });
    });

    this
        .preferences
        .setString(AccessTokenInterceptor._TOKEN_PREF_KEY, allTokens.encode());
    return allTokens;
  }

  Request newRequestWithAccessToken(Request request, AccessToken tokenData) {
    return request
        .newBuilder()
        .header(
            "authorization", "${tokenData.tokenType} ${tokenData.accessToken}")
        .build();
    // final requestUrl = request.url.toString();
    // print(request.url.toString());
    // if (requestUrl.contains("/cms/v2")) {
    //   builder.url(buildString((it) {
    //     it as StringBuffer;
    //     it.write(requestUrl);
    //     it.write(tokenData.bucket);
    //     it.write(tokenData.policy);
    //     it.write(tokenData.signature);
    //     it.write(tokenData.keyPairId);
    //   }));
    // }
  }

  Future<Request> getRequest() async {
    final client = OkHttpClient();
    final refreshToken = await client
        .newCall(
          GET("https://raw.githubusercontent.com/Samfun75/File-host/main/aniyomi/refreshToken.txt"),
        )
        .execute()
        .then((response) => (response as Response)
            .body
            .string
            .replaceFirst(RegExp("[\n\r]"), ""));

    final headers = Headers.Builder()
        .add("Content-Type", "application/x-www-form-urlencoded")
        .add(
          "Authorization",
          "Basic b2VkYXJteHN0bGgxanZhd2ltbnE6OWxFaHZIWkpEMzJqdVY1ZFc5Vk9TNTdkb3BkSnBnbzE=",
        )
        .build();
    final postBody = FormBody.Builder()
        .add("grant_type", "refresh_token")
        .add("refresh_token", refreshToken)
        .add("scope", "offline_access")
        .build();
    return POST("${this.crUrl}/auth/v1/token", headers, postBody);
  }

  static const String _TOKEN_PREF_KEY = "access_token_data";
}
