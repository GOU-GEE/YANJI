package com.example.yanji.ongoing.honor

import android.content.Context
import android.util.Log
import com.example.yanji.BuildConfig
import com.hihonor.android.magicx.intelligence.suggestion.Suggestion
import com.hihonor.android.magicx.intelligence.suggestion.api.FeedbackClient
import com.hihonor.android.magicx.intelligence.suggestion.callback.FeedbackCallback
import com.hihonor.android.magicx.intelligence.suggestion.model.EventFeedbackReq
import java.util.concurrent.atomic.AtomicBoolean

/** Thin SDK wrapper. Callers must pass capability and lifecycle gates first. */
internal class HonorSuggestionsClient {
    private companion object {
        const val tag = "YANJI.HonorMagicCapsule"
        const val preferencesName = "honor_suggestions_feedback"
        const val keyLastSuccessful = "last_successful_key"
        const val keyLastSuccessfulAt = "last_successful_at"
        const val keyBlockedUntil = "blocked_until"
    }

    fun feedbackEvent(
        context: Context,
        event: HonorSuggestionsMapper.Event,
        callback: (HonorFeedbackResult) -> Unit,
    ) {
        HonorSuggestionsCapability.check(context) { report ->
            if (!report.fullLifecycleReady) {
                callback(HonorFeedbackResult.UNSUPPORTED)
                return@check
            }
            submitApprovedEvent(context.applicationContext, event, callback)
        }
    }

    private fun submitApprovedEvent(
        context: Context,
        event: HonorSuggestionsMapper.Event,
        callback: (HonorFeedbackResult) -> Unit,
    ) {
        val endedStatus = BuildConfig.HONOR_SUGGESTIONS_ENDED_STATUS
        val eventStatus = when (event.phase) {
            HonorSuggestionsMapper.EventPhase.STARTED -> "00"
            HonorSuggestionsMapper.EventPhase.ENDED -> endedStatus
        }
        if (eventStatus.isBlank()) {
            callback(HonorFeedbackResult.UNSUPPORTED)
            return
        }

        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val gateState = HonorFeedbackGate.State(
            lastSuccessfulKey = preferences.getString(keyLastSuccessful, null),
            lastSuccessfulAtMillis = preferences.getLong(keyLastSuccessfulAt, 0L),
            blockedUntilMillis = preferences.getLong(keyBlockedUntil, 0L),
        )
        val key = HonorFeedbackGate.eventKey(event)
        if (!HonorFeedbackGate.shouldDispatch(gateState, key, System.currentTimeMillis())) {
            Log.i(tag, "Duplicate or flow-limited feedback suppressed")
            callback(HonorFeedbackResult.SUCCESS)
            return
        }

        try {
            val suggestion = Suggestion.getInstance(context.applicationContext)
            if (!suggestion.hasFeature(
                    com.hihonor.android.magicx.intelligence.suggestion.common.enumrate.FeatureEnum.FEEDBACK_EVENT.value,
                )
            ) {
                callback(HonorFeedbackResult.UNSUPPORTED)
                return
            }
            val feedbackClient: FeedbackClient = suggestion.feedbackClient
            val request = EventFeedbackReq().apply {
                intentType = BuildConfig.HONOR_SUGGESTIONS_INTENT_TYPE
                this.eventStatus = eventStatus
                createTime = event.createdAtMillis
                beginTime = event.beginTimeMillis
                event.endTimeMillis?.let { this.endTime = it }
                eventId = event.eventId
            }
            val completed = AtomicBoolean(false)
            val accepted = feedbackClient.feedbackEvent(
                request,
                object : FeedbackCallback {
                    override fun onResult(resultCode: Int) {
                        if (!completed.compareAndSet(false, true)) return
                        val mapped = HonorFeedbackResultMapper.fromSdkCode(resultCode)
                        recordResult(preferences, gateState, key, mapped)
                        HonorSuggestionsCapability.recordFeedbackResult(context, mapped)
                        Log.i(tag, "Suggestions Kit event result=$resultCode")
                        callback(mapped)
                    }
                },
            )
            if (!accepted && completed.compareAndSet(false, true)) {
                Log.w(tag, "Suggestions Kit rejected event submission")
                callback(HonorFeedbackResult.FAILED)
            }
        } catch (error: Throwable) {
            Log.w(tag, "Suggestions Kit event feedback failed (${error.javaClass.simpleName})")
            callback(HonorFeedbackResult.SERVICE_ERROR)
        }
    }

    private fun recordResult(
        preferences: android.content.SharedPreferences,
        oldState: HonorFeedbackGate.State,
        key: String,
        result: HonorFeedbackResult,
    ) {
        val next = HonorFeedbackGate.afterResult(oldState, key, result, System.currentTimeMillis())
        preferences.edit()
            .putString(keyLastSuccessful, next.lastSuccessfulKey)
            .putLong(keyLastSuccessfulAt, next.lastSuccessfulAtMillis)
            .putLong(keyBlockedUntil, next.blockedUntilMillis)
            .apply()
    }
}

/** Local duplicate/rate-limit gate; 60 seconds is an app safety backoff, not an HONOR SLA. */
internal object HonorFeedbackGate {
    const val flowBackoffMillis = 60_000L

    data class State(
        val lastSuccessfulKey: String? = null,
        val lastSuccessfulAtMillis: Long = 0L,
        val blockedUntilMillis: Long = 0L,
    )

    fun eventKey(event: HonorSuggestionsMapper.Event): String =
        "${event.eventId}:${event.phase.name}"

    fun shouldDispatch(state: State, key: String, nowMillis: Long): Boolean =
        state.lastSuccessfulKey != key && nowMillis >= state.blockedUntilMillis

    fun afterResult(
        state: State,
        key: String,
        result: HonorFeedbackResult,
        nowMillis: Long,
    ): State = when (result) {
        HonorFeedbackResult.SUCCESS -> State(
            lastSuccessfulKey = key,
            lastSuccessfulAtMillis = nowMillis,
            blockedUntilMillis = state.blockedUntilMillis,
        )
        HonorFeedbackResult.RATE_LIMITED -> state.copy(
            blockedUntilMillis = maxOf(state.blockedUntilMillis, nowMillis + flowBackoffMillis),
        )
        else -> state
    }
}
