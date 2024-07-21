class ZoroPreferences {
  static const prefTitleLangKey = "preferred_title_lang";
  static const prefTitleLangDefault = "Romaji";
  static const prefTitleLangList = ["Romaji", "English"];

  static const prefMarkFillersKey = "mark_fillers";
  static const prefMarkFillersDefault = true;

  static const prefQualityKey = "preferred_quality";
  static const prefQualityDefault = "1080";

  static const prefLangKey = "preferred_language";
  static const prefLangDefault = "Sub";

  static const prefServerKey = "preferred_server";

  static const prefHosterKey = "hoster_selection";

  static const prefTypeToggleKey = "type_selection";
  static const prefTypesEntries = ["Sub", "Dub", "Mixed"];

  static const prefTypesEntryValues = [
    "servers-sub",
    "servers-dub",
    "servers-mixed"
  ];

  static const prefTypesToggleDefault = prefTypesEntryValues;
}
