package media.bcc.bccm_player.utils

object LanguageUtils {
    fun toThreeLetterLanguageCode(languageCode: String?): String? {
        return when (languageCode) {
            // Norwegian
            "no", "nb", "nb-NO", "nor", "nob", "no-nob" -> "nor"

            // English
            "en", "eng", "en-US", "en-GB" -> "eng"

            // French
            "fr", "fra", "fr-FR" -> "fra"

            // German
            "de", "deu", "de-DE" -> "deu"

            // Hungarian
            "hu", "hun", "hu-HU" -> "hun"

            // Spanish
            "es", "spa", "es-ES" -> "spa"

            // Italian
            "it", "ita", "it-IT" -> "ita"

            // Polish
            "pl", "pol", "pl-PL" -> "pol"

            // Romanian
            "ro", "ron", "ro-RO" -> "ron"

            // Russian
            "ru", "rus", "ru-RU" -> "rus"

            // Slovenian
            "sl", "slv", "sl-SI" -> "slv"

            // Turkish
            "tr", "tur", "tr-TR" -> "tur"

            // Chinese
            "zh", "zho", "cmn", "zh-cmn", "zh-CN" -> "zho"

            // Cantonese
            "zh-HK", "yue", "yue-HK" -> "yue"

            // Tamil
            "ta", "tam", "ta-IN" -> "tam"

            // Bulgarian
            "bg", "bul", "bg-BG" -> "bul"

            // Dutch
            "nl", "nld", "nl-NL" -> "nld"

            // Danish
            "da", "dan", "da-DK" -> "dan"

            // Finnish
            "fi", "fin", "fi-FI" -> "fin"

            // Portuguese
            "pt", "por", "pt-PT" -> "por"

            // Khasi
            "kha", "kha-IN" -> "kha"

            // Croatian
            "hr", "hrv", "hbs-hrv", "hr-HR" -> "hrv"

            else -> languageCode
        }
    }
}