package com.example.kivou_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "env").setMethodCallHandler { call, result ->
			when (call.method) {
				"getGoogleMapsApiKey" -> {
					val resId = resources.getIdentifier("google_maps_api_key", "string", packageName)
					if (resId != 0) {
						result.success(getString(resId))
					} else {
						result.success("")
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
