package com.example.location_poc


import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "Boot receiver triggered: ${intent?.action}")
        
        if (context == null || intent == null) return

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                
                // Check if the service was running before reboot
                val prefs = context.getSharedPreferences("location_service", Context.MODE_PRIVATE)
                val wasServiceRunning = prefs.getBoolean("service_was_running", false)
                
                if (wasServiceRunning) {
                    Log.d(TAG, "Restarting location service after boot")
                    
                    val serviceIntent = Intent(context, com.example.location_poc.LocationService::class.java)
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(serviceIntent)
                        } else {
                            context.startService(serviceIntent)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to start service after boot: ${e.message}")
                    }
                }
            }
        }
    }
}