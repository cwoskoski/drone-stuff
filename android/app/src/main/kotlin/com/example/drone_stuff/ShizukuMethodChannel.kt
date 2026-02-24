package com.example.drone_stuff

import android.content.ComponentName
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.IBinder
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import rikka.shizuku.Shizuku.UserServiceArgs

class ShizukuMethodChannel(
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler {

    private var fileService: IFileService? = null
    private var permissionResult: MethodChannel.Result? = null

    private val binderReceivedListener = Shizuku.OnBinderReceivedListener {
        bindUserService()
    }

    private val binderDeadListener = Shizuku.OnBinderDeadListener {
        fileService = null
    }

    private val permissionResultListener =
        Shizuku.OnRequestPermissionResultListener { requestCode, grantResult ->
            if (requestCode == PERMISSION_REQUEST_CODE) {
                val granted = grantResult == PackageManager.PERMISSION_GRANTED
                if (granted) bindUserService()
                permissionResult?.success(granted)
                permissionResult = null
            }
        }

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            fileService = IFileService.Stub.asInterface(binder)
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            fileService = null
        }
    }

    private val userServiceArgs = UserServiceArgs(
        ComponentName(
            BuildConfig.APPLICATION_ID,
            ShizukuFileService::class.java.name
        )
    )
        .daemon(false)
        .processNameSuffix("file_service")
        .debuggable(BuildConfig.DEBUG)
        .version(BuildConfig.VERSION_CODE)

    fun register() {
        channel.setMethodCallHandler(this)
        Shizuku.addBinderReceivedListenerSticky(binderReceivedListener)
        Shizuku.addBinderDeadListener(binderDeadListener)
        Shizuku.addRequestPermissionResultListener(permissionResultListener)
    }

    fun unregister() {
        channel.setMethodCallHandler(null)
        Shizuku.removeBinderReceivedListener(binderReceivedListener)
        Shizuku.removeBinderDeadListener(binderDeadListener)
        Shizuku.removeRequestPermissionResultListener(permissionResultListener)
        try {
            Shizuku.unbindUserService(userServiceArgs, serviceConnection, true)
        } catch (_: Exception) {}
        fileService = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getShizukuState" -> result.success(getShizukuState())
            "requestShizukuPermission" -> requestPermission(result)
            "listFiles" -> withService(result) { svc ->
                val path = call.argument<String>("path")!!
                result.success(svc.listFiles(path))
            }
            "readFile" -> withService(result) { svc ->
                val path = call.argument<String>("path")!!
                result.success(svc.readFile(path))
            }
            "writeFile" -> withService(result) { svc ->
                val path = call.argument<String>("path")!!
                val bytes = call.argument<ByteArray>("bytes")!!
                result.success(svc.writeFile(path, bytes))
            }
            "fileSize" -> withService(result) { svc ->
                val path = call.argument<String>("path")!!
                result.success(svc.fileSize(path))
            }
            "exists" -> withService(result) { svc ->
                val path = call.argument<String>("path")!!
                result.success(svc.exists(path))
            }
            "deleteFile" -> withService(result) { svc ->
                val path = call.argument<String>("path")!!
                result.success(svc.deleteFile(path))
            }
            else -> result.notImplemented()
        }
    }

    private fun getShizukuState(): String {
        return try {
            if (!Shizuku.pingBinder()) "not_running"
            else if (Shizuku.checkSelfPermission() != PackageManager.PERMISSION_GRANTED) "permission_needed"
            else "ready"
        } catch (_: Exception) {
            "not_installed"
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        try {
            if (!Shizuku.pingBinder()) {
                result.success(false)
                return
            }
            if (Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
                bindUserService()
                result.success(true)
                return
            }
            permissionResult = result
            Shizuku.requestPermission(PERMISSION_REQUEST_CODE)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun bindUserService() {
        try {
            if (Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
                Shizuku.bindUserService(userServiceArgs, serviceConnection)
            }
        } catch (_: Exception) {}
    }

    private inline fun withService(
        result: MethodChannel.Result,
        block: (IFileService) -> Unit
    ) {
        val svc = fileService
        if (svc == null) {
            result.error("NO_SERVICE", "Shizuku service not connected", null)
            return
        }
        try {
            block(svc)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", e.message, null)
        }
    }

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
    }
}
