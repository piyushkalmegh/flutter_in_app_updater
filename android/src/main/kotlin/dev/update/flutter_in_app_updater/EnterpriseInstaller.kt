package dev.update.flutter_in_app_updater

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

class EnterpriseInstaller(private val activitySupplier: () -> Activity?) {

    fun installApk(filePath: String) {
        val activity = activitySupplier() ?: throw IllegalStateException("Android Activity context is currently unavailable.")
        val file = File(filePath)

        val intent = Intent(Intent.ACTION_VIEW).apply {
            val uri: Uri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.fileprovider",
                file
            )
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        activity.startActivity(intent)
    }
}