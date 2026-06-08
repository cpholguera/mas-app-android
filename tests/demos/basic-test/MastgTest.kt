package org.owasp.mastestapp

import android.content.Context
import android.util.Log

class MastgTest(private val context: Context) {

    val shouldRunInMainThread = false

    fun mastgTest(): String {
        // Demo: basic shared preferences write
        val prefs = context.getSharedPreferences("demo_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("secret_key", "super_secret_value_123").apply()

        val storedValue = prefs.getString("secret_key", "NOT_FOUND")
        Log.d("MastgTest", "Stored value: $storedValue")

        return "SharedPreferences write test completed. Stored value: $storedValue"
    }
}
