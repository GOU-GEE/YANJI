package com.example.yanji.ongoing.xiaomi

/** Xiaomi's notification extension keys are kept in this adapter only. */
internal object XiaomiFocusKeys {
    const val PARAM = "miui.focus.param"
    const val PICS = "miui.focus.pics"
    const val ACTIONS = "miui.focus.actions"
    const val CHANNEL_ID = "study_timer_xiaomi_focus"
    const val SYSTEM_PROTOCOL_SETTING = "notification_focus_protocol"
    const val FOCUS_PERMISSION_URI =
        "content://miui.statusbar.notification.public"
    const val FOCUS_PERMISSION_METHOD = "canShowFocus"
}
