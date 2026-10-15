package com.ethereal.trousseau.views

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ethereal.trousseau.components.ScriptTitle
import com.ethereal.trousseau.components.SerifBody
import com.ethereal.trousseau.components.SerifHeadline
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.theme.Ink
import com.ethereal.trousseau.theme.PaperBackdrop

@Composable
fun SettingsSheet(onClose: () -> Unit) {
    val theme = LocalThemeSettings.current

    AlertDialog(
        onDismissRequest = onClose,
        confirmButton = {
            TextButton(onClick = onClose) { SerifHeadline("CLOSE", fontSize = 11.sp) }
        },
        title = {
            ScriptTitle("Paper Atelier", fontSize = 28.sp, modifier = Modifier.fillMaxWidth())
        },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(80.dp)
                        .background(theme.baseColor)
                        .border(1.dp, Ink),
                ) {
                    PaperBackdrop(modifier = Modifier.fillMaxWidth().height(80.dp))
                }
                Spacer(modifier = Modifier.height(12.dp))
                SerifHeadline("WARMTH", fontSize = 10.sp, letterSpacing = 2.sp)
                Slider(
                    value = theme.temperature,
                    onValueChange = { theme.updateTemperature(it) },
                    valueRange = 0f..1f,
                )
                SerifBody(
                    "Shift the parchment between candlelit amber and cool linen.",
                    italic = true, fontSize = 13.sp, color = Ink.copy(alpha = 0.6f),
                )

                Spacer(modifier = Modifier.height(12.dp))
                SerifHeadline("DARKNESS", fontSize = 10.sp, letterSpacing = 2.sp)
                Slider(
                    value = theme.darkness,
                    onValueChange = { theme.updateDarkness(it) },
                    valueRange = 0f..1f,
                )
                SerifBody(
                    "Pulls the page toward espresso for evening reading.",
                    italic = true, fontSize = 13.sp, color = Ink.copy(alpha = 0.6f),
                )

                Spacer(modifier = Modifier.height(12.dp))
                SerifHeadline("FIBRE", fontSize = 10.sp, letterSpacing = 2.sp)
                Slider(
                    value = theme.texture,
                    onValueChange = { theme.updateTexture(it) },
                    valueRange = 0f..1f,
                )
                SerifBody(
                    "How much visible paper grain to show.",
                    italic = true, fontSize = 13.sp, color = Ink.copy(alpha = 0.6f),
                )
            }
        },
    )
}
