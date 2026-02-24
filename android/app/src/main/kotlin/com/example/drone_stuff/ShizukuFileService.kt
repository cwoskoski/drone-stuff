package com.example.drone_stuff

import java.io.File
import kotlin.system.exitProcess

class ShizukuFileService : IFileService.Stub {

    constructor() : super()

    override fun listFiles(path: String): List<String> {
        val dir = File(path)
        if (!dir.exists() || !dir.isDirectory) return emptyList()
        return dir.listFiles()?.map { it.name } ?: emptyList()
    }

    override fun readFile(path: String): ByteArray {
        val file = File(path)
        if (!file.exists() || !file.isFile) return ByteArray(0)
        return file.readBytes()
    }

    override fun writeFile(path: String, bytes: ByteArray): Boolean {
        return try {
            val file = File(path)
            file.parentFile?.mkdirs()
            file.writeBytes(bytes)
            true
        } catch (e: Exception) {
            false
        }
    }

    override fun fileSize(path: String): Long {
        val file = File(path)
        return if (file.exists()) file.length() else -1L
    }

    override fun exists(path: String): Boolean {
        return File(path).exists()
    }

    override fun deleteFile(path: String): Boolean {
        return try {
            File(path).delete()
        } catch (e: Exception) {
            false
        }
    }

    override fun destroy() {
        exitProcess(0)
    }
}
