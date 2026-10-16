package com.example.yanji.ongoing.honor

/** Pure parser for the version formats exposed by HONOR build display strings. */
internal object HonorMagicOsVersion {
    fun parse(display: String, incremental: String): String? {
        val text = "$display $incremental"
        val match = Regex("(?:MagicOS|Magic\\s*UI)\\s*([0-9]+(?:\\.[0-9]+)*)", RegexOption.IGNORE_CASE)
            .find(text)
        return match?.groupValues?.getOrNull(1)
    }

    fun isSupported(version: String): Boolean {
        val major = version.substringBefore('.').toIntOrNull() ?: return false
        // YOYO Suggestions Kit's official supported-device list says MagicOS 7.0+.
        return major >= 7
    }
}
