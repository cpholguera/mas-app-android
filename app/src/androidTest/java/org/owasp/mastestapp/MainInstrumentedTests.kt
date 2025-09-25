package org.owasp.mastestapp

import android.util.Log
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsNotDisplayed
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Tests the built in MastgTests.
 */
@RunWith(AndroidJUnit4::class)
class MainInstrumentedTests {
    @get:Rule()
    val composeRule = createComposeRule()

    @Test
    fun runMastgTest() {
        with(composeRule) {
            setContent { MainScreen() }
            val textNode = onNodeWithTag(MASTG_TEXT_TAG)
            textNode.assertTextEquals("Click \"Start\" to run the test.\n\n")
                    .assertIsDisplayed()

            onNodeWithText("Start").performClick()

            textNode.assertIsDisplayed()

            val text = textNode.fetchSemanticsNode().config.getOrNull(SemanticsProperties.Text)?.joinToString() ?: "No text found"
            Log.i("MastgTestOutput", text)
        }
    }

    @Test
    fun runMastgTestWebView() {
        with(composeRule) {
            setContent { WebViewScreen() }
            val textView = onNodeWithText("Click \"Start\" to open the WebView.")
            textView.assertIsDisplayed()

            onNodeWithText("Start").performClick()

            textView.assertIsNotDisplayed()
        }
    }
}