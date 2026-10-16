package com.example.yanji.ongoing

import org.json.JSONObject

/** Platform-neutral study state received from the existing Flutter bridge. */
internal data class OngoingActivityState(
    val sessionId: String?,
    val subject: String,
    val status: String,
    val elapsedSeconds: Long,
    val todayTotalSeconds: Long,
    val targetSeconds: Long,
    val doNotDisturbEnabled: Boolean,
) {
    val isOngoing: Boolean
        get() = !sessionId.isNullOrBlank() && status in setOf("active", "paused")

    /** Data names are the stable contract consumed by YANJI's eventual UPK. */
    fun toFluidCloudData(nowMillis: Long): JSONObject {
        val safeElapsed = elapsedSeconds.coerceAtLeast(0)
        val startEpochMillis = (nowMillis / 1000L * 1000L) - safeElapsed * 1000L
        return JSONObject()
            .put("sessionId", sessionId.orEmpty())
            .put("subject", subject)
            .put("status", status)
            .put("elapsedSeconds", safeElapsed)
            .put("todayTotalSeconds", todayTotalSeconds.coerceAtLeast(0))
            .put("targetSeconds", targetSeconds.coerceAtLeast(0))
            .put("doNotDisturbEnabled", doNotDisturbEnabled)
            .put("sessionStartedAtEpochMillis", startEpochMillis)
    }
}
