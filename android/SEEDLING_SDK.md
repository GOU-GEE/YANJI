# OPPO Seedling Support SDK

YANJI vendors the OPPO official `SeedlingSupportSDK-lite` AAR, version `3.0.7`.
The AAR was downloaded from the link in OPPO's `SeedlingSupportSDK` integration
guide and its SHA-256 was checked before it was added:

- Official download: <https://openfs.oppomobile.com/open/oop/202503/26/4f20e6dde01180bc45aa5ad89fb425e9.zip>
- AAR SHA-256: `a4b268fd661d4095528e8fee7a31af57f57721644090c47e3ca6be17992619c7`
- File: `app/libs/seedling-support-lite-3.0.7.aar`
- Minimum Android API: 26 (declared by the official AAR manifest)

The SDK provider stays disabled unless all OPPO-issued integration values are
present in `android/local.properties`. That file is ignored by Git.

```properties
oppo.seedling.authCode=VALUE_FROM_OPPO
oppo.seedling.serviceId=VALUE_FROM_OPPO
oppo.seedling.intentId=VALUE_FROM_OPPO
oppo.seedling.eventCode=VALUE_FROM_OPPO
oppo.seedling.event=VALUE_FROM_OPPO
oppo.seedling.policyName=VALUE_FROM_OPPO
```

Do not substitute guessed IDs. Before enabling this path, the OPPO open platform
must approve YANJI's service scenario, assign the service/intent/event contract,
approve the UPK card package, and issue the host authorization code for YANJI's
final Android application ID and signing certificate. The current project
application ID is still `com.example.yanji`; get the final package name and
signing certificate settled before requesting these values.

OPPO's SDK privacy statement says the Seedling integration SDK does not process
personal information and does not call sensitive device permissions for its
service integration. The AAR manifest contributes OPPO-specific `AI_APP` and
`DATABASE` permissions plus package visibility entries for ColorOS system
services; it does not add `INTERNET` or runtime-sensitive permissions. Review
the merged manifest and update YANJI's third-party SDK disclosure before
shipping the enabled service.

## Local UPK handoff

Fluid Cloud also requires an approved UPK service. The Android AAR only supplies
the host-side lifecycle and data bridge; it does not contain the card UI. OPPO
must approve the service scenario and provide the service/intent contract before
the UPK can be built and uploaded. The app will continue using its existing
Android fallback until that contract is configured.

The remaining platform handoff is:

1. Register YANJI as an enterprise app in OPPO Open Platform and confirm the
   final Android package name and release signing certificate.
2. Apply for the study-session ongoing service/Fluid Cloud scenario and obtain
   the authorization code, service ID, intent ID, event code/name, policy name,
   and the approved business-data schema.
3. Build the UPK against OPPO's current Fluid Cloud template/schema and approved
   host policy, then submit it for service review and publishing.
4. Put the assigned values in the ignored `android/local.properties` file and
   rebuild. Do not enable a card until the UPK and service are approved.

The assigned schema is intentionally not guessed here: it determines the UPK
field names and the system's accepted host/action contract.
