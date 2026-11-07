package org.owasp.mastestapp

import android.content.Context
import android.util.Log

class MastgTest(private val context: Context) {

    val shouldRunInMainThread = false

    private var firstSecretValue = System.nanoTime().toInt()
    private var secondSecretValue = context.packageName.length
    private var thirdSecretValue = context.applicationInfo.targetSdkVersion
    private var fourthSecretValue = android.os.Build.VERSION.SDK_INT

    private fun firstHiddenCalculation(input: Int): Int {
        firstSecretValue = firstSecretValue xor input
        return firstSecretValue
    }

    private fun secondHiddenCalculation(input: Int): Int {
        secondSecretValue = secondSecretValue + input
        return secondSecretValue
    }

    private fun thirdHiddenCalculation(input: Int): Int {
        thirdSecretValue = thirdSecretValue xor input
        return thirdSecretValue
    }

    private fun fourthHiddenCalculation(input: Int): Int {
        fourthSecretValue = fourthSecretValue + input
        return fourthSecretValue
    }

    private fun calculateHiddenTotal(seed: Int): Int {
        return firstHiddenCalculation(seed) +
            secondHiddenCalculation(seed + 1) +
            thirdHiddenCalculation(seed + 2) +
            fourthHiddenCalculation(seed + 3)
    }

    fun mastgTest(): String {
        val prefs = context.getSharedPreferences("demo_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("secret_key", "super_secret_value_123").apply()

        val storedValue = prefs.getString("secret_key", "NOT_FOUND")
        val hiddenTotal = calculateHiddenTotal(storedValue?.length ?: 0)

        Log.d("MastgTest", "Stored value: $storedValue, hidden total: $hiddenTotal")

        return "SharedPreferences write test completed. Stored value: $storedValue"
    }
}