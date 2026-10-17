package com.example.yanji

import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.MotionEvent
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.yanji.ongoing.xiaomi.XiaomiSuperIslandManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Flutter delays the first Android draw until its first frame. Drop
            // the matching system mark then, without a second exit animation.
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
    }

    private val refreshHandler = Handler(Looper.getMainLooper())
    private val releaseRefreshRate = Runnable { setInteractiveRefreshRate(false) }
    private var highRefreshRateRequested = false

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                refreshHandler.removeCallbacks(releaseRefreshRate)
                setInteractiveRefreshRate(true)
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                refreshHandler.removeCallbacks(releaseRefreshRate)
                // Keep the preference through a fling or a tab transition.
                refreshHandler.postDelayed(releaseRefreshRate, 1500)
            }
        }
        return super.dispatchTouchEvent(event)
    }

    override fun onPause() {
        refreshHandler.removeCallbacks(releaseRefreshRate)
        setInteractiveRefreshRate(false)
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        XiaomiSuperIslandManager.invalidateCapability()
        StudyLiveActivityBridge.synchronizeCurrent(this)
    }

    private fun setInteractiveRefreshRate(active: Boolean) {
        if (highRefreshRateRequested == active) return
        val requestedRate = if (active) {
            window.decorView.display?.supportedModes
                ?.map { it.refreshRate }
                ?.filter { it > 60.5f && it <= 120.1f }
                ?.maxOrNull() ?: return
        } else {
            0f
        }
        val params = window.attributes
        params.preferredRefreshRate = requestedRate
        window.attributes = params
        highRefreshRateRequested = active
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        StudyLiveActivityBridge.register(this, flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yanji/glass")
            .setMethodCallHandler { call, result ->
                if (call.method == "androidSdk") {
                    result.success(Build.VERSION.SDK_INT)
                } else {
                    result.notImplemented()
                }
            }
        captureNotificationAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureNotificationAction(intent)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (
            requestCode == StudyLiveActivityBridge.notificationPermissionRequestCode &&
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        ) {
            StudyLiveActivityBridge.synchronizeCurrent(this)
        }
    }

    private fun captureNotificationAction(source: Intent?) {
        StudyLiveActivityBridge.captureLaunchIntent(this, source)
    }
}
