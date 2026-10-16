package com.example.yanji.ongoing.honor

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.example.yanji.BuildConfig
import com.hihonor.android.magicx.intelligence.suggestion.Suggestion
import com.hihonor.android.magicx.intelligence.suggestion.common.enumrate.FeatureEnum
import java.util.concurrent.Executors

/** HONOR-only checks; a manufacturer string by itself never enables dispatch. */
internal object HonorSuggestionsCapability {
    private const val tag = "YANJI.HonorMagicCapsule"
    private const val providerUri =
        "content://com.hihonor.brain.kitservice.provider.KitProvider"
    private const val queryMethod = "queryBusinessData"
    private const val globalReachArgument = "globalReach"
    private const val queryParametersKey = "queryParamList"
    private const val consentPreferences = "honor_suggestions"
    private const val dataFeedbackConsentKey = "data_feedback_consent"
    private const val permissionResultKey = "permission_result"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    data class Report(
        val manufacturer: String,
        val brand: String,
        val model: String,
        val androidVersion: String,
        val magicOsVersion: String,
        val isHonorDevice: Boolean,
        val supportedOsVersion: Boolean,
        val suggestionsKitAvailable: Boolean?,
        val permissionStatus: String,
        val globalReachEnabled: Boolean?,
        val dataConsentGranted: Boolean,
        val appIdConfigured: Boolean,
        val intentTypeConfigured: Boolean,
        val sceneApproved: Boolean,
        val privacyNoticeReady: Boolean,
        val stateContractApproved: Boolean,
        val stateMapperReady: Boolean,
        val selectedAdapter: String,
        val error: String = "",
    ) {
        val fullLifecycleReady: Boolean
            get() = isHonorDevice && supportedOsVersion &&
                suggestionsKitAvailable == true && permissionStatus == "approved" &&
                globalReachEnabled == true && appIdConfigured && intentTypeConfigured &&
                sceneApproved && privacyNoticeReady && dataConsentGranted &&
                stateContractApproved && stateMapperReady

        fun toMap(): Map<String, Any?> = mapOf(
            "manufacturer" to manufacturer,
            "brand" to brand,
            "model" to model,
            "androidVersion" to androidVersion,
            "magicOsVersion" to magicOsVersion,
            "isHonorDevice" to isHonorDevice,
            "supportedOsVersion" to supportedOsVersion,
            "suggestionsKitAvailable" to suggestionsKitAvailable,
            "permissionStatus" to permissionStatus,
            "globalReachEnabled" to globalReachEnabled,
            "dataConsentGranted" to dataConsentGranted,
            "appIdConfigured" to appIdConfigured,
            "intentTypeConfigured" to intentTypeConfigured,
            "sceneApproved" to sceneApproved,
            "privacyNoticeReady" to privacyNoticeReady,
            "stateContractApproved" to stateContractApproved,
            "stateMapperReady" to stateMapperReady,
            "selectedAdapter" to selectedAdapter,
            "error" to error,
        )
    }

    fun inspect(context: Context): Report {
        val isHonor = isHonorDevice()
        val magicOsVersion = HonorMagicOsVersion.parse(Build.DISPLAY, Build.VERSION.INCREMENTAL)
        val osSupported = magicOsVersion?.let(HonorMagicOsVersion::isSupported) ?: false
        val globalReachEnabled = if (isHonor) queryGlobalReachEnabled(context.contentResolver) else null
        val dataConsentGranted = hasDataFeedbackConsent(context)

        // Do not initialize Suggestions Kit before the app has a real App ID,
        // platform data-feedback approval, approved scene, disclosure and user
        // consent path. This project currently has none of those approvals.
        val mayProbeSdk = isHonor && osSupported &&
            BuildConfig.HONOR_SUGGESTIONS_RUNTIME_CONFIGURED && dataConsentGranted
        val sdkAvailable = if (mayProbeSdk) {
            try {
                Suggestion.getInstance(context.applicationContext)
                    .hasFeature(FeatureEnum.FEEDBACK_EVENT.value)
            } catch (error: Throwable) {
                Log.w(tag, "Suggestions Kit capability check failed (${error.javaClass.simpleName})")
                false
            }
        } else {
            null
        }

        val permissionStatus = when {
            !BuildConfig.HONOR_SUGGESTIONS_PERMISSION_APPROVED -> "not-approved"
            !BuildConfig.HONOR_SUGGESTIONS_RUNTIME_CONFIGURED -> "not-probed"
            context.applicationContext.getSharedPreferences(consentPreferences, Context.MODE_PRIVATE)
                .getString(permissionResultKey, null) == "unauthorized" -> "unauthorized"
            else -> "approved"
        }
        val readiness = isHonor && osSupported && sdkAvailable == true &&
            permissionStatus == "approved" && globalReachEnabled == true &&
            BuildConfig.HONOR_SUGGESTIONS_RUNTIME_CONFIGURED && dataConsentGranted &&
            STATE_MAPPER_READY
        return Report(
            manufacturer = Build.MANUFACTURER,
            brand = Build.BRAND,
            model = Build.MODEL,
            androidVersion = Build.VERSION.RELEASE,
            magicOsVersion = magicOsVersion ?: "unknown",
            isHonorDevice = isHonor,
            supportedOsVersion = osSupported,
            suggestionsKitAvailable = sdkAvailable,
            permissionStatus = permissionStatus,
            globalReachEnabled = globalReachEnabled,
            dataConsentGranted = dataConsentGranted,
            appIdConfigured = BuildConfig.HONOR_SUGGESTIONS_APP_ID.isNotBlank(),
            intentTypeConfigured = BuildConfig.HONOR_SUGGESTIONS_INTENT_TYPE.isNotBlank(),
            sceneApproved = BuildConfig.HONOR_SUGGESTIONS_SCENE_APPROVED,
            privacyNoticeReady = BuildConfig.HONOR_SUGGESTIONS_PRIVACY_NOTICE_READY,
            stateContractApproved = BuildConfig.HONOR_SUGGESTIONS_STATE_CONTRACT_APPROVED,
            stateMapperReady = STATE_MAPPER_READY,
            selectedAdapter = if (readiness) "HonorMagicCapsuleAdapter" else "fallback",
        )
    }

