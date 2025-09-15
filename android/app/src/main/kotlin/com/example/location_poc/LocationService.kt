package com.example.locationtracker

import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.*

class LocationService : Service(), LocationListener {

    private val binder = LocationBinder()
    private lateinit var locationManager: LocationManager
    private var locationCallback: ((String) -> Unit)? = null
    
    companion object {
        const val CHANNEL_ID = "LocationServiceChannel"
        const val NOTIFICATION_ID = 1
        var isRunning = false
        private const val TAG = "LocationService"
        private const val LOCATION_INTERVAL = 5 * 60 * 1000L // 5 minutes
        private const val MIN_DISTANCE = 0f // Get location even if not moved
    }

    inner class LocationBinder : Binder() {
        fun getService(): LocationService = this@LocationService
    }

    override fun onCreate() {
        super.onCreate()
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        createNotificationChannel()
        Log.d(TAG, "LocationService created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "LocationService started")
        startForeground(NOTIFICATION_ID, createNotification())
        startLocationUpdates()
        isRunning = true
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onDestroy() {
        super.onDestroy()
        stopLocationUpdates()
        isRunning = false
        Log.d(TAG, "LocationService destroyed")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Location Service Channel",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Channel for Location Service"
                setShowBadge(false)
                setSound(null, null)
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Location Tracker")
            .setContentText("Tracking location every 5 minutes")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun startLocationUpdates() {
        try {
            // Check for location permissions
            if (checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) 
                != android.content.pm.PackageManager.PERMISSION_GRANTED &&
                checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) 
                != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                Log.e(TAG, "Location permissions not granted")
                return
            }

            // Try GPS first, then Network
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    LOCATION_INTERVAL,
                    MIN_DISTANCE,
                    this
                )
                Log.d(TAG, "Started GPS location updates")
            }

            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    LOCATION_INTERVAL,
                    MIN_DISTANCE,
                    this
                )
                Log.d(TAG, "Started Network location updates")
            }

            // Get last known location immediately
            getLastKnownLocation()

        } catch (ex: SecurityException) {
            Log.e(TAG, "Security exception in startLocationUpdates: ${ex.message}")
        } catch (ex: Exception) {
            Log.e(TAG, "Exception in startLocationUpdates: ${ex.message}")
        }
    }

    private fun stopLocationUpdates() {
        try {
            locationManager.removeUpdates(this)
            Log.d(TAG, "Stopped location updates")
        } catch (ex: SecurityException) {
            Log.e(TAG, "Security exception in stopLocationUpdates: ${ex.message}")
        }
    }

    private fun getLastKnownLocation() {
        try {
            if (checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) 
                != android.content.pm.PackageManager.PERMISSION_GRANTED &&
                checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) 
                != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                return
            }

            val gpsLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            val networkLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)

            val location = when {
                gpsLocation != null && networkLocation != null -> {
                    if (gpsLocation.time > networkLocation.time) gpsLocation else networkLocation
                }
                gpsLocation != null -> gpsLocation
                networkLocation != null -> networkLocation
                else -> null
            }

            location?.let { onLocationChanged(it) }
        } catch (ex: SecurityException) {
            Log.e(TAG, "Security exception in getLastKnownLocation: ${ex.message}")
        }
    }

    override fun onLocationChanged(location: Location) {
        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        val locationInfo = "Lat: ${location.latitude}, Lng: ${location.longitude}\n" +
                "Accuracy: ${location.accuracy}m\n" +
                "Provider: ${location.provider}\n" +
                "Time: $timestamp"

        Log.d(TAG, "Location updated: $locationInfo")
        
        // Update notification
        val notification = createNotification()
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)

        // Send to Flutter app
        locationCallback?.invoke(locationInfo)

        // Here you can also save to database, send to server, etc.
        saveLocationToPreferences(location, timestamp)
    }

    private fun saveLocationToPreferences(location: Location, timestamp: String) {
        val prefs = getSharedPreferences("location_data", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        editor.putString("last_latitude", location.latitude.toString())
        editor.putString("last_longitude", location.longitude.toString())
        editor.putString("last_accuracy", location.accuracy.toString())
        editor.putString("last_timestamp", timestamp)
        editor.putString("last_provider", location.provider ?: "Unknown")
        editor.apply()

        Log.d(TAG, "Location saved to SharedPreferences")
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "LocationTracker::LocationWakeLock"
        )
        wakeLock.acquire(10*60*1000L /*10 minutes - will be renewed*/)
        Log.d(TAG, "WakeLock acquired")
    }

    private fun releaseWakeLock() {
        if (::wakeLock.isInitialized && wakeLock.isHeld) {
            wakeLock.release()
            Log.d(TAG, "WakeLock released")
        }
    }

    private fun saveServiceState(isRunning: Boolean) {
        val prefs = getSharedPreferences("location_service", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("service_was_running", isRunning).apply()
    }

    // Override onTaskRemoved to restart service when app is removed from recents
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "App removed from recents, restarting service")
        
        // Restart the service
        val intent = Intent(applicationContext, LocationService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    fun setLocationCallback(callback: (String) -> Unit) {
        this.locationCallback = callback
    }

    override fun onProviderEnabled(provider: String) {
        Log.d(TAG, "Provider enabled: $provider")
    }

    override fun onProviderDisabled(provider: String) {
        Log.d(TAG, "Provider disabled: $provider")
    }

    @Deprecated("Deprecated in Java")
    override fun onStatusChanged(provider: String?, status: Int, extras: android.os.Bundle?) {
        Log.d(TAG, "Provider status changed: $provider, status: $status")
    }
}