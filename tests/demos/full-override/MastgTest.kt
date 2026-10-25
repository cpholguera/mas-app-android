package org.owasp.mastestapp

import android.content.Context
import android.util.Log
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties

class MastgTest(private val context: Context) {

    val shouldRunInMainThread = false

    fun mastgTest(): String {
        val results = StringBuilder()

        // Test 1: Write sensitive data to internal storage
        val internalFile = File(context.filesDir, "sensitive_data.txt")
        internalFile.writeText("password=admin123")
        results.appendLine("Internal storage write: ${internalFile.absolutePath}")

        // Test 2: SharedPreferences
        val prefs = context.getSharedPreferences("secure_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("api_token", "tok_1234567890abcdef").apply()
        results.appendLine("SharedPreferences write completed")

        // Test 3: Log sensitive data (intentional bad practice for demo)
        Log.d("MastgTest", "Token: tok_1234567890abcdef")
        results.appendLine("Logging test completed")

        return results.toString().trim()
    }
}
