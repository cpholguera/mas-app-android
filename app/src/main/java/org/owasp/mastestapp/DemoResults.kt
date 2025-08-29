package org.owasp.mastestapp

import kotlinx.serialization.*
import kotlinx.serialization.json.*

@Serializable
enum class Status {
    FAIL, PASS, ERROR
}

@Serializable
data class DemoResult(
    val status: Status,
    val testId: String,
    val message: String
)

class DemoResults(private val testId: String) {
    private val demoResults = mutableListOf<DemoResult>()

    fun add(status: Status, message: String) {
        demoResults.add(DemoResult(status, "[MASTG-TEST-$testId]", message))
    }

    fun toJson(): String {
        return Json.encodeToString(demoResults)
    }
}
