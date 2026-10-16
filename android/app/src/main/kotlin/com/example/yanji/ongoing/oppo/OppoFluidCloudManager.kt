package com.example.yanji.ongoing.oppo

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.example.yanji.ongoing.OngoingActivityState
import com.oplus.pantanal.seedling.bean.SeedlingCard
import com.oplus.pantanal.seedling.intelligent.IntelligentData
import com.oplus.pantanal.seedling.update.SeedlingCardOptions
import com.oplus.pantanal.seedling.util.SeedlingTool
import org.json.JSONObject
import java.util.concurrent.Executors

/** OPPO-only adapter. No vendor SDK call is made on the Flutter/UI thread. */
internal object OppoFluidCloudManager {
    private const val tag = "YANJI.OPPOFluidCloud"
    private const val preferencesName = "oppo_fluid_cloud"
    private const val keyCurrentSession = "current_session"
    private const val keyCurrentStatus = "current_status"
    private const val keyCurrentData = "current_data"
    private const val keyLastDispatch = "last_dispatch"
    private const val keyDismissedSession = "dismissed_session"

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val lock = Any()
    private val capabilityWaiters = mutableListOf<(Capability) -> Unit>()

    @Volatile
    private var cachedCapability: Capability? = null
    private var capabilityCheckInFlight = false

    internal data class Capability(
        val manufacturer: String,
        val brand: String,
        val isOppoDevice: Boolean,
        val seedlingSupported: Boolean,
        val systemIntentSupported: Boolean,
        val fluidCloudSupported: Boolean,
        val appConfigured: Boolean,
        val error: String? = null,
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "manufacturer" to manufacturer,
            "brand" to brand,
            "isOppoDevice" to isOppoDevice,
            "seedlingSupported" to seedlingSupported,
            "systemIntentSupported" to systemIntentSupported,
            "fluidCloudSupported" to fluidCloudSupported,
            "appConfigured" to appConfigured,
            "error" to (error ?: ""),
        )

