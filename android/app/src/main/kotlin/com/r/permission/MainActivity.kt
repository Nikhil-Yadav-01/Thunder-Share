package com.r.permission

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.r.permission/app_manager"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
