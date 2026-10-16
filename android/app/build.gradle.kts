import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val appLocalProperties = Properties().apply {
    val propertiesFile = rootProject.file("local.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use(::load)
    }
}

fun oppoProperty(name: String): String = appLocalProperties.getProperty(name, "").trim()
fun xiaomiProperty(name: String): String = appLocalProperties.getProperty(name, "").trim()
fun honorProperty(name: String): String =
    providers.gradleProperty(name).orNull?.trim()
        ?: appLocalProperties.getProperty(name, "").trim()

fun buildConfigString(value: String): String =
    "\"${value.replace("\\", "\\\\").replace("\"", "\\\"")}\""

val oppoSeedlingAuthCode = oppoProperty("oppo.seedling.authCode")
val oppoSeedlingServiceId = oppoProperty("oppo.seedling.serviceId")
val oppoSeedlingIntentId = oppoProperty("oppo.seedling.intentId")
val oppoSeedlingEventCode = oppoProperty("oppo.seedling.eventCode")
val oppoSeedlingEvent = oppoProperty("oppo.seedling.event")
val oppoSeedlingPolicyName = oppoProperty("oppo.seedling.policyName")
val oppoFluidCloudConfigured = listOf(
    oppoSeedlingAuthCode,
    oppoSeedlingServiceId,
    oppoSeedlingIntentId,
    oppoSeedlingEventCode,
    oppoSeedlingEvent,
    oppoSeedlingPolicyName,
).all { it.isNotBlank() } &&
    (oppoSeedlingIntentId.toLongOrNull() ?: 0L) > 0L &&
    (oppoSeedlingEventCode.toIntOrNull() ?: 0) > 0
val xiaomiFocusBusiness = xiaomiProperty("xiaomi.focus.business")
val honorSuggestionsAppId = honorProperty("honor.suggestions.appId")
val honorSuggestionsIntentType = honorProperty("honor.suggestions.intentType")
val honorSuggestionsEndedStatus = honorProperty("honor.suggestions.endedEventStatus")
val honorSuggestionsPermissionApproved = honorProperty("honor.suggestions.permissionApproved").toBoolean()
val honorSuggestionsSceneApproved = honorProperty("honor.suggestions.sceneApproved").toBoolean()
val honorSuggestionsPrivacyNoticeReady = honorProperty("honor.suggestions.privacyNoticeReady").toBoolean()
val honorSuggestionsStateContractApproved = honorProperty("honor.suggestions.stateContractApproved").toBoolean()
val honorSuggestionsRuntimeConfigured =
    honorSuggestionsAppId.isNotBlank() &&
        honorSuggestionsIntentType.isNotBlank() &&
        honorSuggestionsIntentType.all(Char::isDigit) &&
        honorSuggestionsEndedStatus in setOf("01", "11") &&
        honorSuggestionsPermissionApproved &&
        honorSuggestionsSceneApproved &&
        honorSuggestionsPrivacyNoticeReady &&
        honorSuggestionsStateContractApproved

android {
    namespace = "com.example.yanji"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.yanji"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // SeedlingSupportSDK-lite 3.0.7 declares minSdkVersion 26.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["oppoSeedlingProviderEnabled"] = oppoFluidCloudConfigured.toString()
        manifestPlaceholders["oppoSeedlingAuthCode"] = oppoSeedlingAuthCode
        // Empty by default. HONOR App IDs and scene data are issued/approved
        // by the developer portal and must never be invented in source.
        manifestPlaceholders["honorSuggestionsAppId"] = honorSuggestionsAppId

        buildConfigField("boolean", "OPPO_FLUID_CLOUD_CONFIGURED", oppoFluidCloudConfigured.toString())
        buildConfigField("String", "OPPO_SEEDLING_SERVICE_ID", buildConfigString(oppoSeedlingServiceId))
        buildConfigField("long", "OPPO_SEEDLING_INTENT_ID", "${oppoSeedlingIntentId.toLongOrNull() ?: 0L}L")
        buildConfigField("int", "OPPO_SEEDLING_EVENT_CODE", oppoSeedlingEventCode.toIntOrNull()?.toString() ?: "0")
        buildConfigField("String", "OPPO_SEEDLING_EVENT", buildConfigString(oppoSeedlingEvent))
        buildConfigField("String", "OPPO_SEEDLING_POLICY_NAME", buildConfigString(oppoSeedlingPolicyName))
        // Xiaomi assigns/approves the business scene. An empty value keeps the
        // Xiaomi payload disabled and preserves the ordinary notification path.
        buildConfigField("String", "XIAOMI_FOCUS_BUSINESS", buildConfigString(xiaomiFocusBusiness))
        buildConfigField("String", "HONOR_SUGGESTIONS_APP_ID", buildConfigString(honorSuggestionsAppId))
        buildConfigField("String", "HONOR_SUGGESTIONS_INTENT_TYPE", buildConfigString(honorSuggestionsIntentType))
        buildConfigField("String", "HONOR_SUGGESTIONS_ENDED_STATUS", buildConfigString(honorSuggestionsEndedStatus))
        buildConfigField("boolean", "HONOR_SUGGESTIONS_PERMISSION_APPROVED", honorSuggestionsPermissionApproved.toString())
        buildConfigField("boolean", "HONOR_SUGGESTIONS_SCENE_APPROVED", honorSuggestionsSceneApproved.toString())
        buildConfigField("boolean", "HONOR_SUGGESTIONS_PRIVACY_NOTICE_READY", honorSuggestionsPrivacyNoticeReady.toString())
        buildConfigField("boolean", "HONOR_SUGGESTIONS_STATE_CONTRACT_APPROVED", honorSuggestionsStateContractApproved.toString())
        buildConfigField("boolean", "HONOR_SUGGESTIONS_RUNTIME_CONFIGURED", honorSuggestionsRuntimeConfigured.toString())
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Downloaded from OPPO's official documentation and SHA-256 verified.
    implementation(files("libs/seedling-support-lite-3.0.7.aar"))
    // Latest Suggestions Kit release listed by HONOR's official version history.
    // Runtime use stays disabled until app-data permission, scene approval,
    // privacy disclosure/consent, and the state contract are configured.
    implementation("com.hihonor.mcs:intelligence-suggestion:1.0.0.308")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