    fun check(context: Context, callback: (Report) -> Unit) {
        executor.execute {
            val report = try {
                inspect(context.applicationContext)
            } catch (error: Throwable) {
                Log.w(tag, "Capability check failed (${error.javaClass.simpleName})")
                unavailable(error.javaClass.simpleName)
            }
            mainHandler.post { callback(report) }
        }
    }

    private fun unavailable(error: String) = Report(
        manufacturer = Build.MANUFACTURER,
        brand = Build.BRAND,
        model = Build.MODEL,
        androidVersion = Build.VERSION.RELEASE,
        magicOsVersion = "unknown",
        isHonorDevice = false,
        supportedOsVersion = false,
        suggestionsKitAvailable = null,
        permissionStatus = "unknown",
        globalReachEnabled = null,
        dataConsentGranted = false,
        appIdConfigured = BuildConfig.HONOR_SUGGESTIONS_APP_ID.isNotBlank(),
        intentTypeConfigured = BuildConfig.HONOR_SUGGESTIONS_INTENT_TYPE.isNotBlank(),
        sceneApproved = BuildConfig.HONOR_SUGGESTIONS_SCENE_APPROVED,
        privacyNoticeReady = BuildConfig.HONOR_SUGGESTIONS_PRIVACY_NOTICE_READY,
        stateContractApproved = BuildConfig.HONOR_SUGGESTIONS_STATE_CONTRACT_APPROVED,
        stateMapperReady = STATE_MAPPER_READY,
        selectedAdapter = "fallback",
        error = error,
    )

    private const val STATE_MAPPER_READY = false

    fun setDataFeedbackConsent(context: Context, granted: Boolean) {
        context.applicationContext.getSharedPreferences(consentPreferences, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(dataFeedbackConsentKey, granted)
            .apply()
    }

    fun recordFeedbackResult(context: Context, result: HonorFeedbackResult) {
        val preferences = context.applicationContext.getSharedPreferences(
            consentPreferences,
            Context.MODE_PRIVATE,
        )
        when (result) {
            HonorFeedbackResult.NOT_AUTHORIZED -> preferences.edit()
                .putString(permissionResultKey, "unauthorized")
                .apply()
            HonorFeedbackResult.SUCCESS -> preferences.edit()
                .remove(permissionResultKey)
                .apply()
            else -> Unit
        }
    }

    internal fun hasDataFeedbackConsent(context: Context): Boolean =
        context.applicationContext.getSharedPreferences(consentPreferences, Context.MODE_PRIVATE)
            .getBoolean(dataFeedbackConsentKey, false)

    private fun isHonorDevice(): Boolean =
        Build.MANUFACTURER.equals("HONOR", ignoreCase = true) ||
            Build.BRAND.equals("HONOR", ignoreCase = true)

    private fun queryGlobalReachEnabled(contentResolver: ContentResolver): Boolean? {
        return try {
            // Ask only for the switch result. The UUID is cloud-channel-only and is
            // intentionally not requested or persisted by this on-device route.
            val args = Bundle().apply {
                putStringArrayList(queryParametersKey, arrayListOf())
            }
            val result = contentResolver.call(
                Uri.parse(providerUri),
                queryMethod,
                globalReachArgument,
                args,
            )
            result?.getBoolean("result")
        } catch (error: Throwable) {
            Log.i(tag, "globalReach state unavailable (${error.javaClass.simpleName})")
            null
        }
    }

}
