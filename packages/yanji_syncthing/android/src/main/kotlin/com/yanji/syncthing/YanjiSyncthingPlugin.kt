package com.yanji.syncthing

import engine.Engine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executors

class YanjiSyncthingPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "yanji/syncthing")
        channel.setMethodCallHandler(this)
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val request = call.arguments as? String
        if (call.method != "execute" || request == null) { result.notImplemented(); return }
        worker.execute {
            try {
                val response = Engine.execute(request)
                main.post { result.success(response) }
            } catch (e: Exception) { main.post { result.error("sync_engine", e.message, null) } }
        }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        worker.execute { try { Engine.execute("{\"command\":\"stop\"}") } catch (_: Exception) {} }
        worker.shutdown()
    }
}
