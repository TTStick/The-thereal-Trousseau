package com.ethereal.trousseau

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.ethereal.trousseau.services.LocalWardrobeStore
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.theme.ParchmentTheme
import com.ethereal.trousseau.views.RootView

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val app = application as TrousseauApplication
        setContent {
            ParchmentTheme {
                CompositionLocalProvider(
                    LocalWardrobeStore provides app.wardrobeStore,
                    LocalThemeSettings provides app.themeSettings,
                ) {
                    Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                        RootView()
                    }
                }
            }
        }
    }
}
