package com.example.drone_stuff

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var shizukuMethodChannel: ShizukuMethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.dronestuff/shizuku"
        )
        shizukuMethodChannel = ShizukuMethodChannel(channel).also { it.register() }
    }

    override fun onDestroy() {
        shizukuMethodChannel?.unregister()
        shizukuMethodChannel = null
        super.onDestroy()
    }
}
