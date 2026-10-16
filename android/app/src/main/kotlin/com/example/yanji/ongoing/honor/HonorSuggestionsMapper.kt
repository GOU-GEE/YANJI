package com.example.yanji.ongoing.honor

import com.example.yanji.ongoing.OngoingActivityState
import java.security.MessageDigest

/**
 * Semantic mapping for YANJI's existing single-session model.
 *
 * Suggestions Kit's public Event API has event start/end semantics; it does
 * not document generic progress, pause, or resume updates. Keep those states
 * explicit here so a future approved HONOR schema cannot silently turn them
 * into unrelated event types.
 */
internal object HonorSuggestionsMapper {
    enum class EventPhase { STARTED, ENDED }

    enum class DisplayState(val capsuleLabel: String) {
        RUNNING("学习中"),
        PAUSED("已暂停"),
        FINISHED("已结束"),
    }

    data class Event(
        val phase: EventPhase,
        val eventId: String,
        val createdAtMillis: Long,
        val beginTimeMillis: Long,
        val endTimeMillis: Long? = null,
    )

    fun displayState(state: OngoingActivityState): DisplayState? = when (state.status) {
        "active" -> DisplayState.RUNNING
        "paused" -> DisplayState.PAUSED
        "finished" -> DisplayState.FINISHED
        else -> null
    }

    /** A start event is emitted once per business session, including restore. */
    fun start(state: OngoingActivityState, nowMillis: Long): Event? {
        if (!state.isOngoing) return null
        return Event(
            phase = EventPhase.STARTED,
            eventId = stableEventId(state.sessionId ?: return null),
            createdAtMillis = nowMillis,
            beginTimeMillis = sessionBeginMillis(state, nowMillis),
        )
    }

    /** Complete and cancel share the business model's terminal `finished` state. */
    fun end(state: OngoingActivityState, nowMillis: Long): Event? {
        if (state.status != "finished") return null
        val sessionId = state.sessionId?.takeIf(String::isNotBlank) ?: return null
        return Event(
            phase = EventPhase.ENDED,
            eventId = stableEventId(sessionId),
            createdAtMillis = nowMillis,
            beginTimeMillis = sessionBeginMillis(state, nowMillis),
            endTimeMillis = nowMillis,
        )
    }

    /** Progress ticks and pause/resume are not Event start/end transitions. */
    @Suppress("UNUSED_PARAMETER")
    fun hasPublicEventUpdate(state: OngoingActivityState): Boolean = false

    fun compactBusinessName(): String = "学习"

    fun compactStatus(state: OngoingActivityState): String? = displayState(state)?.capsuleLabel

    private fun sessionBeginMillis(state: OngoingActivityState, nowMillis: Long): Long =
        (nowMillis - state.elapsedSeconds.coerceAtLeast(0L) * 1000L).coerceAtLeast(0L)

    /** HONOR receives a stable opaque ID, never YANJI's raw local session ID. */
    private fun stableEventId(sessionId: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
            .digest(sessionId.toByteArray(Charsets.UTF_8))
        val shortHex = digest.take(16).joinToString("") { "%02x".format(it) }
        return "yanji-$shortHex"
    }
}

internal enum class HonorFeedbackResult {
    SUCCESS,
    UNSUPPORTED,
    NOT_AUTHORIZED,
    RATE_LIMITED,
    INVALID_PAYLOAD,
    SERVICE_ERROR,
    FAILED,
}

/** Stable mapping for Suggestions Kit ResultCode values. */
internal object HonorFeedbackResultMapper {
    fun fromSdkCode(code: Int): HonorFeedbackResult = when (code) {
        0 -> HonorFeedbackResult.SUCCESS
        10001 -> HonorFeedbackResult.NOT_AUTHORIZED
        10002 -> HonorFeedbackResult.RATE_LIMITED
        10003 -> HonorFeedbackResult.INVALID_PAYLOAD
        10004 -> HonorFeedbackResult.SERVICE_ERROR
        else -> HonorFeedbackResult.FAILED
    }
}
