package com.example.yanji.ongoing.xiaomi

import com.example.yanji.ongoing.OngoingActivityState
import org.json.JSONObject

/**
 * Maps YANJI's existing stopwatch state to Xiaomi's param_v2 notification.
 *
 * HyperOS 2 uses the focus-notification fields. HyperOS 3 adds the compact
 * island fields. The optional JSON "protocol" member is intentionally omitted:
 * Xiaomi's current guide shows it in an example but does not define its meaning.
 */
internal object XiaomiSuperIslandMapper {
    const val HYPEROS_2 = 2
    const val HYPEROS_3 = 3
    const val MAX_LIFETIME_SECONDS = 12 * 60 * 60
    private const val MAX_SUBJECT_CODE_POINTS = 24

    internal data class Payload(
        val json: String,
        val notificationTimeoutMillis: Long,
        val remainingSeconds: Int,
    )

    fun map(
        state: OngoingActivityState,
        protocolVersion: Int,
        approvedBusiness: String,
    ): Payload? {
        val sessionId = state.sessionId?.takeIf(String::isNotBlank) ?: return null
        if (!state.isOngoing || protocolVersion !in HYPEROS_2..HYPEROS_3) return null
        val business = approvedBusiness.trim().takeIf(String::isNotEmpty) ?: return null
        val elapsed = state.elapsedSeconds.coerceAtLeast(0)
        val remaining = MAX_LIFETIME_SECONDS - elapsed
        if (remaining <= 0) return null

        val isPaused = state.status == "paused"
        val title = if (isPaused) "已暂停" else "学习中"
        val subject = compactText(state.subject)
        val param = JSONObject()
            .put("business", business)
            .put("updatable", true)
            .put("islandFirstFloat", false)
            .put("enableFloat", false)
            .put("reopen", "reopen")
            .put("timeout", (remaining / 60).coerceAtLeast(1))
            // Keep the base notification visible if the focus permission is
            // revoked between the asynchronous capability check and notify().
            .put("filterWhenNoPermission", false)
            .put(
                "baseInfo",
                JSONObject()
                    .put("type", 1)
                    .put("title", title)
                    .put("content", subject),
            )
            .put("aodTitle", title)

        if (protocolVersion == HYPEROS_2) {
            param.put("ticker", title)
        } else {
            param.put(
                "param_island",
                JSONObject()
                    .put("islandProperty", 1)
                    .put("islandTimeout", remaining)
                    .put("bigIslandArea", bigIslandArea(title, subject))
                    .put("smallIslandArea", smallIslandArea()),
            )
        }

        val root = JSONObject().put("param_v2", param)
        return Payload(
            json = root.toString(),
            notificationTimeoutMillis = remaining * 1000L,
            remainingSeconds = remaining.toInt(),
        )
    }

    private fun bigIslandArea(title: String, subject: String) =
        JSONObject().put(
            "imageTextInfoLeft",
            JSONObject()
                .put("type", 1)
                .put("picInfo", JSONObject().put("type", 1))
                .put(
                    "textInfo",
                    JSONObject()
                        .put("frontTitle", title)
                        .put("title", subject)
                        .put("content", ""),
                ),
        )

    private fun smallIslandArea() =
        JSONObject().put("picInfo", JSONObject().put("type", 1))

    internal fun compactText(value: String): String {
        val flattened = value.replace(Regex("\\s+"), " ").trim()
        if (flattened.isEmpty()) return "自由学习"
        val count = flattened.codePointCount(0, flattened.length)
        if (count <= MAX_SUBJECT_CODE_POINTS) return flattened
        val end = flattened.offsetByCodePoints(0, MAX_SUBJECT_CODE_POINTS - 1)
        return flattened.substring(0, end).trimEnd() + "…"
    }

    internal fun progressPercent(elapsedSeconds: Long, targetSeconds: Long): Int? {
        if (targetSeconds <= 0L) return null
        val elapsed = elapsedSeconds.coerceAtLeast(0L)
        return ((elapsed.toDouble() / targetSeconds.toDouble()) * 100.0)
            .toInt()
            .coerceIn(0, 100)
    }

    internal fun formatDuration(elapsedSeconds: Long): String {
        val safe = elapsedSeconds.coerceAtLeast(0L)
        val hours = safe / 3600
        val minutes = safe / 60 % 60
        val seconds = safe % 60
        return if (hours > 0) {
            "%d:%02d:%02d".format(hours, minutes, seconds)
        } else {
            "%02d:%02d".format(safe / 60, seconds)
        }
    }
}