        val supportsFluidCloud: Boolean
            get() = isOppoDevice && seedlingSupported && systemIntentSupported && fluidCloudSupported
    }

    /**
     * Uses OPPO's own service checks. Those checks cross process and therefore
     * run on a worker; isSupportFluidCloud's callback also handles FBE unlock.
     */
    fun checkCapability(context: Context, callback: (Capability) -> Unit) {
        val appContext = context.applicationContext
        val isOppo = isExplicitlySupportedBrand()
        // The debug capability page may query realme's OPlus system service
        // APIs, but realme remains excluded from the production dispatch path
        // below until OPPO explicitly approves it for this service.
        if (!isOppo && !isRealmeDevice()) {
            callback(
                Capability(
                    manufacturer = Build.MANUFACTURER,
                    brand = Build.BRAND,
                    isOppoDevice = false,
                    seedlingSupported = false,
                    systemIntentSupported = false,
                    fluidCloudSupported = false,
                    appConfigured = OppoFluidCloudConfig.isConfigured,
                ),
            )
            return
        }

        cachedCapability?.let { callback(it); return }
        synchronized(lock) {
            cachedCapability?.let { callback(it); return }
            capabilityWaiters.add(callback)
            if (capabilityCheckInFlight) return
            capabilityCheckInFlight = true
        }

        executor.execute {
            try {
                val seedlingSupported = SeedlingTool.isSupportSeedlingCard(appContext)
                val systemIntentSupported = SeedlingTool.isSupportSystemSendIntent(appContext)
                SeedlingTool.isSupportFluidCloud(appContext) { fluidCloudSupported ->
                    completeCapability(
                        Capability(
                            manufacturer = Build.MANUFACTURER,
                            brand = Build.BRAND,
                            isOppoDevice = isOppo,
                            seedlingSupported = seedlingSupported,
                            systemIntentSupported = systemIntentSupported,
                            fluidCloudSupported = fluidCloudSupported,
                            appConfigured = OppoFluidCloudConfig.isConfigured,
                        ),
                    )
                }
            } catch (error: Throwable) {
                Log.w(tag, "Official Seedling capability check failed (${error.javaClass.simpleName})")
                completeCapability(
                    Capability(
                        manufacturer = Build.MANUFACTURER,
                        brand = Build.BRAND,
                        isOppoDevice = isOppo,
                        seedlingSupported = false,
                        systemIntentSupported = false,
                        fluidCloudSupported = false,
                        appConfigured = OppoFluidCloudConfig.isConfigured,
                        error = error.javaClass.simpleName,
                    ),
                )
            }
        }
    }

    /** Returns true when Fluid Cloud owns this state or the user dismissed it. */
    fun synchronize(
        context: Context,
        state: OngoingActivityState,
        callback: (Boolean) -> Unit,
    ) {
        if (!OppoFluidCloudConfig.isConfigured || !isExplicitlySupportedBrand()) {
            callback(false)
            return
        }

        checkCapability(context) { capability ->
            if (!capability.supportsFluidCloud) {
                Log.i(tag, "Fluid Cloud unavailable; allowing the existing Android fallback")
                callback(false)
                return@checkCapability
            }
            executor.execute {
                val handled = try {
                    dispatchState(context.applicationContext, state)
                } catch (error: Throwable) {
                    Log.e(tag, "Seedling state dispatch failed (${error.javaClass.simpleName})")
                    false
                }
                mainHandler.post { callback(handled) }
            }
        }
    }

    /** Used by the debug-only controls to verify cancellation without UI side effects. */
    fun removeForDebug(context: Context, sessionId: String, callback: (Boolean) -> Unit) {
        if (!OppoFluidCloudConfig.isConfigured || sessionId.isBlank()) {
            callback(false)
            return
        }
        checkCapability(context) { capability ->
            if (!capability.supportsFluidCloud) {
                callback(false)
                return@checkCapability
            }
            executor.execute {
                val removed = try {
                    sendIntent(context.applicationContext, sessionId, null, isExited = true, isMilestone = true)
                    true
                } catch (error: Throwable) {
                    Log.e(tag, "Seedling remove dispatch failed (${error.javaClass.simpleName})")
                    false
                }
                mainHandler.post { callback(removed) }
            }
        }
    }

    /** Latest saved UI data is reused if the system requests a card refresh. */
    fun latestBusinessData(context: Context, expectedSessionId: String?): JSONObject? {
        val prefs = context.applicationContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val savedSession = prefs.getString(keyCurrentSession, null) ?: return null
        if (expectedSessionId != null && savedSession != expectedSessionId) return null
        val json = prefs.getString(keyCurrentData, null) ?: return null
        return runCatching { JSONObject(json) }.getOrNull()
    }

    fun noteServiceClosed(context: Context, serviceId: String, serviceInstanceId: String) {
        if (serviceId != OppoFluidCloudConfig.serviceId || serviceInstanceId.isBlank()) return
        context.applicationContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putString(keyDismissedSession, serviceInstanceId)
            .apply()
        Log.i(tag, "System reported that the current service was dismissed")
    }

    private fun completeCapability(capability: Capability) {
        val callbacks: List<(Capability) -> Unit>
        synchronized(lock) {
            cachedCapability = capability
            capabilityCheckInFlight = false
            callbacks = capabilityWaiters.toList()
            capabilityWaiters.clear()
        }
        Log.i(
            tag,
            "Capability result: seedling=${capability.seedlingSupported}, " +
                "systemIntent=${capability.systemIntentSupported}, " +
                "fluidCloud=${capability.fluidCloudSupported}",
        )
        mainHandler.post { callbacks.forEach { it(capability) } }
    }

    private fun dispatchState(context: Context, state: OngoingActivityState): Boolean {
        val sessionId = state.sessionId?.takeIf(String::isNotBlank) ?: return false
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        if (preferences.getString(keyDismissedSession, null) == sessionId && state.isOngoing) {
            Log.i(tag, "Respecting the system dismissal for the current session")
            cacheState(context, state)
            return true
        }

        val cards = SeedlingTool.getSeedlingCardMap()[OppoFluidCloudConfig.serviceId].orEmpty()
        val matchingCard = cards.firstOrNull { it.serviceInstanceId == sessionId }
        val now = System.currentTimeMillis()
        val businessData = state.toFluidCloudData(now)
        val payloadSignature = "$sessionId|${state.status}|${businessData}"
        if (preferences.getString(keyLastDispatch, null) == payloadSignature) return true

        val previousSession = preferences.getString(keyCurrentSession, null)
        val previousStatus = preferences.getString(keyCurrentStatus, null)
        val isMilestone = previousSession != sessionId || previousStatus != state.status

        if (state.isOngoing) {
            // Remove a stale session before starting a different one. The business
            // session ID is also the stable system serviceInstanceId.
            cards.asSequence()
                .mapNotNull { it.serviceInstanceId }
                .filter { it.isNotBlank() && it != sessionId }
                .distinct()
                .forEach { staleSessionId ->
                    sendIntent(context, staleSessionId, null, isExited = true, isMilestone = true)
                }

            if (matchingCard == null) {
                sendIntent(context, sessionId, businessData, isExited = false, isMilestone = isMilestone)
                Log.i(tag, "Fluid Cloud create/update intent dispatched")
            } else {
                val options = SeedlingCardOptions().apply { this.isMilestone = isMilestone }
                SeedlingTool.updateAllCardData(matchingCard, sessionId, businessData, options)
                Log.i(tag, "Fluid Cloud card data updated")
            }
        } else if (matchingCard != null) {
            // The official default milestone expiry is five minutes. OPPO can
            // approve a shorter stateDuration; YANJI does not assume that grant.
            val options = SeedlingCardOptions().apply { this.isMilestone = true }
            SeedlingTool.updateAllCardData(matchingCard, sessionId, businessData, options)
            Log.i(tag, "Fluid Cloud completion state dispatched")
        } else {
            // Do not create a new visible card for an already-finished session.
            sendIntent(context, sessionId, null, isExited = true, isMilestone = true)
            Log.i(tag, "Fluid Cloud stale session removal dispatched")
        }

        cacheState(context, state, businessData, payloadSignature)
        return true
    }

    private fun cacheState(
        context: Context,
        state: OngoingActivityState,
        businessData: JSONObject = state.toFluidCloudData(System.currentTimeMillis()),
        payloadSignature: String? = null,
    ) {
        val editor = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putString(keyCurrentData, businessData.toString())
            .putString(keyCurrentStatus, state.status)
            .putString(keyLastDispatch, payloadSignature)
        if (state.sessionId == null) {
            editor.remove(keyCurrentSession)
        } else {
            editor.putString(keyCurrentSession, state.sessionId)
        }
        if (!state.isOngoing) editor.remove(keyDismissedSession)
        editor.apply()
    }

    private fun sendIntent(
        context: Context,
        sessionId: String,
        businessData: JSONObject?,
        isExited: Boolean,
        isMilestone: Boolean,
    ) {
        val intentData = JSONObject()
            .put("service_id", OppoFluidCloudConfig.serviceId)
            .put("intent_id", OppoFluidCloudConfig.intentId)
            .put("intent_flag", 0)
            .put("force_rebuild", !isExited)
            .put("policy_name", OppoFluidCloudConfig.policyName)
            .put("is_exited", isExited)
            .put("instance_id", sessionId)
        if (businessData != null) {
            intentData.put("business_data", businessData.toString())
        }

        val options = SeedlingCardOptions().apply { this.isMilestone = isMilestone }
        SeedlingTool.updateIntelligentData(
            context,
            IntelligentData(
                System.currentTimeMillis(),
                OppoFluidCloudConfig.eventCode,
                OppoFluidCloudConfig.event,
                intentData,
                businessData,
                options,
                sessionId,
            ),
        )
    }

    private fun isExplicitlySupportedBrand(): Boolean =
        Build.MANUFACTURER.equals("OPPO", ignoreCase = true) ||
            Build.BRAND.equals("OPPO", ignoreCase = true)

    private fun isRealmeDevice(): Boolean =
        Build.MANUFACTURER.equals("realme", ignoreCase = true) ||
            Build.BRAND.equals("realme", ignoreCase = true)
}
