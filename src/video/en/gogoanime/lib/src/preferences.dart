class Preferences {
  static const List<String> HOSTERS = [
    "Gogo server",
    "Vidstreaming",
    "Doodstream",
    "StreamWish",
    "Mp4upload",
    "FileLions",
  ];

  static const List<String> HOSTERS_NAMES = [
    "vidcdn",
    "anime",
    "doodstream",
    "streamwish",
    "mp4upload",
    "filelions",
  ];

  static const PREF_DOMAIN_KEY = "preferred_domain_name";
  static const PREF_DOMAIN_TITLE = "Override BaseUrl";
  static const PREF_DOMAIN_DEFAULT = "https://anitaku.to";
  static const PREF_DOMAIN_SUMMARY =
      "For temporary uses. Updating the extension will erase this setting.";
  static const PREF_DOMAIN_DIALOG_MESSAGE = "Default: $PREF_DOMAIN_DEFAULT";

  static const String PREF_QUALITY_KEY = "preferred_quality";
  static const String PREF_QUALITY_TITLE = "Preferred quality";
  static const String PREF_QUALITY_DEFAULT = "1080";

  static const List<String> PREF_QUALITY_ENTRIES = [
    "1080p",
    "720p",
    "480p",
    "360p"
  ];
  static const List<String> PREF_QUALITY_VALUES = ["1080", "720", "480", "360"];

  static const String PREF_SERVER_KEY = "preferred_server";
  static const String PREF_SERVER_TITLE = "Preferred server";
  static const String PREF_SERVER_DEFAULT = "Gogostream";

  static const String PREF_HOSTER_KEY = "hoster_selection";
  static const String PREF_HOSTER_TITLE = "Enable/Disable Hosts";
  static const List<String> PREF_HOSTER_DEFAULT = Preferences.HOSTERS_NAMES;
}
