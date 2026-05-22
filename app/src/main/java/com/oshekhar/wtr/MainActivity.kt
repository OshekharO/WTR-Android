package com.oshekhar.wtr

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = ScrollView(this)
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(40, 80, 40, 40)
        }

        val title = TextView(this).apply {
            text = "WTR Android"
            textSize = 28f
            gravity = Gravity.CENTER
        }

        val subtitle = TextView(this).apply {
            text = "Reader API demo project initialized."
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 0)
        }

        val endpoint = TextView(this).apply {
            text = "Endpoint: https://wtr-lab.com/api/reader/get"
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 0)
        }

        container.addView(title)
        container.addView(subtitle)
        container.addView(endpoint)
        root.addView(container)
        setContentView(root)
    }
}
