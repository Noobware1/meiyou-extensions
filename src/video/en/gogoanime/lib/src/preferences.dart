class Preferences {
  static const List<String> hosters = [
    "Gogo server",
    "Vidstreaming",
    "Doodstream",
    "StreamWish",
    "Mp4upload",
    "FileLions",
  ];

  static const List<String> hosters_names = [
    "vidcdn",
    "anime",
    "doodstream",
    "streamwish",
    "mp4upload",
    "filelions",
  ];

  static const pref_domain_key = "preferred_domain_name";
  static const pref_domain_title = "Override BaseUrl";
  static const pref_domain_default = "https://anitaku.to";
  static const pref_domain_summary =
      "For temporary uses. Updating the extension will erase this setting.";
  static const PREF_DOMAIN_DIALOG_MESSAGE = "Default: $pref_domain_default";

  static const String pref_quality_key = "preferred_quality";
  static const String pref_quality_title = "Preferred quality";
  static const String pref_quality_default = "1080";

  static const List<String> pref_quality_entries = [
    "1080p",
    "720p",
    "480p",
    "360p"
  ];
  static const List<String> pref_quality_values = ["1080", "720", "480", "360"];

  static const String pref_server_key = "preferred_server";
  static const String pref_server_title = "Preferred server";
  static const String pref_server_default = "Gogostream";

  static const String pref_hoster_key = "hoster_selection";
  static const String pref_hoster_title = "Enable/Disable Hosts";
  static const List<String> pref_hoster_default = Preferences.hosters_names;
}
