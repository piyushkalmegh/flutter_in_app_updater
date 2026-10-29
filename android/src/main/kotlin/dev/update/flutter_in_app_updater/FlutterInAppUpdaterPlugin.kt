package dev.update.flutter_in_app_updater

import android.app.Activity
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterInAppUpdaterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel : MethodChannel
    private var activity: Activity? = null
    private lateinit var appUpdateManager: AppUpdateManager
    private lateinit var enterpriseInstaller: EnterpriseInstaller

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_in_app_updater")
        channel.setMethodCallHandler(this)
        appUpdateManager = AppUpdateManagerFactory.create(flutterPluginBinding.applicationContext)

        // Initialize the separate enterprise installer class, passing a lambda to fetch current activity
        enterpriseInstaller = EnterpriseInstaller { activity }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updateAndroid" -> {
                val immediate = call.argument<Boolean>("immediate") ?: true
                val updateType = if (immediate) AppUpdateType.IMMEDIATE else AppUpdateType.FLEXIBLE

                val appUpdateInfoTask = appUpdateManager.appUpdateInfo
                appUpdateInfoTask.addOnSuccessListener { appUpdateInfo: AppUpdateInfo ->
                    if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                        appUpdateInfo.isUpdateTypeAllowed(updateType)) {
                        activity?.let { currentActivity ->
                            appUpdateManager.startUpdateFlowForResult(
                                appUpdateInfo,
                                updateType,
                                currentActivity,
                                1234
                            )
                            result.success(true)
                        } ?: result.error("NO_ACTIVITY", "Current activity is null", null)
                    } else {
                        result.error("NOT_AVAILABLE", "No update available or allowed", null)
                    }
                }.addOnFailureListener { e: Exception ->
                    result.error("UPDATE_ERROR", e.message, null)
                }
            }
            "installApk" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    try {
                        enterpriseInstaller.installApk(path)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_PATH", "The provided APK file path is null.", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}