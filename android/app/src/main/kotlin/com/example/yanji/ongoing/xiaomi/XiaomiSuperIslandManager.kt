package com.example.yanji.ongoing.xiaomi

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import com.example.yanji.BuildConfig
import com.example.yanji.MainActivity
import com.example.yanji.R
import com.example.yanji.StudyLiveActivityBridge
import com.example.yanji.ongoing.OngoingActivityState
import org.json.JSONObject
import java.util.concurrent.Executors

/** Xiaomi-only capability checks and notification adapter. */
internal object XiaomiSuperIslandManager {
    private const val tag = "YANJI.XiaomiSuperIsland"
    private const val cacheMillis = 60_000L
    private const val debugNotificationId = 2403
    private const val preferencesName = "xiaomi_super_island"
    private const val keyLastActivityId = "last_activity_id"
    private const val keyLastPayload = "last_payload_signature"

    private val executor = Executors.newSingleThreadExecutor()
    private val lock = Any()
    private val waiters = mutableListOf<(Capability) -> Unit>()

    @Volatile
    private var cached: Capability? = null
    @Volatile
    private var cachedAtMillis = 0L
    private var inFlight = false

    internal data class Capability(
        val manufacturer: String,
        val brand: String,
        val xiaomiFamilyCandidate: Boolean,
        val protocolVersion: Int,
        val islandFeatureSupported: Boolean,
        val androidNotificationPermission: Boolean,
        val focusPermission: Boolean,
        val businessConfigured: Boolean,
        val supported: Boolean,
        val selectedAdapter: String,
        val notificationId: Int,
        val activityId: String,
        val reason: String,
        val error: String = "",
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "manufacturer" to manufacturer,
            "brand" to brand,
            "xiaomiFamilyCandidate" to xiaomiFamilyCandidate,
            "protocolVersion" to protocolVersion,
            "islandFeatureSupported" to islandFeatureSupported,
            "androidNotificationPermission" to androidNotificationPermission,
            "focusPermission" to focusPermission,
            "businessConfigured" to businessConfigured,
            "supported" to supported,
            "selectedAdapter" to selectedAdapter,
            "notificationId" to notificationId,
            "activityId" to activityId,
            "reason" to reason,
            "error" to error,
        )
    }

    fun checkCapability(context: Context, forceRefresh: Boolean = false, callback: (Capability) -> Unit) {
        val appContext = context.applicationContext
        val now = System.currentTimeMillis()
        val value = cached
        if (!forceRefresh && value != null && now - cachedAtMillis < cacheMillis) {
            callback(value)
            return
        }

        synchronized(lock) {
            val stillFresh = cached
            if (!forceRefresh && stillFresh != null &&
                System.currentTimeMillis() - cachedAtMillis < cacheMillis
            ) {
                callback(stillFresh)
                return
            }
            waiters.add(callback)
            if (inFlight) return
            inFlight = true
            if (forceRefresh) cached = null
        }

        executor.execute {
            val capability = try {
                detectCapability(appContext)
            } catch (error: Throwable) {
                Log.w(tag, "Capability check failed (${error.javaClass.simpleName})")
                unavailableCapability(error.javaClass.simpleName)
            }
            val callbacks: List<(Capability) -> Unit>
            synchronized(lock) {
                cached = capability
                cachedAtMillis = System.currentTimeMillis()
                inFlight = false
                callbacks = waiters.toList()
                waiters.clear()
            }
            Log.i(
                tag,
                "Capability protocol=${capability.protocolVersion}, " +
                    "island=${capability.islandFeatureSupported}, " +
                    "notifications=${capability.androidNotificationPermission}, " +
                    "focus=${capability.focusPermission}, " +
                    "supported=${capability.supported}",
            )
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                callbacks.forEach { it(capability) }
            }
        }
    }

    fun isPotentialDevice(): Boolean =
        isXiaomiFamily(Build.MANUFACTURER, Build.BRAND)

    fun invalidateCapability() {
        synchronized(lock) {
            cached = null
            cachedAtMillis = 0L
        }
    }

    fun synchronize(
        context: Context,
        state: OngoingActivityState,
        callback: (Boolean) -> Unit,
    ) {
        val sessionId = state.sessionId?.takeIf(String::isNotBlank)
        if (!state.isOngoing || sessionId == null) {
            cancel(context)
            callback(false)
            return
        }
        if (!XiaomiFocusConfig.isConfigured) {
            Log.i(tag, "Skipped Xiaomi focus payload: Xiaomi has not approved a business scene")
            callback(false)
            return
        }

        checkCapability(context) { capability ->
            if (!capability.supported || !capability.businessConfigured) {
                Log.i(tag, "Xiaomi adapter unavailable: ${capability.reason}")
                callback(false)
                return@checkCapability
            }
            val payload = XiaomiSuperIslandMapper.map(
                state = state,
                protocolVersion = capability.protocolVersion,
                approvedBusiness = XiaomiFocusConfig.business,
            )
            if (payload == null) {
                Log.i(tag, "Payload omitted for an unsupported state or expired 12-hour lifetime")
                callback(false)
                return@checkCapability
            }
            val signature = payloadSignature(state, payload.json)
            val preferences = context.applicationContext.getSharedPreferences(
                preferencesName,
                Context.MODE_PRIVATE,
            )
            val activeNotification = notificationManager(context).activeNotifications
                .firstOrNull { it.id == StudyLiveActivityBridge.notificationId }
            val postedSignature = activeNotification
                ?.notification
                ?.extras
                ?.getString(XiaomiFocusKeys.PARAM)
                ?.let(::displayedPayloadSignature)
            if (preferences.getString(keyLastPayload, null) == signature &&
                postedSignature == displayedPayloadSignature(payload.json)
            ) {
                callback(true)
                return@checkCapability
            }

            val posted = StudyLiveActivityBridge.publishCurrent(
                context = context,
                focusPayload = payload.json,
                timeoutAfterMillis = payload.notificationTimeoutMillis,
            )
            if (posted) {
                preferences.edit()
                    .putString(keyLastActivityId, sessionId)
                    .putString(keyLastPayload, signature)
                    .apply()
                if (BuildConfig.DEBUG) Log.d(tag, "Payload updated (${payload.json.length} chars)")
                else Log.i(tag, "Focus notification updated for the current study session")
            }
            callback(posted)
        }
    }

    fun end(context: Context) {
        cancel(context)
    }

    fun debug(
        context: Context,
        action: String,
        callback: (Map<String, Any>) -> Unit,
    ) {
        if (!BuildConfig.DEBUG) {
            callback(mapOf("dispatched" to false, "reason" to "debug_only"))
            return
        }
        if (action == "cancel") {
            cancelDebug(context)
            callback(mapOf("dispatched" to true, "status" to "cancelled"))
            return
        }
        if (!XiaomiFocusConfig.isConfigured) {
            callback(
                mapOf(
                    "dispatched" to false,
                    "reason" to "business_not_approved",
                    "configured" to false,
                ),
            )
            return
        }
        checkCapability(context) { capability ->
            if (!capability.supported) {
                callback(mapOf("dispatched" to false, "reason" to capability.reason))
                return@checkCapability
            }
            val elapsed = when (action) {
                "update" -> 30L
                "progress" -> 60L
                else -> 0L
            }
            val status = when (action) {
                "pause" -> "paused"
                "complete" -> "finished"
                "create", "update", "progress", "resume" -> "active"
                else -> {
                    callback(mapOf("dispatched" to false, "reason" to "invalid_action"))
                    return@checkCapability
                }
            }
            if (status == "finished") {
                cancelDebug(context)
                callback(mapOf("dispatched" to true, "status" to "finished"))
                return@checkCapability
            }
            val state = OngoingActivityState(
                sessionId = "yanji-debug-xiaomi",
                subject = "数据结构复习",
                status = status,
                elapsedSeconds = elapsed,
                todayTotalSeconds = elapsed,
                targetSeconds = 0,
                doNotDisturbEnabled = false,
            )
            val payload = XiaomiSuperIslandMapper.map(
                state,
                capability.protocolVersion,
                XiaomiFocusConfig.business,
            )
            if (payload == null) {
                callback(mapOf("dispatched" to false, "reason" to "payload_unavailable"))
                return@checkCapability
            }
            createChannel(context)
            val notification = Notification.Builder(
                context,
                XiaomiFocusKeys.CHANNEL_ID,
            )
                .setSmallIcon(R.drawable.ic_study_notification)
                .setContentTitle(if (status == "paused") "已暂停" else "学习中")
                .setContentText(state.subject)
                .setCategory(Notification.CATEGORY_STOPWATCH)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setContentIntent(openPendingIntent(context, debugNotificationId))
                .setTimeoutAfter(payload.notificationTimeoutMillis)
                .build()
            notification.extras.putString(XiaomiFocusKeys.PARAM, payload.json)
            notificationManager(context).notify(debugNotificationId, notification)
            callback(
                mapOf(
                    "dispatched" to true,
                    "status" to status,
                    "notificationId" to debugNotificationId,
                    "protocolVersion" to capability.protocolVersion,
                ),
            )
        }
    }

    private fun detectCapability(context: Context): Capability {
        val manufacturer = Build.MANUFACTURER
        val brand = Build.BRAND
        val familyCandidate = isXiaomiFamily(manufacturer, brand)
        val protocol = runCatching {
            Settings.System.getInt(
                context.contentResolver,
                XiaomiFocusKeys.SYSTEM_PROTOCOL_SETTING,
                0,
            )
        }.getOrDefault(0)
        val islandSupported = readSystemPropertyBoolean("persist.sys.feature.island")
        val notificationPermission = Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        // canShowFocus crosses into SystemUI and can block. This method is only
        // called by the single-thread executor, never from a Flutter frame.
        val focusPermission = if (familyCandidate && protocol in 2..3) {
            hasFocusPermission(context)
        } else {
            false
        }
        val supported = familyCandidate &&
            protocol in 2..3 &&
            (protocol != XiaomiSuperIslandMapper.HYPEROS_3 || islandSupported) &&
            notificationPermission &&
            focusPermission
        val reason = when {
            !familyCandidate -> "not_xiaomi_family"
            protocol !in 2..3 -> "focus_protocol_unavailable"
            protocol == XiaomiSuperIslandMapper.HYPEROS_3 && !islandSupported ->
                "super_island_feature_unavailable"
            !notificationPermission -> "android_notification_permission_denied"
            !focusPermission -> "xiaomi_focus_permission_denied"
            !XiaomiFocusConfig.isConfigured -> "business_not_approved"
            else -> "ready"
        }
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        return Capability(
            manufacturer = manufacturer,
            brand = brand,
            xiaomiFamilyCandidate = familyCandidate,
            protocolVersion = protocol,
            islandFeatureSupported = islandSupported,
            androidNotificationPermission = notificationPermission,
            focusPermission = focusPermission,
            businessConfigured = XiaomiFocusConfig.isConfigured,
            supported = supported,
            selectedAdapter = when {
                !supported || !XiaomiFocusConfig.isConfigured -> "android_notification_fallback"
                protocol == XiaomiSuperIslandMapper.HYPEROS_3 -> "xiaomi_super_island"
                else -> "xiaomi_focus_notification"
            },
            notificationId = StudyLiveActivityBridge.notificationId,
            activityId = preferences.getString(keyLastActivityId, "").orEmpty(),
            reason = reason,
        )
    }

    private fun unavailableCapability(error: String) = Capability(
        manufacturer = Build.MANUFACTURER,
        brand = Build.BRAND,
        xiaomiFamilyCandidate = isXiaomiFamily(Build.MANUFACTURER, Build.BRAND),
        protocolVersion = 0,
        islandFeatureSupported = false,
        androidNotificationPermission = false,
        focusPermission = false,
        businessConfigured = XiaomiFocusConfig.isConfigured,
        supported = false,
        selectedAdapter = "android_notification_fallback",
        notificationId = StudyLiveActivityBridge.notificationId,
        activityId = "",
        reason = "capability_check_failed",
        error = error,
    )

    private fun isXiaomiFamily(manufacturer: String, brand: String): Boolean {
        val values = listOf(manufacturer, brand).map { it.trim().lowercase() }
        return values.any { it == "xiaomi" || it == "redmi" || it == "poco" }
    }

    private fun readSystemPropertyBoolean(name: String): Boolean = runCatching {
        val type = Class.forName("android.os.SystemProperties")
        val getter = type.getDeclaredMethod(
            "getBoolean",
            String::class.java,
            Boolean::class.javaPrimitiveType,
        )
        getter.invoke(null, name, false) as? Boolean ?: false
    }.getOrDefault(false)

    private fun hasFocusPermission(context: Context): Boolean = runCatching {
        val extras = Bundle().apply { putString("package", context.packageName) }
        context.contentResolver.call(
            Uri.parse(XiaomiFocusKeys.FOCUS_PERMISSION_URI),
            XiaomiFocusKeys.FOCUS_PERMISSION_METHOD,
            null,
            extras,
        )?.getBoolean("canShowFocus", false) ?: false
    }.getOrDefault(false)

    private fun payloadSignature(state: OngoingActivityState, json: String): String =
        listOf(
            state.sessionId.orEmpty(),
            state.status,
            displayedPayloadSignature(json),
        ).joinToString("|")

    private fun displayedPayloadSignature(json: String): String? = runCatching {
        val root = JSONObject(json)
        val param = root.getJSONObject("param_v2")
        param.remove("timeout")
        if (param.has("param_island")) {
            param.getJSONObject("param_island").remove("islandTimeout")
        }
        root.toString()
    }.getOrNull()

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val channel = NotificationChannel(
            XiaomiFocusKeys.CHANNEL_ID,
            "学习计时",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "显示用户主动开始的学习计时状态"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        notificationManager(context).createNotificationChannel(channel)
    }

    private fun cancel(context: Context) {
        notificationManager(context).cancel(StudyLiveActivityBridge.notificationId)
        context.applicationContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .remove(keyLastPayload)
            .remove(keyLastActivityId)
            .apply()
        Log.i(tag, "Current Xiaomi focus notification cancelled")
    }

    private fun cancelDebug(context: Context) {
        notificationManager(context).cancel(debugNotificationId)
    }

    private fun notificationManager(context: Context) =
        context.getSystemService(NotificationManager::class.java)

    private fun openPendingIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse("yanji://live-activity/open"))
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            .putExtra(StudyLiveActivityBridge.extraAction, "open")
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
