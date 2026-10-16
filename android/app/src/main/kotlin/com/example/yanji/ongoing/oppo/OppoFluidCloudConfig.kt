package com.example.yanji.ongoing.oppo

import com.example.yanji.BuildConfig

/** Values assigned by OPPO after approving YANJI's service and intent. */
internal object OppoFluidCloudConfig {
    val isConfigured: Boolean = BuildConfig.OPPO_FLUID_CLOUD_CONFIGURED &&
        BuildConfig.OPPO_SEEDLING_INTENT_ID > 0L &&
        BuildConfig.OPPO_SEEDLING_EVENT_CODE > 0 &&
        BuildConfig.OPPO_SEEDLING_SERVICE_ID.isNotBlank() &&
        BuildConfig.OPPO_SEEDLING_EVENT.isNotBlank() &&
        BuildConfig.OPPO_SEEDLING_POLICY_NAME.isNotBlank()

    val serviceId: String = BuildConfig.OPPO_SEEDLING_SERVICE_ID
    val intentId: Long = BuildConfig.OPPO_SEEDLING_INTENT_ID
    val eventCode: Int = BuildConfig.OPPO_SEEDLING_EVENT_CODE
    val event: String = BuildConfig.OPPO_SEEDLING_EVENT
    val policyName: String = BuildConfig.OPPO_SEEDLING_POLICY_NAME
}
