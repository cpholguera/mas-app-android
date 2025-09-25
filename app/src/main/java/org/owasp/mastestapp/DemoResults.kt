package org.owasp.mastestapp

import android.util.Log
import kotlinx.serialization.*
import kotlinx.serialization.json.*

@Serializable
enum class Status {
    FAIL, PASS, ERROR
}

@Serializable
data class DemoResult(
    val status: Status,
    val demoId: String,
    val message: String
)

class DemoResults(private val demoId: String) {
    private val demoResults = mutableListOf<DemoResult>()

    fun add(status: Status, message: String) {
        demoResults.add(DemoResult(status, demoId, message))
        when (status) {
            Status.PASS -> {
                Log.i("MASTG-DEMO", "MASTG-DEMO-$demoId demonstrated a successful test: $message")
            }
            Status.FAIL -> {
                Log.i("MASTG-DEMO", "MASTG-DEMO-$demoId demonstrated a failed test: $message")
            }
            Status.ERROR -> {
                Log.e("MASTG-DEMO", "MASTG-DEMO-$demoId failed: $message")
            }
        }
    }

    fun toJson(): String {
        return Json.encodeToString(demoResults)
    }
}
