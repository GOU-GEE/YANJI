package com.example.yanji.ongoing.honor

import android.content.Context
import android.util.Log
import com.example.yanji.BuildConfig
import com.example.yanji.ongoing.OngoingActivityState

/**
 * HONOR adapter seam for the unified Android ongoing-session manager.
 *
 * The public Suggestions Kit contract only documents event start/end. It does
 * not define the YANJI learning scene or generic live progress/pause/resume
 * updates. Dispatch therefore remains disabled until all portal, privacy and
 * state-schema gates are supplied; the existing Android notification remains
 * the truthful fallback in the meantime.
 */
internal object HonorMagicCapsuleAdapter {
    private const val tag = "YANJI.HonorMagicCapsule"

    fun isSupported(context: Context, callback: (HonorSuggestionsCapability.Report) -> Unit) {
        HonorSuggestionsCapability.check(context, callback)
    }

    /**
     * Mirrors the unified manager lifecycle without creating a second business
     * state machine. The `false` result asks AndroidOngoingActivityManager to
     * keep/update the existing ordinary ongoing notification.
     */
    fun synchronize(
        context: Context,
        state: OngoingActivityState,
        callback: (Boolean) -> Unit,
    ) {
        HonorSuggestionsCapability.check(context) { report ->
            if (!report.fullLifecycleReady || !BuildConfig.HONOR_SUGGESTIONS_RUNTIME_CONFIGURED) {
                Log.i(tag, "capability unavailable; preserving Android fallback")
                callback(false)
                return@check
            }

            // A fully approved scene-specific mapper must be added after HONOR
            // confirms the payload schema for progress/pause/resume. Sending only
            // an Event start/end here would leave the system surface stale.
            val semanticState = HonorSuggestionsMapper.displayState(state)
            if (semanticState == null) {
                callback(false)
                return@check
            }
            Log.i(tag, "approved state schema is not implemented; preserving Android fallback")
            callback(false)
        }
    }

    fun start(context: Context, state: OngoingActivityState, callback: (Boolean) -> Unit) =
        synchronize(context, state, callback)

    fun update(context: Context, state: OngoingActivityState, callback: (Boolean) -> Unit) =
        synchronize(context, state, callback)

    fun pause(context: Context, state: OngoingActivityState, callback: (Boolean) -> Unit) =
        synchronize(context, state, callback)

    fun resume(context: Context, state: OngoingActivityState, callback: (Boolean) -> Unit) =
        synchronize(context, state, callback)

    fun complete(context: Context, state: OngoingActivityState, callback: (Boolean) -> Unit) =
        synchronize(context, state, callback)

    fun cancel(context: Context, state: OngoingActivityState, callback: (Boolean) -> Unit) =
        synchronize(context, state, callback)

    fun restore(context: Context, state: OngoingActivityState, callback: (Boolean) -> Unit) =
        synchronize(context, state, callback)
}
