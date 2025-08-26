package com.bluebubbles.messaging.services.intents

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.bluebubbles.messaging.Constants
import com.bluebubbles.messaging.utils.Utils
import io.flutter.plugin.common.MethodChannel
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys

/// Receives intents from other apps. This is primarily used for Tasker integration.
class ExternalIntentReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        Log.d(Constants.logTag, "Received intent ${intent.action} from external app")
        when (intent.action) {
            "com.bluebubbles.external.GET_SERVER_URL" -> {
                val password = intent.extras?.getString("password")
                val identifier = intent.extras?.getString("id")
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", 0)
                val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
                val securePrefs = EncryptedSharedPreferences.create(
                    "FlutterSecureStorage",
                    masterKeyAlias,
                    context,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                )
                var storedPassword = securePrefs.getString("guidAuthKey", null)
                if (storedPassword == null) {
                    val legacy = prefs.getString("flutter.guidAuthKey", null)
                    if (legacy != null) {
                        securePrefs.edit().putString("guidAuthKey", legacy).apply()
                        prefs.edit().remove("flutter.guidAuthKey").apply()
                        storedPassword = legacy
                    }
                }

                if (password == storedPassword) {
                    Utils.getServerUrl(context, object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            Log.d(Constants.logTag, "Got URL: $result - sending to Tasker...")
                            val intent = Intent()
                            intent.setAction("net.dinglisch.android.taskerm.BB_SERVER_URL")
                            intent.putExtra("url", result.toString())
                            intent.putExtra("id", identifier)
                            context.sendBroadcast(intent)
                        }

                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                        override fun notImplemented() {}
                    })
                }
            }
        }
    }
}