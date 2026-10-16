package com.example.yanji.ongoing.xiaomi

import com.example.yanji.BuildConfig

/**
 * The Xiaomi business value is supplied only after Xiaomi approves YANJI's
 * study-session scene. Never put a guessed business value in the app.
 */
internal object XiaomiFocusConfig {
    val business: String = BuildConfig.XIAOMI_FOCUS_BUSINESS.trim()
    val isConfigured: Boolean
        get() = business.isNotEmpty()
}
