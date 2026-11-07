package org.owasp.mastestapp

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.MotionEvent
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.Toast

class MastgTest(private val context: Context) {

    val shouldRunInMainThread = true

    fun mastgTest(): String {
        val layout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.TRANSPARENT)
        }

        val halfWidth = (context.resources.displayMetrics.widthPixels * 0.5).toInt()

        val buttonParams = LinearLayout.LayoutParams(
            halfWidth,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            topMargin = 24
        }

        val vulnerableButton = Button(context).apply {
            text = "Vulnerable: Confirm Payment"
            setOnClickListener {
                Toast.makeText(context, "Vulnerable button clicked", Toast.LENGTH_SHORT).show()
            }
        }
        layout.addView(vulnerableButton, buttonParams)

        val protectedButton = Button(context).apply {
            text = "Protected: Confirm Payment"
            filterTouchesWhenObscured = true
            setOnClickListener {
                Toast.makeText(context, "Protected button clicked", Toast.LENGTH_SHORT).show()
            }
        }
        layout.addView(protectedButton, buttonParams)

        val customProtectedButton = object : Button(context) {
            override fun onFilterTouchEventForSecurity(event: MotionEvent): Boolean {
                if ((event.flags and MotionEvent.FLAG_WINDOW_IS_OBSCURED) != 0) {
                    Toast.makeText(context, "Blocked obscured touch", Toast.LENGTH_SHORT).show()
                    return false
                }
                return super.onFilterTouchEventForSecurity(event)
            }
        }.apply {
            text = "Custom Protection: Grant Permission"
            setOnClickListener {
                Toast.makeText(context, "Custom protected button clicked", Toast.LENGTH_SHORT).show()
            }
        }
        layout.addView(customProtectedButton, buttonParams)

        (context as? Activity)?.let { activity ->
            val root = activity.findViewById<ViewGroup>(android.R.id.content)
            if (layout.parent == null) {
                root.addView(
                    layout,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    )
                )
            }
        }

        return "Created buttons with various overlay protections"
    }
}