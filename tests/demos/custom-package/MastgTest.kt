package org.owasp.mastestapp

import android.content.Context
import android.util.Log

class MastgTest(private val context: Context) {

    val shouldRunInMainThread = false

    fun mastgTest(): String {
        val filesDir = context.filesDir
        val testFile = java.io.File(filesDir, "test_data.txt")
        testFile.writeText("Custom package demo: sensitive data written to internal storage")

        val content = testFile.readText()
        Log.d("MastgTest", "File content: $content")

        return "Custom package test completed. File: ${testFile.absolutePath}"
    }
}
