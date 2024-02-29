class Preferences {
  static const List<String> SERVERS = [
    "DuckStream",
    "BirdStream",
    "VidStreaming"
  ];

  static const String PREFIX_SEARCH = "slug:";

  static const String PREF_USE_ENGLISH_KEY = "pref_use_english";
  static const String PREF_USE_ENGLISH_TITLE = "Use English titles";
  static const String PREF_USE_ENGLISH_SUMMARY =
      "Show Titles in English instead of Romanji when possible.";
  static const bool PREF_USE_ENGLISH_DEFAULT = false;

  static const String PREF_QUALITY_KEY = "preferred_quality";
  static const String PREF_QUALITY_TITLE = "Preferred quality";
  static const String PREF_QUALITY_DEFAULT = "1080p";
  static const List<String> PREF_QUALITY_ENTRIES = [
    "240p",
    "360p",
    "480p",
    "720p",
    "1080p",
    "2160p"
  ];

  static const String PREF_AUDIO_LANG_KEY = "preferred_audio_lang";
  static const String PREF_AUDIO_LANG_TITLE = "Preferred audio language";
  static const String PREF_AUDIO_LANG_DEFAULT = "ja-JP";

  // Add new locales to the bottom so it doesn't mess with pref indexes
  static const List<MapEntry<String, String>>  LOCALE = [
    MapEntry("en-US", "English"),
    MapEntry("es-ES", "Spanish (España)"),
    MapEntry("ja-JP", "Japanese"),
  ];

  static const String PREF_SERVER_KEY = "preferred_server";
  static const String PREF_SERVER_TITLE = "Preferred server";
  static const String PREF_SERVER_DEFAULT = "DuckStream";
  static const List<String> PREF_SERVER_VALUES = SERVERS;

  static const String PREF_DOMAIN_KEY = "preferred_domain";
  static const String PREF_DOMAIN_TITLE =
      "Preferred domain (requires app restart)";
  static const String PREF_DOMAIN_DEFAULT = "https://kickassanimes.io";
  static const List<String> PREF_DOMAIN_ENTRIES = [
    "kickassanime.am",
    "kaas.to",
    "kaas.ro"
  ];
  static const List<String> PREF_DOMAIN_ENTRY_VALUES = [
    "https://kickassanimes.io",
    "https://kaas.ro",
    "https://kaas.to",
    "https://kickassanime.mx",
  ];

  static const String PREF_HOSTER_KEY = "hoster_selection";
  static const String PREF_HOSTER_TITLE = "Enable/Disable Hosts";
  static const List<String> PREF_HOSTER_DEFAULT = SERVERS;
}
