package com.ethereal.trousseau.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.theme.Ink
import com.ethereal.trousseau.views.AddSpecimenSheet
import kotlinx.coroutines.delay

/**
 * Camera button that lives in the centre of the bottom bar.
 * Mirrors the iOS AddButton in RootView.swift.
 */
@Composable
fun AddSpecimenButton() {
    val theme = LocalThemeSettings.current
    var sheetVisible by remember { mutableStateOf(false) }
    var pulse by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (pulse) 1.35f else 1.0f,
        animationSpec = tween(durationMillis = 220),
        label = "camera-pulse",
    )

    LaunchedEffect(pulse) {
        if (pulse) {
            delay(120)
            pulse = false
        }
    }

    Box(
        modifier = Modifier
            .size(56.dp)
            .background(theme.baseColor, CircleShape)
            .border(1.dp, Ink, CircleShape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) {
                pulse = true
                sheetVisible = true
            },
        contentAlignment = Alignment.Center,
    ) {
        VintageCameraGlyph(scale = scale)
    }

    if (sheetVisible) {
        AddSpecimenSheet(onDismiss = { sheetVisible = false })
    }
}

@Composable
fun VintageCameraGlyph(scale: Float = 1f) {
    Box(
        modifier = Modifier.size(28.dp, 17.dp),
        contentAlignment = Alignment.Center,
    ) {
        // Body outline
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawRect(color = Ink, style = Stroke(width = 0.9f), size = Size(size.width, size.height))
        }
        // Top viewfinder bump
        Box(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .size(11.dp, 3.5.dp),
        ) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                drawRect(color = Ink, style = Stroke(width = 0.75f), size = Size(size.width, size.height))
            }
        }
        // Lens housing — scales with the shutter animation
        Box(
            modifier = Modifier
                .size(14.dp)
                .scale(scale)
                .border(0.9.dp, Ink, CircleShape),
        )
        // Inner aperture dot
        Box(
            modifier = Modifier
                .size(2.5.dp)
                .background(Ink, CircleShape),
        )
        // Flash bulb top-right
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .offset(x = (-1).dp, y = 1.dp)
                .size(2.5.dp)
                .border(0.6.dp, Ink, CircleShape),
        )
    }
}
