package com.r.permission

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.Inet4Address
import java.net.NetworkInterface

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.r.permission/app_manager"
    private val HOTSPOT_CHANNEL = "com.r.permission/hotspot_manager"

    private var hotspotReservation: WifiManager.LocalOnlyHotspotReservation? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // App Manager Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    Thread {
                        try {
                            val appsList = getInstalledAppsList()
                            runOnUiThread { result.success(appsList) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("ERROR", e.localizedMessage, null) }
                        }
                    }.start()
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        Thread {
                            try {
                                val iconBytes = getAppIconBytes(packageName)
                                runOnUiThread { result.success(iconBytes) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("ERROR", e.localizedMessage, null) }
                            }
                        }.start()
                    } else {
                        result.error("INVALID_ARG", "Package name required", null)
                    }
                }
                "getAppPermissions" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            val flags = PackageManager.GET_PERMISSIONS
                            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(flags.toLong()))
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getPackageInfo(packageName, flags)
                            }
                            val permissions = packageInfo.requestedPermissions?.toList() ?: emptyList<String>()
                            result.success(permissions)
                        } catch (e: Exception) {
                            result.error("ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARG", "Package name required", null)
                    }
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                            if (launchIntent != null) {
                                startActivity(launchIntent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARG", "Package name required", null)
                    }
                }
                "openAppSettings" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARG", "Package name required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Hotspot Manager Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HOTSPOT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startHotspot" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startLocalHotspot(result)
                    } else {
                        result.error("UNSUPPORTED", "Local-Only Hotspot requires Android 8.0+", null)
                    }
                }
                "stopHotspot" -> {
                    stopLocalHotspot()
                    result.success(true)
                }
                "getHotspotStatus" -> {
                    result.success(hotspotReservation != null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startLocalHotspot(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("UNSUPPORTED", "Android 8.0+ required", null)
            return
        }

        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            if (wifiManager == null) {
                result.error("NO_WIFI", "Wi-Fi service unavailable", null)
                return
            }

            // Stop any existing hotspot reservation
            stopLocalHotspot()

            wifiManager.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(reservation: WifiManager.LocalOnlyHotspotReservation?) {
                    super.onStarted(reservation)
                    hotspotReservation = reservation

                    val ssid: String
                    val password: String
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val config = reservation?.softApConfiguration
                        ssid = config?.ssid ?: "DirectShare-Hotspot"
                        password = config?.passphrase ?: ""
                    } else {
                        @Suppress("DEPRECATION")
                        val config = reservation?.wifiConfiguration
                        ssid = config?.SSID ?: "DirectShare-Hotspot"
                        password = config?.preSharedKey ?: ""
                    }

                    val ip = getHotspotIpAddress()
                    val data = mapOf(
                        "ssid" to ssid,
                        "password" to password,
                        "ipAddress" to ip,
                        "status" to "active"
                    )
                    runOnUiThread { result.success(data) }
                }

                override fun onStopped() {
                    super.onStopped()
                    hotspotReservation = null
                }

                override fun onFailed(reason: Int) {
                    super.onFailed(reason)
                    hotspotReservation = null
                    runOnUiThread {
                        result.error("HOTSPOT_FAILED", "Failed to start hotspot. Code: $reason", null)
                    }
                }
            }, Handler(Looper.getMainLooper()))
        } catch (e: SecurityException) {
            result.error("SECURITY_ERROR", "Location/Wi-Fi permission missing: ${e.localizedMessage}", null)
        } catch (e: Exception) {
            result.error("ERROR", e.localizedMessage, null)
        }
    }

    private fun stopLocalHotspot() {
        try {
            hotspotReservation?.close()
        } catch (_: Exception) {}
        hotspotReservation = null
    }

    private fun getHotspotIpAddress(): String {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val netIf = interfaces.nextElement()
                val name = netIf.name.lowercase()
                if (name.contains("ap") || name.contains("wlan") || name.contains("softap") || name.contains("rndis")) {
                    val addrs = netIf.inetAddresses
                    while (addrs.hasMoreElements()) {
                        val addr = addrs.nextElement()
                        if (!addr.isLoopbackAddress && addr is Inet4Address) {
                            val ip = addr.hostAddress
                            if (ip != null && !ip.startsWith("127.")) {
                                return ip
                            }
                        }
                    }
                }
            }
        } catch (_: Exception) {}
        return "192.168.43.1"
    }

    override fun onDestroy() {
        stopLocalHotspot()
        super.onDestroy()
    }

    private fun getInstalledAppsList(): List<Map<String, Any?>> {
        val pm = packageManager
        val flags = PackageManager.GET_META_DATA
        val packages: List<PackageInfo> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(flags.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(flags)
        }

        val appList = mutableListOf<Map<String, Any?>>()
        for (pkg in packages) {
            val appInfo = pkg.applicationInfo ?: continue
            val appName = pm.getApplicationLabel(appInfo).toString()
            val packageName = pkg.packageName
            val versionName = pkg.versionName ?: ""
            val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pkg.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                pkg.versionCode.toLong()
            }
            val apkPath = appInfo.sourceDir ?: ""
            val apkSize = if (apkPath.isNotEmpty()) {
                val file = File(apkPath)
                if (file.exists()) file.length() else 0L
            } else {
                0L
            }
            val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val minSdk = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                appInfo.minSdkVersion
            } else {
                0
            }
            val targetSdk = appInfo.targetSdkVersion

            appList.add(
                mapOf(
                    "name" to appName,
                    "packageName" to packageName,
                    "versionName" to versionName,
                    "versionCode" to versionCode,
                    "apkFilePath" to apkPath,
                    "apkSizeBytes" to apkSize,
                    "isSystemApp" to isSystemApp,
                    "installedTimestamp" to pkg.firstInstallTime,
                    "updatedTimestamp" to pkg.lastUpdateTime,
                    "minSdk" to minSdk,
                    "targetSdk" to targetSdk
                )
            )
        }
        return appList
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        val pm = packageManager
        val drawable = try {
            pm.getApplicationIcon(packageName)
        } catch (e: Exception) {
            return null
        }
        val bitmap = drawableToBitmap(drawable) ?: return null
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap? {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
