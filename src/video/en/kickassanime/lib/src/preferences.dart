class Preferences {
  static const List<String> servers = [
    "DuckStream",
    "BirdStream",
    "VidStreaming"
  ];

  static const String prefix_search = "slug:";

  static const String pref_use_english_key = "pref_use_english";
  static const String pref_use_english_title = "Use English titles";
  static const String pref_use_english_summary =
      "Show Titles in English instead of Romanji when possible.";
  static const bool PREF_USE_ENGLISH_DEFAULT = false;

  static const String pref_quality_key = "preferred_quality";
  static const String pref_quality_title = "Preferred quality";
  static const String pref_quality_default = "1080p";
  static const List<String> pref_quality_entries = [
    "240p",
    "360p",
    "480p",
    "720p",
    "1080p",
    "2160p"
  ];

  static const String pref_audio_lang_key = "preferred_audio_lang";
  static const String pref_audio_lang_title = "Preferred audio language";
  static const String pref_audio_lang_default = "ja-JP";

  // Add new locales to the bottom so it doesn't mess with pref indexes
  static const List<MapEntry<String, String>> locale = [
    MapEntry("en-US", "English"),
    MapEntry("es-ES", "Spanish (España)"),
    MapEntry("ja-JP", "Japanese"),
  ];

  static const String pref_server_key = "preferred_server";
  static const String pref_server_title = "Preferred server";
  static const String pref_server_default = "DuckStream";
  static const List<String> PREF_SERVER_VALUES = servers;

  static const String pref_domain_key = "preferred_domain";
  static const String pref_domain_title =
      "Preferred domain (requires app restart)";
  static const String pref_domain_default = "https://kickassanimes.io";
  static const List<String> pref_domain_entries = [
    "kickassanime.am",
    "kaas.to",
    "kaas.ro"
  ];
  static const List<String> pref_domain_entry_values = [
    "https://kickassanimes.io",
    "https://kaas.ro",
    "https://kaas.to",
    "https://kickassanime.mx",
  ];

  static const String pref_hoster_key = "hoster_selection";
  static const String pref_hoster_title = "Enable/Disable Hosts";
  static const List<String> pref_hoster_default = servers;
}
