import 'package:meiyou_extensions_lib/meiyou_extensions_lib.dart';

void main(List<String> args) {
  final edges = json['data']!['search']!['videos']['edges'] as List;

  print(edges.map((e) => toSearchResponse(e['node'])));
}

SearchResponse toSearchResponse(dynamic e) {
  final img = e['thumbnailx720'] ??
      e['thumbnailx60'] ??
      e['thumbnailx240'] ??
      e['thumbnailx120'];

  return SearchResponse(
      title: e['title'],
      url: e['xid'],
      poster: StringUtils.valueToString(img),
      type: ShowType.Others);
}

final json = <String, dynamic>{
  "data": {
    "search": {
      "id": "U2VhcmNoOk5vbmU=",
      "videos": {
        "pageInfo": {
          "hasNextPage": true,
          "nextPage": 2,
          "__typename": "PageInfo"
        },
        "totalCount": 5800,
        "edges": [
          {
            "node": {
              "id": "VmlkZW86eDhxbThmYw==",
              "xid": "x8qm8fc",
              "title":
                  "Shin Chan New Episode in Hindi | Shin Chan Funny Episode | #viral #shinchan #viralvideo",
              "createdAt": "2023-12-16T06:41:12+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OHFtOGZj",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4cW04ZmM=",
                  "total": 18,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnV1YW1l",
                "xid": "x2uuame",
                "name": "ShinchanLatestEpisode",
                "displayName": "Shinchan Latest Episode",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 478,
              "thumbnailx60": "https://s1.dmcdn.net/v/VVque1bVLx0IbH2JX/x60",
              "thumbnailx120": "https://s1.dmcdn.net/v/VVque1bVLx0Nusxmy/x120",
              "thumbnailx240": "https://s1.dmcdn.net/v/VVque1bVLx0TU5TaU/x240",
              "thumbnailx720": "https://s1.dmcdn.net/v/VVque1bVLx0u5hPPs/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhodzh5Zw==",
              "xid": "x8hw8yg",
              "title": "Shinchan New episode hindi Dubbed 2023",
              "createdAt": "2023-02-03T18:51:58+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGh3OHln",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4aHc4eWc=",
                  "total": 20789,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnFhcmV0",
                "xid": "x2qaret",
                "name": "Animationvideosofficial",
                "displayName": "Animation Videos",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 1392,
              "thumbnailx60": "https://s1.dmcdn.net/v/UdyPO1ZtMjBCMq-Uh/x60",
              "thumbnailx120": "https://s1.dmcdn.net/v/UdyPO1ZtMjBarDHjM/x120",
              "thumbnailx240": "https://s1.dmcdn.net/v/UdyPO1ZtMjBlBDwJ5/x240",
              "thumbnailx720": "https://s1.dmcdn.net/v/UdyPO1ZtMjB-qnIND/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhrczJrdg==",
              "xid": "x8ks2kv",
              "title":
                  "Shinchan Season 16 Episode 45 in Hindi / Hum Dono Twins Hai / Chalo Kare Sumo Wrestling! ( New Episode )",
              "createdAt": "2023-05-09T01:30:25+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGtzMmt2",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4a3Mya3Y=",
                  "total": 12508,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnJrNnVt",
                "xid": "x2rk6um",
                "name": "dm_f848ffc35b861f529f3e519576fc53b9",
                "displayName": "Cartoons World",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 970,
              "thumbnailx60": "https://s2.dmcdn.net/v/UwR0F1aY-3pt3rMIW/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UwR0F1aY-3pWskSVd/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UwR0F1aY-3pnTFiJ8/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UwR0F1aY-3pkNZqLa/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhpZ2l0aA==",
              "xid": "x8igith",
              "title": "Shinchan New Horror Episode In Hindi",
              "createdAt": "2023-02-20T08:56:53+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGlnaXRo",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4aWdpdGg=",
                  "total": 42537,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnI0ZnU0",
                "xid": "x2r4fu4",
                "name": "Cartoon-tv-Hindi",
                "displayName": "Cartoon tv-Hindi",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 456,
              "thumbnailx60": "https://s2.dmcdn.net/v/UhZL51aHktj20jqDS/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UhZL51aHktj6_r0mK/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UhZL51aHktj_zB7Hw/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UhZL51aHktjWllRgO/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhrbDY3dA==",
              "xid": "x8kl67t",
              "title":
                  "Shinchan Season 16 Episode 34 in Hindi / Aaj Hum Karenge Sking! ( New Episode )",
              "createdAt": "2023-05-02T10:13:51+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGtsNjd0",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4a2w2N3Q=",
                  "total": 18166,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnJrNnVt",
                "xid": "x2rk6um",
                "name": "dm_f848ffc35b861f529f3e519576fc53b9",
                "displayName": "Cartoons World",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 970,
              "thumbnailx60": "https://s2.dmcdn.net/v/UvCQv1aZ3HnbOuvtz/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UvCQv1aZ3HnJPfnKa/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UvCQv1aZ3HnAJtdDE/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UvCQv1aZ3HnVDJd99/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhsMnptZQ==",
              "xid": "x8l2zme",
              "title":
                  "Shinchan Season 16 Episode 64 in Hindi / Dad Ka Bura Sapna / Action Kamen Stamp! ( New Episode )",
              "createdAt": "2023-05-20T02:20:39+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGwyem1l",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4bDJ6bWU=",
                  "total": 21420,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnJrNnVt",
                "xid": "x2rk6um",
                "name": "dm_f848ffc35b861f529f3e519576fc53b9",
                "displayName": "Cartoons World",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 963,
              "thumbnailx60": "https://s1.dmcdn.net/v/UyNNM1aZ1uv8b6v1L/x60",
              "thumbnailx120": "https://s1.dmcdn.net/v/UyNNM1aZ1uv-u8WrN/x120",
              "thumbnailx240": "https://s1.dmcdn.net/v/UyNNM1aZ1uvjTjpOa/x240",
              "thumbnailx720": "https://s1.dmcdn.net/v/UyNNM1aZ1uv7AjRY1/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhrdW56dQ==",
              "xid": "x8kunzu",
              "title":
                  "crayon shin-chan movie 30 mononoke ninja chinpuuden In English Sub",
              "createdAt": "2023-05-11T12:49:43+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGt1bnp1",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4a3VuenU=",
                  "total": 1426,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnE1NTJ4",
                "xid": "x2q552x",
                "name": "AnimayExplainer",
                "displayName": "Animay Explainer",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 5973,
              "thumbnailx60": "https://s1.dmcdn.net/v/UwuZw1aPE8v3Ix6rE/x60",
              "thumbnailx120": "https://s1.dmcdn.net/v/UwuZw1aPE8vKcS1D9/x120",
              "thumbnailx240": "https://s1.dmcdn.net/v/UwuZw1aPE8vFxer9d/x240",
              "thumbnailx720": "https://s1.dmcdn.net/v/UwuZw1aPE8vA5IdJ2/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhob2NubA==",
              "xid": "x8hocnl",
              "title": "Shin_Chan_Movie_07_The_Spy In Hindi dubbed 2023",
              "createdAt": "2023-01-29T15:32:02+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGhvY25s",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4aG9jbmw=",
                  "total": 88931,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnBpNGtx",
                "xid": "x2pi4kq",
                "name": "Ctv",
                "displayName": "Cartoons TV",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 6448,
              "thumbnailx60": "https://s2.dmcdn.net/v/UcYSH1ZrgZ5clBEj_/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UcYSH1ZrgZ56pSsu1/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UcYSH1ZrgZ5PBqVFX/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UcYSH1ZrgZ5ksMdse/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhodzh5Zg==",
              "xid": "x8hw8yf",
              "title": "Shinchan New episode hindi Dubbed 2023",
              "createdAt": "2023-02-03T18:51:54+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGh3OHlm",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4aHc4eWY=",
                  "total": 62990,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnFhcmV0",
                "xid": "x2qaret",
                "name": "Animationvideosofficial",
                "displayName": "Animation Videos",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 1243,
              "thumbnailx60": "https://s2.dmcdn.net/v/UdyPN1ZtMjB4iFhgh/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UdyPN1ZtMjB2N21U7/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UdyPN1ZtMjBUbjX2x/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UdyPN1ZtMjByg4mHl/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhpc2FubA==",
              "xid": "x8isanl",
              "title":
                  "Shinchan Season 16 EP-2 In Hindi || Shinchan New Episode",
              "createdAt": "2023-03-03T08:21:02+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGlzYW5s",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4aXNhbmw=",
                  "total": 29872,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnI0ZnU0",
                "xid": "x2r4fu4",
                "name": "Cartoon-tv-Hindi",
                "displayName": "Cartoon tv-Hindi",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 970,
              "thumbnailx60": "https://s2.dmcdn.net/v/UjfRn1aHktjqmyrA_/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UjfRn1aHktjwIBpZ_/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UjfRn1aHktjTU3Sk1/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UjfRn1aHktjXLlc34/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhrdzk0bA==",
              "xid": "x8kw94l",
              "title":
                  "Shinchan Season 16 Episode 53 in Hindi / Aaj Hum Khayenge Noodles / Sales Lady Phir Se Aa Gayi! ( New Episode )",
              "createdAt": "2023-05-13T01:57:04+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGt3OTRs",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4a3c5NGw=",
                  "total": 22972,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnJrNnVt",
                "xid": "x2rk6um",
                "name": "dm_f848ffc35b861f529f3e519576fc53b9",
                "displayName": "Cartoons World",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 970,
              "thumbnailx60": "https://s2.dmcdn.net/v/UxAer1aZ3lJvJRwer/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UxAer1aZ3lJfbZSv3/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UxAer1aZ3lJZ6FZo4/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UxAer1aZ3lJc6skuu/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhsMTU0OQ==",
              "xid": "x8l1549",
              "title":
                  "Shinchan Season 16 Episode 59 in Hindi / Neni Ne Apna Ghar Chor Diya / Bada Bhai Bana Bohot Mushkil Hai! ( New Episode )",
              "createdAt": "2023-05-18T02:17:40+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGwxNTQ5",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4bDE1NDk=",
                  "total": 21118,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnJrNnVt",
                "xid": "x2rk6um",
                "name": "dm_f848ffc35b861f529f3e519576fc53b9",
                "displayName": "Cartoons World",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 972,
              "thumbnailx60": "https://s2.dmcdn.net/v/Uy2Kf1aYyEkMnzVOr/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/Uy2Kf1aYyEkRiGk36/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/Uy2Kf1aYyEkKbil_A/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/Uy2Kf1aYyEkeZMryr/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhrdTJtNQ==",
              "xid": "x8ku2m5",
              "title":
                  "Shinchan Season 16 Episode 48 (A) in Hindi / Shiro Ka Naya Ghar! ( New Episode )",
              "createdAt": "2023-05-11T01:18:50+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGt1Mm01",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4a3UybTU=",
                  "total": 14539,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnJrNnVt",
                "xid": "x2rk6um",
                "name": "dm_f848ffc35b861f529f3e519576fc53b9",
                "displayName": "Cartoons World",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 485,
              "thumbnailx60": "https://s2.dmcdn.net/v/Uwnoz1aYyEgJpkgPZ/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/Uwnoz1aYyEgXPB1l_/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/Uwnoz1aYyEgZ9DqQB/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/Uwnoz1aYyEgEj_SVY/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhqaTZqOQ==",
              "xid": "x8ji6j9",
              "title": "Shinchan New episode hindi Dubbed 2023",
              "createdAt": "2023-03-27T19:25:22+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGppNmo5",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4amk2ajk=",
                  "total": 29516,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnFhcmV0",
                "xid": "x2qaret",
                "name": "Animationvideosofficial",
                "displayName": "Animation Videos",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 1576,
              "thumbnailx60": "https://s2.dmcdn.net/v/UoGIL1a8WcQeatcn5/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UoGIL1a8WcQ4N49Wl/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UoGIL1a8WcQb3l9zI/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UoGIL1a8WcQO-unvt/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhpc2Ficg==",
              "xid": "x8isabr",
              "title":
                  "Shinchan Season 15 EP-17 In Hindi || Shinchan New Episode",
              "createdAt": "2023-03-03T08:02:05+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGlzYWJy",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4aXNhYnI=",
                  "total": 15858,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnI0ZnU0",
                "xid": "x2r4fu4",
                "name": "Cartoon-tv-Hindi",
                "displayName": "Cartoon tv-Hindi",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 1509,
              "thumbnailx60": "https://s2.dmcdn.net/v/UjfL71aHktj9odO3Z/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UjfL71aHktjImoNkq/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UjfL71aHktjQBPjrA/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UjfL71aHktjTrLr_U/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhpY3Zvag==",
              "xid": "x8icvoj",
              "title":
                  "Shinchan new episode in hindi | Shinchan new episode in hindi without zoom effect",
              "createdAt": "2023-02-16T16:41:07+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGljdm9q",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4aWN2b2o=",
                  "total": 7334,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnFvMWQw",
                "xid": "x2qo1d0",
                "name": "saikatsardar180",
                "displayName": "Shinchan",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 1474,
              "thumbnailx60": "https://s2.dmcdn.net/v/UgvrZ1a4KXAtYPYE7/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UgvrZ1a4KXAkh1QL4/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UgvrZ1a4KXAnnyE_1/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UgvrZ1a4KXAd37afc/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhpc2Fuaw==",
              "xid": "x8isank",
              "title":
                  "Shinchan Season 16 EP-1 In Hindi || Shinchan New Episode",
              "createdAt": "2023-03-03T08:20:35+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGlzYW5r",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4aXNhbms=",
                  "total": 81762,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnI0ZnU0",
                "xid": "x2r4fu4",
                "name": "Cartoon-tv-Hindi",
                "displayName": "Cartoon tv-Hindi",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 968,
              "thumbnailx60": "https://s1.dmcdn.net/v/UjfRm1aHktjpuY1OL/x60",
              "thumbnailx120": "https://s1.dmcdn.net/v/UjfRm1aHktjFCiZ9L/x120",
              "thumbnailx240": "https://s1.dmcdn.net/v/UjfRm1aHktjfIWYws/x240",
              "thumbnailx720": "https://s1.dmcdn.net/v/UjfRm1aHktja7zi5t/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhrdDBoZQ==",
              "xid": "x8kt0he",
              "title":
                  "Shinchan Season 16 Episode 47 (A) in Hindi / Aaj Hum Khayenge Sukiyaki! ( New Episode )",
              "createdAt": "2023-05-10T00:56:45+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGt0MGhl",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4a3QwaGU=",
                  "total": 21600,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MnJrNnVt",
                "xid": "x2rk6um",
                "name": "dm_f848ffc35b861f529f3e519576fc53b9",
                "displayName": "Cartoons World",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 487,
              "thumbnailx60": "https://s1.dmcdn.net/v/Uwbko1aZ3Hm3oLqjY/x60",
              "thumbnailx120": "https://s1.dmcdn.net/v/Uwbko1aZ3Hm5VI7EN/x120",
              "thumbnailx240": "https://s1.dmcdn.net/v/Uwbko1aZ3HmHUR9H9/x240",
              "thumbnailx720": "https://s1.dmcdn.net/v/Uwbko1aZ3HmkWMGN0/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDhkanRmcg==",
              "xid": "x8djtfr",
              "title":
                  "Crayon Shinchan The Movie: The Tornado Legend Of Ninja Mononoke | Trailer 1",
              "createdAt": "2022-09-08T08:03:24+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4OGRqdGZy",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4ZGp0ZnI=",
                  "total": 4727,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4Mmh5cGRi",
                "xid": "x2hypdb",
                "name": "CinemaOnline",
                "displayName": "Cinema Online",
                "accountType": "verified-partner",
                "__typename": "Channel"
              },
              "duration": 95,
              "thumbnailx60": "https://s2.dmcdn.net/v/UC6Z71Z6RqCtdCDGy/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/UC6Z71Z6RqCQ1pPob/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/UC6Z71Z6RqCNx28ZC/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/UC6Z71Z6RqCbVBCNs/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          },
          {
            "node": {
              "id": "VmlkZW86eDgyMDZmcg==",
              "xid": "x8206fr",
              "title":
                  "ShinChan Telugu Season 1 | Episode 1 | Monu Cartoons | Crayon Shin-chan",
              "createdAt": "2021-06-16T21:09:37+00:00",
              "stats": {
                "id": "VmlkZW9TdGF0czp4ODIwNmZy",
                "views": {
                  "id": "VmlkZW9TdGF0c1ZpZXdzOng4MjA2ZnI=",
                  "total": 53010,
                  "__typename": "VideoStatsViews"
                },
                "__typename": "VideoStats"
              },
              "channel": {
                "id": "Q2hhbm5lbDp4MjQybGEx",
                "xid": "x242la1",
                "name": "Monu_World",
                "displayName": "Monu_World",
                "accountType": "partner",
                "__typename": "Channel"
              },
              "duration": 1120,
              "thumbnailx60": "https://s2.dmcdn.net/v/T28AN1Woca5NNR0Eo/x60",
              "thumbnailx120": "https://s2.dmcdn.net/v/T28AN1Woca5VoVCOf/x120",
              "thumbnailx240": "https://s2.dmcdn.net/v/T28AN1Woca5SyUXtR/x240",
              "thumbnailx720": "https://s2.dmcdn.net/v/T28AN1Woca5bsBJ6b/x720",
              "aspectRatio": null,
              "__typename": "Video"
            },
            "__typename": "VideoEdge"
          }
        ],
        "__typename": "VideoConnection"
      }
    }
  }
};
