package org.owasp.mastestapp

import android.content.Context
import android.util.Log
import java.net.URL
import javax.net.ssl.HttpsURLConnection

class MastgTest(private val context: Context) {

    val shouldRunInMainThread = false

    fun mastgTest(): String {
        return try {
            val url = URL("https://mas.owasp.org")
            val connection = url.openConnection() as HttpsURLConnection
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            val responseCode = connection.responseCode
            Log.d("MastgTest", "Response code: $responseCode")
            "Network security config test completed. Response code: $responseCode"
        } catch (e: Exception) {
            Log.e("MastgTest", "Connection failed", e)
            "Network security config test: ${e.message}"
        }
    }
}
