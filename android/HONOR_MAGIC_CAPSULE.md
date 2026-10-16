# YANJI HONOR Magic Capsule / YOYO integration preparation

Audit date: 2026-09-30

## Current project audit

YANJI does not yet have a standalone Dart `OngoingActivityService`. Its current source of truth is the existing study session, synchronized through `StudyLiveActivity` and one Android `MethodChannel`.

The state already present in the repository is:

- `sessionId`, subject, `active` / `paused` / `finished`, elapsed seconds, today total, target seconds, and Do Not Disturb state.
- There is one current local study session. There is no task ID, expected end time, target progress, or separate cancelled state.
- iOS uses ActivityKit through `StudyLiveActivityBridge`.
- Android currently dispatches OPPO Seedling/Fluid Cloud, then Xiaomi Super Island on candidate Xiaomi devices, then the existing ongoing notification.
- There is no vivo Android adapter in this checkout. `VIVO_ATOMIC_ISLAND.md` is an audit/plan only.
- HONOR is now represented in the Android manager as a separate, approval-gated adapter before the existing notification fallback.

## HONOR developer terminology and route

The user-facing destinations are **灵动胶囊**, dynamic notification, lock-screen notification, AOD, and YOYO Suggestions cards. The developer interface documented for third-party event data is **Suggestions Kit** under **YOYO 建议 / 全局触达**. The public workflow is app registration, Suggestions Kit permission approval, SDK integration, event feedback, scene configuration, design review, and joint testing. There is no documented `MagicCapsule.show()` call.

The official event-data SDK currently listed in HONOR's version history is `com.hihonor.mcs:intelligence-suggestion:1.0.0.308` (release note dated 2025-04-09; latest version listed when checked). The current general HONOR Maven repository documentation uses `https://developer.honor.com/repo`. HONOR's YOYO Suggestions supported-device list says MagicOS 7.0 or later. This is a platform baseline, not a guarantee that every model or scene displays a capsule.

References:

