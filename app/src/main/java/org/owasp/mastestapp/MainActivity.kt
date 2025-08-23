package org.owasp.mastestapp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

const val MASTG_TEXT_TAG = "mastgTestText"

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MainScreen()
        }
    }
}

@Preview
@Composable
fun MainScreen() {
    var displayString by remember { mutableStateOf("Click \"Start\" to run the test.") }
    val context = LocalContext.current
    val mastgTestClass = MastgTest(context)
    // By default run the test in a separate thread, this ensures that network tests such as those using SSLSocket work properly.
    // However, some tests which interact with UI elements need to run on the main thread.
    // You can set shouldRunInMainThread = true in MastgTest.kt for those tests.
    val runInMainThread = MastgTest::class.members
        .find { it.name == "shouldRunInMainThread" }
        ?.call(mastgTestClass) as? Boolean ?: false

    BaseScreen(
        onStartClick = {
            if (runInMainThread) {
                val result = mastgTestClass.mastgTest()
                displayString = result
            } else {
                Thread {
                    val result = mastgTestClass.mastgTest()
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        displayString = result
                    }
                }.start()
            }
        }
    ) {
        Text(
            modifier = Modifier
                .padding(16.dp)
                .testTag(MASTG_TEXT_TAG),
            text = displayString,
            color = Color.White,
            fontSize = 16.sp,
            fontFamily = FontFamily.Monospace
        )
    }
}
