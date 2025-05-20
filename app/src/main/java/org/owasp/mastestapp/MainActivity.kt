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
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.text.SpanStyle
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.decodeFromJsonElement

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
    val defaultMessage = "Click \"Start\" to run the test.\n\n"
    var displayText by remember { mutableStateOf(buildAnnotatedString { append(defaultMessage) }) }
    val context = LocalContext.current
    val mastgTestClass = MastgTest(context)

    BaseScreen(
        onStartClick = {

            // run the demo
            val r = mastgTestClass.mastgTest()

            displayText = buildAnnotatedString {
                append(defaultMessage)
                try {
                    val jsonArrayFromString = Json.parseToJsonElement(r) as JsonArray
                    val demoResults = jsonArrayFromString.map { Json.decodeFromJsonElement<DemoResult>(it) }

                    for (demoResult in demoResults) {
                        val lineColor = when (demoResult.status) {
                            Status.PASS -> Color.Green
                            Status.FAIL -> Color(0xFFFF9800)
                            Status.ERROR -> Color.Red
                        }
                        withStyle(style = SpanStyle(color = lineColor)) {
                            append("${demoResult.status} ${demoResult.testId}: ${demoResult.message} \n\n")
                        }
                    }
                } catch (e: Exception) {
                    // fallback: not an instances of DemoResult, so print the result without any parsing
                    append(r)
                }
            }
        }
    ) {
        Text(
            modifier = Modifier
                .padding(16.dp)
                .testTag(MASTG_TEXT_TAG),
            text = displayText,
            color = Color.White,
            fontSize = 16.sp,
            fontFamily = FontFamily.Monospace
        )
    }
}