import 'dart:convert';

class AccessToken {
  final String accessToken;
  final String tokenType;
  final String? policy;
  final String? signature;
  final String? keyPairId;
  final String? bucket;
  final int? policyExpire;

  AccessToken({
    required this.accessToken,
    required this.tokenType,
    required this.policy,
    required this.signature,
    required this.keyPairId,
    required this.bucket,
    required this.policyExpire,
  });

  String encode() => jsonEncode(toJson());

  factory AccessToken.decode(String encoded) =>
      AccessToken.fromJson(jsonDecode(encoded));

  factory AccessToken.fromJson(dynamic json) {
    return AccessToken(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      policy: json['policy'],
      signature: json['signature'],
      keyPairId: json['key_pair_id'],
      bucket: json['bucket'],
      policyExpire: json['policyExpire'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'policy': policy,
      'signature': signature,
      'key_pair_id': keyPairId,
      'bucket': bucket,
      'policyExpire': policyExpire,
    };
  }

  @override
  String toString() {
    return 'AccessToken{accessToken: $accessToken, tokenType: $tokenType, policy: $policy, signature: $signature, keyPairId: $keyPairId, bucket: $bucket, policyExpire: $policyExpire}';
  }
}

class Policy {
  final String policy;
  final String signature;
  final String keyPairId;
  final String bucket;
  final String expires;
  Policy({
    required this.policy,
    required this.signature,
    required this.keyPairId,
    required this.bucket,
    required this.expires,
  });

  String encode() => jsonEncode(toJson());

  // factory Policy.decode(String encoded) => Policy.fromJson(jsonDecode(encoded));

  factory Policy.fromJson(dynamic json) {
    final cms = json['cms'];
    return Policy(
      policy: cms['policy'],
      signature: cms['signature'],
      keyPairId: cms['key_pair_id'],
      bucket: cms['bucket'],
      expires: cms['expires'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policy': policy,
      'signature': signature,
      'key_pair_id': keyPairId,
      'bucket': bucket,
      'expires': expires,
    };
  }
}
