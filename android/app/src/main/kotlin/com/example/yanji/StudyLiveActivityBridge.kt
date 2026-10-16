package com.example.yanji

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import com.example.yanji.ongoing.AndroidOngoingActivityManager
import com.example.yanji.ongoing.OngoingActivityState
import com.example.yanji.ongoing.honor.HonorMagicCapsuleAdapter
import com.example.yanji.ongoing.honor.HonorSuggestionsCapability
import com.example.yanji.ongoing.oppo.OppoFluidCloudManager
import com.example.yanji.ongoing.oppo.OppoFluidCloudConfig
import com.example.yanji.ongoing.xiaomi.XiaomiFocusKeys
import com.example.yanji.ongoing.xiaomi.XiaomiSuperIslandManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object StudyLiveActivityBridge {
    private const val channelName = "com.example.yanji/study_live_activity"
    private const val notificationChannelId = "study_timer_live"
    internal const val notificationId = 2401
    private const val promotedOngoingExtra = "android.requestPromotedOngoing"
    private const val maximumStudySeconds = 8 * 60 * 60
    private const val preferencesName = "study_live_activity"
    private const val actionPause = "com.example.yanji.live.PAUSE"
    private const val actionResume = "com.example.yanji.live.RESUME"
    const val extraAction = "study_live_activity_action"
    const val notificationPermissionRequestCode = 2402

    private const val keySessionId = "session_id"
    private const val keySubject = "subject"
    private const val keyStatus = "status"
    private const val keyElapsedSeconds = "elapsed_seconds"
    private const val keyTodayTotalSeconds = "today_total_seconds"
    private const val keyTargetSeconds = "target_seconds"
    private const val keyDoNotDisturbEnabled = "do_not_disturb_enabled"
    private const val keyReferenceRealtime = "reference_realtime"
    private const val keyPendingAction = "pending_action"
    private const val keyNotificationPermissionRequested =
        "notification_permission_requested"

    fun register(activity: Activity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sync" -> {
                        sync(activity, call)
                        result.success(null)
                    }
                    "consumePendingAction" -> {
                        val preferences = preferences(activity)
                        val action = preferences.getString(keyPendingAction, null)
                        preferences.edit().remove(keyPendingAction).apply()
                        result.success(action)
                    }
                    "currentActivityState" -> result.success(currentState(activity))
                    "checkOppoFluidCloudSupport" -> OppoFluidCloudManager.checkCapability(activity) {
                        result.success(it.toMap())
                    }
                    "debugOppoFluidCloud" -> debugOppoFluidCloud(activity, call, result)
                    "checkXiaomiFocusSupport" ->
                        XiaomiSuperIslandManager.checkCapability(activity, forceRefresh = true) {
                            result.success(it.toMap())
                        }
                    "debugXiaomiSuperIsland" -> {
                        val action = call.argument<String>("action") ?: ""
                        XiaomiSuperIslandManager.debug(activity, action) { result.success(it) }
                    }
                    "checkHonorMagicCapsuleSupport" ->
                        HonorMagicCapsuleAdapter.isSupported(activity) { result.success(it.toMap()) }
                    "setHonorSuggestionsConsent" -> {
                        val granted = call.argument<Boolean>("granted") ?: false
                        HonorSuggestionsCapability.setDataFeedbackConsent(activity, granted)
                        result.success(granted)
                    }
                    "debugHonorMagicCapsule" -> debugHonorMagicCapsule(activity, call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun sync(context: Context, call: MethodCall) {
        val sessionId = call.argument<String>("sessionId")
        val status = call.argument<String>("status") ?: "finished"
        if (sessionId == null || status == "finished") {
            val existing = readState(context)
            val terminalState = if (sessionId != null) {
                stateFromCall(call, sessionId, "finished")
            } else {
                existing?.toOngoingState("finished")
            }
            if (terminalState != null) AndroidOngoingActivityManager.synchronize(context, terminalState)
            clearNativeState(context)
            cancelCurrentNotification(context)
            return
        }

        val state = stateFromCall(call, sessionId, status)
        preferences(context).edit()
            .putString(keySessionId, sessionId)
            .putString(keySubject, state.subject)
            .putString(keyStatus, status)
            .putLong(keyElapsedSeconds, state.elapsedSeconds)
            .putLong(keyTodayTotalSeconds, state.todayTotalSeconds)
            .putLong(keyTargetSeconds, state.targetSeconds)
            .putBoolean(keyDoNotDisturbEnabled, state.doNotDisturbEnabled)
            .putLong(keyReferenceRealtime, SystemClock.elapsedRealtime())
            .apply()

        AndroidOngoingActivityManager.synchronize(context, state)
    }

    internal fun publishCurrent(
        context: Context,
        focusPayload: String? = null,
        timeoutAfterMillis: Long? = null,
    ): Boolean {
        val state = readState(context) ?: return false
        if (!canPostNotifications(context)) return false
        val channelId = if (focusPayload == null) {
            notificationChannelId
        } else {
            XiaomiFocusKeys.CHANNEL_ID
        }
        createNotificationChannel(context, focusPayload != null)
        val notification = buildNotification(
            context = context,
            state = state,
            channelId = channelId,
            timeoutAfterMillis = timeoutAfterMillis,
        )
        if (focusPayload != null) {
            notification.extras.putString(XiaomiFocusKeys.PARAM, focusPayload)
        }
        notificationManager(context).notify(notificationId, notification)
        return true
    }

    internal fun synchronizeCurrent(context: Context, callback: () -> Unit = {}) {
        val state = readState(context)
        if (state == null) {
            callback()
            return
        }
        AndroidOngoingActivityManager.synchronize(context, state.toOngoingState(), callback)
    }

    internal fun cancelCurrentNotification(context: Context) {
        notificationManager(context).cancel(notificationId)
    }

    internal fun requestNotificationPermissionIfNeeded(context: Context) {
        ensureNotificationPermission(context)
    }

    fun storePendingAction(context: Context, action: String) {
        if (action !in setOf("open", "pause", "resume", "finish")) return
        preferences(context).edit().putString(keyPendingAction, action).apply()
    }

    /** Captures the shared yanji://live-activity/open link at cold and warm launch. */
    fun captureLaunchIntent(context: Context, source: Intent?) {
        source ?: return
        val notificationAction = source.getStringExtra(extraAction)
        val uri = source.data
        val deepLinkAction = if (
            uri?.scheme.equals("yanji", ignoreCase = true) &&
            uri?.host.equals("live-activity", ignoreCase = true)
        ) {
            uri?.pathSegments?.firstOrNull()
        } else {
            null
        }
        val action = notificationAction ?: deepLinkAction
        if (action != null) storePendingAction(context, action)
        source.removeExtra(extraAction)
    }

    fun handleToggle(context: Context, pause: Boolean, callback: () -> Unit = {}) {
        val state = readState(context) ?: run {
            callback()
            return
        }
        val elapsed = elapsedSeconds(state)
        val nextStatus = if (pause) "paused" else "active"
        preferences(context).edit()
            .putString(keyStatus, nextStatus)
            .putLong(keyElapsedSeconds, elapsed)
            .putLong(keyReferenceRealtime, SystemClock.elapsedRealtime())
            .putString(keyPendingAction, if (pause) "pause" else "resume")
            .apply()
        val updated = readState(context)
        if (updated == null) callback()
        else AndroidOngoingActivityManager.synchronize(
            context,
            updated.toOngoingState(),
            callback,
        )
    }

    private fun currentState(context: Context): Map<String, Any>? {
        val state = readState(context) ?: return null
        return mapOf(
            "status" to state.status,
            "elapsedSeconds" to elapsedSeconds(state),
            "capturedAtMs" to System.currentTimeMillis(),
        )
    }

    private fun stateFromCall(call: MethodCall, sessionId: String, status: String) =
        OngoingActivityState(
            sessionId = sessionId,
            subject = call.argument<String>("subject") ?: "自由学习",
            status = status,
            elapsedSeconds = call.argument<Number>("elapsedSeconds")?.toLong() ?: 0L,
            todayTotalSeconds = call.argument<Number>("todayTotalSeconds")?.toLong() ?: 0L,
            targetSeconds = call.argument<Number>("targetSeconds")?.toLong() ?: 0L,
            doNotDisturbEnabled = call.argument<Boolean>("doNotDisturbEnabled") ?: false,
        )

    private fun debugOppoFluidCloud(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (!BuildConfig.DEBUG) {
            result.error("debug_only", "Debug controls are disabled in release builds", null)
            return
        }
        val action = call.argument<String>("action") ?: ""
        val sessionId = "yanji-debug-fluid-cloud"
        if (action == "cancel" || action == "remove") {
            OppoFluidCloudManager.removeForDebug(context, sessionId) { removed ->
                result.success(mapOf("dispatched" to removed, "configured" to OppoFluidCloudConfig.isConfigured))
            }
            return
        }
        val status = when (action) {
            "pause" -> "paused"
            "resume", "create", "update", "progress" -> "active"
            "complete" -> "finished"
            else -> {
                result.error("invalid_action", "Unknown OPPO debug action", null)
                return
            }
        }
        val elapsed = when (action) {
            "update" -> 30L
            "progress" -> 60L
            else -> 0L
        }
        val state = OngoingActivityState(
            sessionId = sessionId,
            subject = "流体云调试",
            status = status,
            elapsedSeconds = elapsed,
            todayTotalSeconds = elapsed,
            targetSeconds = 0,
            doNotDisturbEnabled = false,
        )
        OppoFluidCloudManager.synchronize(context, state) { dispatched ->
            result.success(
                mapOf(
                    "dispatched" to dispatched,
                    "configured" to OppoFluidCloudConfig.isConfigured,
                    "status" to status,
                ),
            )
        }
    }

    private fun debugHonorMagicCapsule(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (!BuildConfig.DEBUG) {
            result.error("debug_only", "Debug controls are disabled in release builds", null)
            return
        }
        val action = call.argument<String>("action") ?: ""
        val status = when (action) {
            "start", "update", "resume", "restore" -> "active"
            "pause" -> "paused"
            "complete", "cancel" -> "finished"
            else -> {
                result.error("invalid_action", "Unknown HONOR debug action", null)
                return
            }
        }
        val elapsed = when (action) {
            "update" -> 30L
            "restore" -> 60L
            else -> 0L
        }
        val state = OngoingActivityState(
            sessionId = "yanji-debug-honor-session",
            subject = "数据结构复习",
            status = status,
            elapsedSeconds = elapsed,
            todayTotalSeconds = elapsed,
            targetSeconds = 0,
            doNotDisturbEnabled = false,
        )
        HonorSuggestionsCapability.check(context) { report ->
            HonorMagicCapsuleAdapter.synchronize(context, state) { dispatched ->
                result.success(
                    mapOf(
                        "action" to action,
                        "dispatched" to dispatched,
                        "runtimeConfigured" to BuildConfig.HONOR_SUGGESTIONS_RUNTIME_CONFIGURED,
                        "capability" to report.toMap(),
                    ),
                )
            }
        }
    }

    private fun buildNotification(
        context: Context,
        state: NativeState,
        channelId: String = notificationChannelId,
        timeoutAfterMillis: Long? = null,
    ): Notification {
        val active = state.status == "active"
        val elapsed = elapsedSeconds(state)
        val openIntent = activityPendingIntent(context, "open", 10)
        val toggleIntent = PendingIntent.getBroadcast(
            context,
            11,
            Intent(context, StudyLiveActivityActionReceiver::class.java).setAction(
                if (active) actionPause else actionResume,
            ).addFlags(Intent.FLAG_RECEIVER_FOREGROUND),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val finishIntent = activityPendingIntent(context, "finish", 12)

        val builder = Notification.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_study_notification)
            .setContentTitle(state.subject)
            .setContentText(if (active) "学习中" else "已暂停 · ${formatDuration(elapsed)}")
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setLocalOnly(false)
            .addAction(0, if (active) "暂停" else "继续", toggleIntent)
            .addAction(0, "结束", finishIntent)

        if (timeoutAfterMillis != null && Build.VERSION.SDK_INT >= 26) {
            builder.setTimeoutAfter(timeoutAfterMillis)
        }

        // Android 16 can render a progress-centric Live Update on the lock
        // screen, status bar and notification shade. A study session is a
        // user-started, finite activity for this purpose; cap the visual
        // journey at the same eight-hour limit as the persisted timer.
        if (Build.VERSION.SDK_INT >= 36) {
            val progress = elapsed.coerceAtMost(maximumStudySeconds.toLong()).toInt()
            val progressStyle = Notification.ProgressStyle()
                .setStyledByProgress(false)
                .setProgress(progress)
                .setProgressSegments(
                    listOf(
                        Notification.ProgressStyle.Segment(maximumStudySeconds)
                            .setColor(0xFF356F5A.toInt()),
                    ),
                )
            builder.setStyle(progressStyle)
        }

        if (active) {
            builder
                .setWhen(System.currentTimeMillis() - elapsed * 1000)
                .setShowWhen(true)
                .setUsesChronometer(true)
                .setChronometerCountDown(false)
        } else {
            builder.setShowWhen(false)
            if (Build.VERSION.SDK_INT >= 36) builder.setShortCriticalText("已暂停")
        }

        val notification = builder.build()
        if (Build.VERSION.SDK_INT >= 36) {
            notification.extras.putBoolean(promotedOngoingExtra, true)
        }
        return notification
    }

    private fun activityPendingIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse("yanji://live-activity/open"))
            .putExtra(extraAction, action)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun readState(context: Context): NativeState? {
        val values = preferences(context)
        val sessionId = values.getString(keySessionId, null) ?: return null
        return NativeState(
            sessionId = sessionId,
            subject = values.getString(keySubject, "自由学习") ?: "自由学习",
            status = values.getString(keyStatus, "active") ?: "active",
            elapsedSeconds = values.getLong(keyElapsedSeconds, 0),
            referenceRealtime = values.getLong(keyReferenceRealtime, SystemClock.elapsedRealtime()),
            todayTotalSeconds = values.getLong(keyTodayTotalSeconds, 0),
            targetSeconds = values.getLong(keyTargetSeconds, 0),
            doNotDisturbEnabled = values.getBoolean(keyDoNotDisturbEnabled, false),
        )
    }

    private fun elapsedSeconds(state: NativeState): Long {
        if (state.status != "active") return state.elapsedSeconds.coerceIn(0, maximumStudySeconds.toLong())
        val added = (SystemClock.elapsedRealtime() - state.referenceRealtime).coerceAtLeast(0) / 1000
        return (state.elapsedSeconds + added).coerceIn(0, maximumStudySeconds.toLong())
    }

    private fun formatDuration(seconds: Long): String = when {
        seconds < 60 -> "${seconds}秒"
        else -> "${seconds / 60}分钟"
    }

    private fun ensureNotificationPermission(context: Context) {
        if (
            Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED &&
            context is Activity &&
            !preferences(context).getBoolean(keyNotificationPermissionRequested, false)
        ) {
            // A denied notification permission must not cause a prompt on every
            // later activity sync. Users can grant it from system settings.
            preferences(context).edit()
                .putBoolean(keyNotificationPermissionRequested, true)
                .apply()
            context.requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                notificationPermissionRequestCode,
            )
        }
    }

    private fun canPostNotifications(context: Context): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    private fun createNotificationChannel(context: Context, xiaomiFocus: Boolean = false) {
        if (Build.VERSION.SDK_INT < 26) return
        val channelId = if (xiaomiFocus) XiaomiFocusKeys.CHANNEL_ID else notificationChannelId
        val channel = NotificationChannel(
            channelId,
            "学习计时",
            if (xiaomiFocus) NotificationManager.IMPORTANCE_DEFAULT else NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "显示正在进行的学习计时和快捷操作"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        notificationManager(context).createNotificationChannel(channel)
    }

    private fun preferences(context: Context) =
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    private fun clearNativeState(context: Context) {
        preferences(context).edit()
            .remove(keySessionId)
            .remove(keySubject)
            .remove(keyStatus)
            .remove(keyElapsedSeconds)
            .remove(keyTodayTotalSeconds)
            .remove(keyTargetSeconds)
            .remove(keyDoNotDisturbEnabled)
            .remove(keyReferenceRealtime)
            .apply()
    }

    private fun notificationManager(context: Context) =
        context.getSystemService(NotificationManager::class.java)

    private data class NativeState(
        val sessionId: String,
        val subject: String,
        val status: String,
        val elapsedSeconds: Long,
        val referenceRealtime: Long,
        val todayTotalSeconds: Long,
        val targetSeconds: Long,
        val doNotDisturbEnabled: Boolean,
    ) {
        fun toOngoingState(terminalStatus: String = status) = OngoingActivityState(
            sessionId = sessionId,
            subject = subject,
            status = terminalStatus,
            elapsedSeconds = this@StudyLiveActivityBridge.elapsedSeconds(this),
            todayTotalSeconds = todayTotalSeconds,
            targetSeconds = targetSeconds,
            doNotDisturbEnabled = doNotDisturbEnabled,
        )
    }
}

class StudyLiveActivityActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "com.example.yanji.live.PAUSE" -> {
                val pendingResult = goAsync()
                StudyLiveActivityBridge.handleToggle(context, true) { pendingResult.finish() }
            }
            "com.example.yanji.live.RESUME" -> {
                val pendingResult = goAsync()
                StudyLiveActivityBridge.handleToggle(context, false) { pendingResult.finish() }
            }
        }
    }
}
