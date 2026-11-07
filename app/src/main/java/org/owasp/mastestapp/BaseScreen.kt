package org.owasp.mastestapp


import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Preview
@Composable
fun BaseScreen(
    onStartClick: () -> Unit = {},
    content: @Composable () -> Unit = {},
) {
    Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
        Column(
            modifier =  Modifier.fillMaxSize()
                .padding(innerPadding)
                .padding(16.dp, 8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Display the app name from strings.xml
                Text(
                    text = stringResource(R.string.app_name),
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.SansSerif
                )

                // Button to update the display string
                CustomGradientButton(
                    onClick = onStartClick
                )
            }

            // Content area
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(top = 16.dp)
                    .background(Color.DarkGray, RoundedCornerShape(8.dp))
                    .verticalScroll(rememberScrollState())
            ) {
                content()
            }
        }

    }
}

@Composable
fun CustomGradientButton(onClick: () -> Unit) {
    val gradientBrush = Brush.linearGradient(
        colors = listOf(
            Color(0xFF02D6A9), // rgb(2, 214, 169)
            Color(0xFF479FFF)  // rgb(71, 159, 255)
        )
    )

    Button(
        onClick = onClick,
        modifier = Modifier
            .background(gradientBrush, shape = RoundedCornerShape(30.dp))
            .padding(),
        colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent)
    ) {
        Text(text = "Start", fontFamily = FontFamily.SansSerif, fontSize = 14.sp,)
    }
}