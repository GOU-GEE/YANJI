package com.example.yanji.ongoing.xiaomi

import com.example.yanji.ongoing.OngoingActivityState
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class XiaomiSuperIslandMapperTest {
    private fun state(
        status: String = "active",
        elapsedSeconds: Long = 0,
        subject: String = "数据结构复习",
        targetSeconds: Long = 0,
    ) = OngoingActivityState(
        sessionId = "study-session-1",
        subject = subject,
        status = status,
        elapsedSeconds = elapsedSeconds,
        todayTotalSeconds = elapsedSeconds,
        targetSeconds = targetSeconds,
        doNotDisturbEnabled = false,
    )

    @Test
    fun hyperos2CreatesFocusFieldsWithoutIslandFields() {
        val payload = XiaomiSuperIslandMapper.map(
            state(status = "active", elapsedSeconds = 60),
            XiaomiSuperIslandMapper.HYPEROS_2,
            "approved-study-scene",
        )!!
        val param = JSONObject(payload.json).getJSONObject("param_v2")

        assertEquals("approved-study-scene", param.getString("business"))
        assertEquals("学习中", param.getString("ticker"))
        assertEquals("学习中", param.getString("aodTitle"))
        assertEquals(1, param.getJSONObject("baseInfo").getInt("type"))
        assertFalse(param.has("param_island"))
        assertFalse(param.has("protocol"))
        assertEquals(43_140, payload.remainingSeconds)
        assertEquals(43_140_000L, payload.notificationTimeoutMillis)
    }

    @Test
    fun hyperos3CreatesCompactIslandSummary() {
        val payload = XiaomiSuperIslandMapper.map(
            state(),
            XiaomiSuperIslandMapper.HYPEROS_3,
            "approved-study-scene",
        )!!
        val param = JSONObject(payload.json).getJSONObject("param_v2")
        val island = param.getJSONObject("param_island")
        val large = island.getJSONObject("bigIslandArea")
            .getJSONObject("imageTextInfoLeft")
        val small = island.getJSONObject("smallIslandArea").getJSONObject("picInfo")

        assertEquals(1, island.getInt("islandProperty"))
        assertEquals("学习中", large.getJSONObject("textInfo").getString("frontTitle"))
        assertEquals("数据结构复习", large.getJSONObject("textInfo").getString("title"))
        assertEquals(1, large.getJSONObject("picInfo").getInt("type"))
        assertEquals(1, small.getInt("type"))
        assertFalse(param.has("ticker"))
    }

    @Test
    fun pauseAndResumeMapToConciseStatusWithoutSyntheticProgress() {
        val paused = XiaomiSuperIslandMapper.map(
            state(status = "paused", elapsedSeconds = 1_531),
            XiaomiSuperIslandMapper.HYPEROS_3,
            "approved-study-scene",
        )!!
        val resumed = XiaomiSuperIslandMapper.map(
            state(status = "active", elapsedSeconds = 1_531),
            XiaomiSuperIslandMapper.HYPEROS_3,
            "approved-study-scene",
        )!!

        assertEquals(
            "已暂停",
            JSONObject(paused.json).getJSONObject("param_v2").getString("aodTitle"),
        )
        assertEquals(
            "学习中",
            JSONObject(resumed.json).getJSONObject("param_v2").getString("aodTitle"),
        )
        assertFalse(paused.json.contains("progress"))
        assertFalse(resumed.json.contains("progress"))
    }

    @Test
    fun terminalStatesAndMissingApprovedBusinessHaveNoPayload() {
        assertNull(
            XiaomiSuperIslandMapper.map(
                state(status = "finished"),
                XiaomiSuperIslandMapper.HYPEROS_3,
                "approved-study-scene",
            ),
        )
        assertNull(
            XiaomiSuperIslandMapper.map(
                state(status = "cancelled"),
                XiaomiSuperIslandMapper.HYPEROS_3,
                "approved-study-scene",
            ),
        )
        assertNull(
            XiaomiSuperIslandMapper.map(
                state(),
                XiaomiSuperIslandMapper.HYPEROS_3,
                " ",
            ),
        )
        assertNull(
            XiaomiSuperIslandMapper.map(
                state(elapsedSeconds = 12 * 60 * 60L),
                XiaomiSuperIslandMapper.HYPEROS_2,
                "approved-study-scene",
            ),
        )
    }

    @Test
    fun mapperUsesOnlySupportedProtocols() {
        assertNull(XiaomiSuperIslandMapper.map(state(), 0, "approved-study-scene"))
        assertNull(XiaomiSuperIslandMapper.map(state(), 1, "approved-study-scene"))
        assertNull(XiaomiSuperIslandMapper.map(state(), 4, "approved-study-scene"))
    }

    @Test
    fun progressIsBoundedAndAbsentWithoutTarget() {
        assertNull(XiaomiSuperIslandMapper.progressPercent(50, 0))
        assertEquals(0, XiaomiSuperIslandMapper.progressPercent(0, 100))
        assertEquals(1, XiaomiSuperIslandMapper.progressPercent(1, 100))
        assertEquals(50, XiaomiSuperIslandMapper.progressPercent(50, 100))
        assertEquals(99, XiaomiSuperIslandMapper.progressPercent(99, 100))
        assertEquals(100, XiaomiSuperIslandMapper.progressPercent(100, 100))
        assertEquals(100, XiaomiSuperIslandMapper.progressPercent(150, 100))
        assertEquals(0, XiaomiSuperIslandMapper.progressPercent(-10, 100))
    }

    @Test
    fun durationFormattingCoversMinuteAndHourBoundaries() {
        assertEquals("00:01", XiaomiSuperIslandMapper.formatDuration(1))
        assertEquals("59:59", XiaomiSuperIslandMapper.formatDuration(3_599))
        assertEquals("1:00:00", XiaomiSuperIslandMapper.formatDuration(3_600))
        assertEquals("10:00:00", XiaomiSuperIslandMapper.formatDuration(36_000))
        assertEquals("00:00", XiaomiSuperIslandMapper.formatDuration(-1))
    }

    @Test
    fun ChineseSubjectsAndLongUnicodeTextRemainValidJsonAndBounded() {
        val examples = listOf(
            "学习",
            "今日任务",
            "数据结构复习",
            "完成今日算法竞赛训练计划",
        )
        for (subject in examples) {
            val payload = XiaomiSuperIslandMapper.map(
                state(subject = subject),
                XiaomiSuperIslandMapper.HYPEROS_3,
                "approved-study-scene",
            )!!
            val parsed = JSONObject(payload.json)
            assertEquals(
                subject,
                parsed.getJSONObject("param_v2")
                    .getJSONObject("param_island")
                    .getJSONObject("bigIslandArea")
                    .getJSONObject("imageTextInfoLeft")
                    .getJSONObject("textInfo")
                    .getString("title"),
            )
        }

        val longSubject = "学🙂习".repeat(12)
        val compacted = XiaomiSuperIslandMapper.compactText(longSubject)
        assertTrue(compacted.codePointCount(0, compacted.length) <= 24)
        assertTrue(JSONObject("{\"valid\":true}").getBoolean("valid"))
    }
}
