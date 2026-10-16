package com.example.yanji.ongoing

import android.content.Context
import com.example.yanji.StudyLiveActivityBridge
import com.example.yanji.ongoing.honor.HonorMagicCapsuleAdapter
import com.example.yanji.ongoing.oppo.OppoFluidCloudManager
import com.example.yanji.ongoing.xiaomi.XiaomiSuperIslandManager

/** Dispatches one vendor adapter and preserves YANJI's existing Android fallback. */
internal object AndroidOngoingActivityManager {
    fun synchronize(
        context: Context,
        state: OngoingActivityState,
        callback: () -> Unit = {},
    ) {
        OppoFluidCloudManager.synchronize(context, state) { fluidCloudHandled ->
            if (fluidCloudHandled) {
                StudyLiveActivityBridge.cancelCurrentNotification(context)
                callback()
            } else if (XiaomiSuperIslandManager.isPotentialDevice()) {
                if (!state.isOngoing) {
                    XiaomiSuperIslandManager.end(context)
                    StudyLiveActivityBridge.cancelCurrentNotification(context)
                    callback()
                } else {
                    XiaomiSuperIslandManager.synchronize(context, state) { xiaomiHandled ->
                        if (!xiaomiHandled) publishFallback(context, state)
                        callback()
                    }
                }
            } else {
                HonorMagicCapsuleAdapter.synchronize(context, state) { honorHandled ->
                    if (honorHandled) {
                        StudyLiveActivityBridge.cancelCurrentNotification(context)
                    } else {
                        publishFallback(context, state)
                    }
                    callback()
                }
            }
        }
    }

    private fun publishFallback(context: Context, state: OngoingActivityState) {
        if (!state.isOngoing) {
            StudyLiveActivityBridge.cancelCurrentNotification(context)
        } else {
            StudyLiveActivityBridge.requestNotificationPermissionIfNeeded(context)
            StudyLiveActivityBridge.publishCurrent(context)
        }
    }
}
