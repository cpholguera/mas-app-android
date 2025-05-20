package org.owasp.mastestapp

import android.util.Log
import android.content.Context

class MastgTest (private val context: Context){

    fun mastgTest(): String {
        val r = DemoResults("0000")

        try {
            val sensitiveString = "Hello from the OWASP MASTG Test app."
            Log.d("MASTG-TEST", sensitiveString)

            // case 1: Demo implements a case which fails a test
            r.add(Status.FAIL, "The app implemented a demo which failed the test." )

            // case 2: Demo implements a case which passes a test
            r.add(Status.PASS, "The app implemented a demo which passed the test with the following value: '$sensitiveString'" )

            throw Exception("Something went wrong during the demo.")
        }
        catch (e: Exception){
            // case 3: Demo fails due to an exception.
            r.add(Status.ERROR, e.toString())
        }
        return r.toJson()
    }

}
