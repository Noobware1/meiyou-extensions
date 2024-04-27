class Preferences {
  static const PREF_DOMAIN_KEY = "preferred_domain_new";
  static const PREF_DOMAIN_TITLE = "Preferred domain (requires app restart)";
  static const PREF_QUALITY_KEY = "preferred_quality";
  static const PREF_QUALITY_TITLE = "Preferred quality";
  static const PREF_QUALITY_DEFAULT = "1080p";
  static const PREF_QUALITY_LIST = ["1080p", "720p", "480p", "360p"];

  static const PREF_SUB_KEY = "preferred_subLang";
  static const PREF_SUB_TITLE = "Preferred sub language";
  static const PREF_SUB_DEFAULT = "English";
  static const PREF_SUB_LANGUAGES = [
    "Arabic",
    "English",
    "French",
    "German",
    "Hungarian",
    "Italian",
    "Japanese",
    "Portuguese",
    "Romanian",
    "Russian",
    "Spanish",
  ];

  static const PREF_LATEST_KEY = "preferred_latest_page";
  static const PREF_LATEST_TITLE = "Preferred latest page";
  static const PREF_LATEST_DEFAULT = "Movies";
  static const PREF_LATEST_PAGES = ["Movies", "TV Shows"];

  static const PREF_POPULAR_KEY = "preferred_popular_page_new";
  static const PREF_POPULAR_TITLE = "Preferred popular page";
  static const PREF_POPULAR_DEFAULT = "movie";
  static const PREF_POPULAR_ENTRIES = PREF_LATEST_PAGES;
  static const PREF_POPULAR_VALUES = ["movie", "tv-show"];
}