- [YOYO 全局触达业务介绍](https://developer.honor.com/cn/doc/guides/101452)
- [事件通知开发流程](https://developer.honor.com/cn/doc/guides/101439)
- [Suggestions Kit 权限申请](https://developer.honor.com/cn/doc/guides/101594)
- [全局触达配置指南](https://developer.honor.com/cn/doc/guides/101455)
- [全局触达设计指南](https://developer.honor.com/cn/doc/guides/101538)
- [Suggestions Kit 版本信息](https://developer.honor.com/cn/kitdoc/MagicLive/11003/guides/version-history.md)
- [Suggestions Kit SDK 隐私声明](https://developer.honor.com/cn/docs/11003/guides/privacy)
- [YOYO Suggestions 支持设备列表](https://developer.honor.com/cn/doc/guides/101603)

## Scenario eligibility

The current public global-reach list covers life services (delivery, pickup, retail, medicine, queueing, ticketing and coupons) and travel (flight, rail, taxi, navigation and vehicle control). The public list does not name education, studying, focus timers, or task progress. No public 2026 learning scene or matching intent type was found.

The generic-looking `状态提醒` code in the event-notification reference is listed with unrelated public reminder categories. It does not establish that a study session is an approved scenario, so this integration does not use that code. YANJI must apply for an approved education/focus scene or receive a written custom-scene specification from HONOR.

App-data feedback permission and global-reach scene approval are separate gates. A successful Suggestions Kit event call alone does not establish capsule eligibility. The scene must also be approved and configured with its distribution templates.

## Data channel and event model

The on-device channel is the right starting point because YANJI knows study-session transitions locally. A cloud channel is unnecessary for this product state and would require a backend, UUID handling/expiry, and server-side app-level AccessToken credentials. No server credential or device UUID is added to the app.

The HONOR `Event` model is the closest semantic match for one user-started, finite study session. `Plan` describes recurring future plans, so it is not used. The public event model documents an event occurrence and an event end; it does not document a generic live progress update, pause, or resume operation. The docs also disagree on the end status code (`01` in the sample/cloud contract versus `11` in the Android parameter table). The end code is therefore an external configuration value and cannot enable this adapter until HONOR confirms the value for YANJI's approved Android contract.

Mapping prepared in code:

- `active` or `paused` can identify the same ongoing business event; start identity is stable across restore.
- `finished` is the existing terminal state for both completion and cancellation.
- Progress ticks, pause, and resume are not converted into extra events. No per-second feedback is sent.
- Event IDs sent by the future client are a stable truncated SHA-256 digest of the local session ID; the raw ID is not logged or sent.
- Repeated event phases are deduplicated. A Suggestions Kit `FLOW` response applies a local 60-second retry backoff; that is a YANJI safety delay, not an HONOR-published rate limit.
- SDK results are mapped separately for success, unauthorized, flow-limited, invalid-parameter, service-error, unsupported, and other failures.

The actual state-specific feedback schema is deliberately not activated: the approved scene, exact end status, and mapping for pause/resume/progress do not exist yet. The adapter currently returns control to the normal Android notification path. This keeps the timer working and prevents a stale or misleading system event.

## Configuration and privacy gates

`android/app/build.gradle.kts` exposes these `local.properties` or Gradle properties; source defaults are empty/false:

```properties
honor.suggestions.appId=
honor.suggestions.intentType=
honor.suggestions.endedEventStatus=
honor.suggestions.permissionApproved=false
honor.suggestions.sceneApproved=false
honor.suggestions.privacyNoticeReady=false
honor.suggestions.stateContractApproved=false
```

Only values issued/confirmed for the registered YANJI app and approved scene may be supplied. The manifest contains the official `com.hihonor.mcs.client.appid` metadata key, but no placeholder ID is committed. The application-data-feedback permission and scene approval are not inferred from a non-empty ID.

HONOR's current SDK privacy statement says the Suggestions Kit event-use fields (intent type, operation type, state and time) are processed on-device and not retained or uploaded to a server. Its separate event-notification page describes the cloud route, which this product does not use. The SDK is not initialized until the build-side approval/disclosure gates and a separately stored explicit data-feedback consent are all present. Consent defaults to false. `setHonorSuggestionsDataConsent` is a bridge for a future consent/settings flow; no product UI or privacy text was added. Before enabling feedback, YANJI's privacy notice and third-party SDK disclosure must be reviewed against HONOR's official SDK privacy statement and YANJI's actual data practices. The public SDK also documents a delete-feedback-all operation; consent withdrawal and deletion should be completed before activation.

The event-notification flow explicitly documents the app ID manifest metadata. It does not require `mcs-services.json` in that flow, so none is fabricated or added. The current implementation also does not apply HONOR's `asplugin` Gradle plugin. If the developer console later makes an app-specific `mcs-services.json` mandatory, download it for the registered YANJI app and follow the current Kit-specific integration guide rather than copying another app's file.

## Shared deep link

The existing URI is retained: `yanji://live-activity/open`. Android now captures it in the shared native bridge on both cold and warm launch, stores the pending `open` action, and the existing Flutter startup flow routes to `/timer`. There is no HONOR-specific URI and no vendor branch in Flutter business screens.

## Proposed scene and visual specification for HONOR review

This is a design brief only; it is not a final HONOR-approved template or image asset.

**Scene proposal:** YANJI user-started study / focus session.

**User value:** let a learner glance at whether the session is running or paused and how long they have studied, then return directly to that session without reopening the app and finding it again.

**Start and end:** start when the user starts a study session; end when the existing session becomes `finished` (complete or cancel). One local session is active at a time. YANJI currently has no expected completion time or percentage target.

**Update request:** only user-driven state changes. Ask HONOR to specify whether progress, pause, and resume should be separate event feedback with the same event ID, what fields the scene template consumes, and the supported minimum interval. YANJI must not send a timer tick every second.

**Content proposal:**

- Capsule: business name `学习`; state text `学习中` or `已暂停`; optional elapsed-time value. Keep the state phrase to three Chinese characters.
- Dynamic notification: subject, state, elapsed time, and one `返回学习` action. Do not promise a pause button until HONOR confirms supported action semantics.
- Lock screen: the same core state plus the subject, with readable contrast and no full task paragraph.
- AOD: `学习中` / `已暂停` plus a compact elapsed-time value.
- YOYO card: prepare M and S versions only if HONOR requires them for the approved scene; do not reproduce a system card inside Flutter.

The visual package will need the app/service logo, approved scene icon, illustration if requested, light and dark backgrounds where required, and high-fidelity layouts for AOD, capsule, dynamic notification, lock screen, YOYO card(s), interaction flow, and landing page. No final PNG or unapproved brand treatment is included here.

## Developer-portal application checklist

1. Register/verify the developer account and create the Android app using the final package name and signing identity.
2. Apply for the Suggestions Kit **application data feedback** permission. Do not apply for activity-recognition permission; YANJI does not use it.
3. Ask HONOR whether education/study/focus is eligible as a new or custom global-reach scene. Provide the actual YANJI use case and ask for the Android event end code and the approved state/update payload contract.
4. After approval, create/configure the scene and its distribution data, add test users, and submit the required test report and recording.
5. Supply the real App ID and approved intent type in local build configuration; review and update YANJI's privacy disclosure and add a user consent choice before enabling event feedback.
6. Prepare the approved visual package and shared `yanji://live-activity/open` landing flow; then jointly test with HONOR on a MagicOS device.

Application material to prepare: app name/package/signature, App ID, app-data-feedback permission, proposed scenario and user value, event source/channel, start/end rules, status fields and update cadence, expected session lifetime, displayed content, shared deep link, M/S card resources if required, AOD/capsule/notification high-fidelity flows, test accounts and test report, privacy/SDK disclosure, and a HONOR test-device plan.

## Remaining verification

- No HONOR phone is attached in the current shell environment (`adb` is unavailable).
- No HONOR app ID, data-feedback approval, learning scene approval, or final payload schema is present.
- The dependency and native bridge can be build-verified, but no claim of a real capsule display is made.
- Before runtime activation, confirm the documented end-status discrepancy, whether the Android API updates an event with a stable `eventId`, and the exact schema required by the approved scene.

## Local validation performed

- `dart format` completed for the HONOR Flutter bridge, debug page, and app route.
- `flutter pub get` completed.
- `flutter test` passed all 164 tests.
- `flutter analyze` reported one existing info diagnostic in `lib/features/target_goal.dart`; the HONOR bridge, debug page, and app route passed a targeted analysis with no issues.
- `:app:testDebugUnitTest` passed all 17 Android unit tests, including the HONOR mapper/version/rate-limit tests and existing vendor tests.
- `:app:assembleDebug` passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build ios --no-codesign` passed.
- `:app:assembleRelease` did not pass: `GeneratedPluginRegistrant.java` references the dev-only `integration_test` plugin, but its class is missing from the Release compile classpath. This is an existing project build issue also recorded in `XIAOMI_SUPER_ISLAND.md`. Release R8 execution was therefore not reached; the current release build type does not enable minification.
- No HONOR device runtime, capsule, AOD, lock-screen, or YOYO-card result was tested.
