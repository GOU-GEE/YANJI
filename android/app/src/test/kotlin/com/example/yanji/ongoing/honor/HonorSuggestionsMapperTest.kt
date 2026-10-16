package com.example.yanji.ongoing.honor

import com.example.yanji.ongoing.OngoingActivityState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class HonorSuggestionsMapperTest {
    private fun state(
        status: String = "active",
        sessionId: String? = "study-session-1",
        elapsedSeconds: Long = 0,
    ) = OngoingActivityState(
        sessionId = sessionId,
        subject = "数据结构复习",
        status = status,
        elapsedSeconds = elapsedSeconds,
        todayTotalSeconds = elapsedSeconds,
        targetSeconds = 0,
        doNotDisturbEnabled = false,
    )

    @Test
    fun runningAndPausedKeepTheSameEventStartSemantics() {
        val running = HonorSuggestionsMapper.start(state(), nowMillis = 10_000)!!
        val paused = HonorSuggestionsMapper.start(
            state(status = "paused", elapsedSeconds = 30),
            nowMillis = 40_000,
        )!!

        assertEquals(HonorSuggestionsMapper.EventPhase.STARTED, running.phase)
        assertEquals(running.eventId, paused.eventId)
        assertEquals(10_000, running.beginTimeMillis)
        assertEquals(10_000, paused.beginTimeMillis)
        assertEquals("学习中", HonorSuggestionsMapper.compactStatus(state()))
        assertEquals("已暂停", HonorSuggestionsMapper.compactStatus(state(status = "paused")))
        assertEquals("学习", HonorSuggestionsMapper.compactBusinessName())
    }

    @Test
    fun progressPauseAndResumeDoNotInventEventUpdateApi() {
        assertFalse(HonorSuggestionsMapper.hasPublicEventUpdate(state(elapsedSeconds = 1)))
        assertFalse(HonorSuggestionsMapper.hasPublicEventUpdate(state(status = "paused")))
        assertFalse(HonorSuggestionsMapper.hasPublicEventUpdate(state(status = "active", elapsedSeconds = 60)))
    }

    @Test
    fun completionAndCancellationShareTheExistingFinishedBusinessState() {
        val completed = HonorSuggestionsMapper.end(
            state(status = "finished", elapsedSeconds = 125),
            nowMillis = 200_000,
        )!!
        val cancelled = HonorSuggestionsMapper.end(
            state(status = "finished", elapsedSeconds = 125),
            nowMillis = 200_000,
        )!!

        assertEquals(HonorSuggestionsMapper.EventPhase.ENDED, completed.phase)
        assertEquals(completed.eventId, cancelled.eventId)
        assertEquals(75_000L, completed.beginTimeMillis)
        assertEquals(200_000L, completed.endTimeMillis)
        assertEquals("已结束", HonorSuggestionsMapper.compactStatus(state(status = "finished")))
    }

    @Test
    fun mapperRejectsMissingAndUnsupportedStates() {
        assertNull(HonorSuggestionsMapper.start(state(sessionId = null), 1_000))
        assertNull(HonorSuggestionsMapper.end(state(status = "active"), 1_000))
        assertNull(HonorSuggestionsMapper.end(state(sessionId = null, status = "finished"), 1_000))
        assertNull(HonorSuggestionsMapper.displayState(state(status = "unknown")))
    }

    @Test
    fun eventIdIsStableOpaqueAndSeparateFromRawSessionId() {
        val first = HonorSuggestionsMapper.start(state(), 1_000)!!.eventId
        val same = HonorSuggestionsMapper.start(state(), 5_000)!!.eventId
        val other = HonorSuggestionsMapper.start(state(sessionId = "study-session-2"), 1_000)!!.eventId

        assertEquals(first, same)
        assertNotEquals(first, other)
        assertFalse(first.contains("study-session-1"))
    }

    @Test
    fun repeatedStatusAndProgressUpdatesAreDeduplicated() {
        val state = HonorFeedbackGate.State()
        val start = HonorSuggestionsMapper.start(state(), 1_000)!!
        val startKey = HonorFeedbackGate.eventKey(start)
        assertTrue(HonorFeedbackGate.shouldDispatch(state, startKey, 1_000))

        val afterStart = HonorFeedbackGate.afterResult(
            state,
            startKey,
            HonorFeedbackResult.SUCCESS,
            1_000,
        )
        val repeatedStart = HonorSuggestionsMapper.start(state(elapsedSeconds = 30), 31_000)!!
        assertFalse(
            HonorFeedbackGate.shouldDispatch(
                afterStart,
                HonorFeedbackGate.eventKey(repeatedStart),
                31_000,
            ),
        )

        val terminalKey = HonorFeedbackGate.eventKey(HonorSuggestionsMapper.end(
            state(status = "finished", elapsedSeconds = 30),
            31_000,
        )!!)
        assertNotEquals(startKey, terminalKey)
        assertTrue(HonorFeedbackGate.shouldDispatch(afterStart, terminalKey, 31_000))
    }

    @Test
    fun flowResultAppliesLocalBackoffAndCanRetryAfterItExpires() {
        val key = "event:STARTED"
        val limited = HonorFeedbackGate.afterResult(
            HonorFeedbackGate.State(),
            key,
            HonorFeedbackResult.RATE_LIMITED,
            10_000,
        )

        assertFalse(HonorFeedbackGate.shouldDispatch(limited, key, 69_999))
        assertTrue(HonorFeedbackGate.shouldDispatch(limited, key, 70_000))
    }

    @Test
    fun sdkErrorCodesMapToStablePlatformResults() {
        assertEquals(HonorFeedbackResult.SUCCESS, HonorFeedbackResultMapper.fromSdkCode(0))
        assertEquals(HonorFeedbackResult.NOT_AUTHORIZED, HonorFeedbackResultMapper.fromSdkCode(10001))
        assertEquals(HonorFeedbackResult.RATE_LIMITED, HonorFeedbackResultMapper.fromSdkCode(10002))
        assertEquals(HonorFeedbackResult.INVALID_PAYLOAD, HonorFeedbackResultMapper.fromSdkCode(10003))
        assertEquals(HonorFeedbackResult.SERVICE_ERROR, HonorFeedbackResultMapper.fromSdkCode(10004))
        assertEquals(HonorFeedbackResult.FAILED, HonorFeedbackResultMapper.fromSdkCode(-1))
    }

    @Test
    fun magicOsVersionGateRequiresOfficialMinimum() {
        assertEquals("8.0.0.120", HonorMagicOsVersion.parse("HONOR MagicOS 8.0.0.120", ""))
        assertEquals("6.1", HonorMagicOsVersion.parse("Magic UI 6.1", ""))
        assertTrue(HonorMagicOsVersion.isSupported("7.0"))
        assertTrue(HonorMagicOsVersion.isSupported("9.0.0"))
        assertFalse(HonorMagicOsVersion.isSupported("6.1"))
        assertNull(HonorMagicOsVersion.parse("HONOR", "release"))
    }
}
