package com.example.yanji.ongoing.oppo

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.oplus.pantanal.seedling.SeedlingCardWidgetProvider
import com.oplus.pantanal.seedling.bean.SeedlingCard
import com.oplus.pantanal.seedling.update.SeedlingCardOptions

/** Receives OPPO's card lifecycle callbacks and answers system data refreshes. */
class YanjiSeedlingCardProvider : SeedlingCardWidgetProvider() {
    override fun onCardCreate(context: Context, card: SeedlingCard) {
        logLifecycle("create", card)
    }

    override fun onShow(context: Context, card: SeedlingCard) {
        logLifecycle("show", card)
    }

    override fun onHide(context: Context, card: SeedlingCard) {
        logLifecycle("hide", card)
    }

    override fun onDestroy(context: Context, card: SeedlingCard) {
        logLifecycle("destroy", card)
    }

    override fun onSubscribed(context: Context, card: SeedlingCard) {
        logLifecycle("subscribed", card)
    }

    override fun onUnSubscribed(context: Context, card: SeedlingCard) {
        logLifecycle("unsubscribed", card)
    }

    override fun onCardObserve(context: Context, clientName: String, cards: List<SeedlingCard>) {
        val serviceCards = cards.count { it.serviceId == OppoFluidCloudConfig.serviceId }
        Log.d(tag, "System card cache observed: $serviceCards YANJI card(s)")
    }

    override fun onUpdateData(context: Context, card: SeedlingCard, data: Bundle) {
        if (card.serviceId != OppoFluidCloudConfig.serviceId) return
        val businessData = OppoFluidCloudManager.latestBusinessData(
            context,
            card.serviceInstanceId,
        ) ?: return
        updateData(
            card,
            businessData,
            SeedlingCardOptions().apply { isMilestone = false },
        )
        Log.d(tag, "System requested the latest full card state")
    }

    override fun onSizeChanged(context: Context, card: SeedlingCard, oldSize: Int, newSize: Int) {
        if (card.serviceId == OppoFluidCloudConfig.serviceId) {
            Log.d(tag, "Fluid Cloud presentation size changed: $oldSize -> $newSize")
        }
    }

    private fun logLifecycle(event: String, card: SeedlingCard) {
        if (card.serviceId == OppoFluidCloudConfig.serviceId) {
            Log.d(tag, "Card lifecycle: $event (${card.host})")
        }
    }

    private companion object {
        const val tag = "YANJI.OPPOFluidCloud"
    }
}

/** Captures failed card creation and explicit user dismissal from OPPO. */
class YanjiSeedlingEventProvider : com.oplus.pantanal.seedling.SeedlingCardEventProvider() {
    override fun onCardCreateErrorInfo(cardErrorInfo: com.oplus.pantanal.seedling.bean.CardCreateErrorBean) {
        if (cardErrorInfo.serviceId == OppoFluidCloudConfig.serviceId) {
            Log.w(
                tag,
                "Card creation failed: code=${cardErrorInfo.errorCode}, " +
                    "entrance=${cardErrorInfo.entranceName}",
            )
        }
    }

    override fun onServiceClose(
        serviceId: String?,
        reason: String?,
        serviceInstanceId: String?,
        extra: String?,
    ) {
        if (serviceId != OppoFluidCloudConfig.serviceId) return
        val instanceId = serviceInstanceId?.takeIf(String::isNotBlank) ?: return
        context?.let { OppoFluidCloudManager.noteServiceClosed(it, serviceId, instanceId) }
        Log.i(tag, "System reported explicit service dismissal: $reason")
    }

    private companion object {
        const val tag = "YANJI.OPPOFluidCloud"
    }
}
