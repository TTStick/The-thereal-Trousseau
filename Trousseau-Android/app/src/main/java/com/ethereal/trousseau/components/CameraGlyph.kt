package com.ethereal.trousseau.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.ethereal.trousseau.theme.Ink

/**
 * A simple vintage-camera glyph: body + top viewfinder bump + lens circle.
 * Used as a brand mark on the About / Manifesto screen.
 */
@Composable
fun CameraGlyph() {
    Canvas(modifier = Modifier.size(60.dp, 36.dp)) {
        // Body
        drawRect(color = Ink, style = Stroke(width = 1.5f), size = Size(size.width, size.height))
        // Top viewfinder bump
        val bumpW = size.width * 0.4f
        val bumpH = size.height * 0.18f
        drawRect(
            color = Ink,
            style = Stroke(width = 1.2f),
            topLeft = androidx.compose.ui.geometry.Offset((size.width - bumpW) / 2, 0f),
            size = Size(bumpW, bumpH),
        )
        // Lens
        val lensR = size.height * 0.3f
        drawCircle(color = Ink, style = Stroke(width = 1.5f), radius = lensR,
            center = androidx.compose.ui.geometry.Offset(size.width / 2, size.height * 0.62f))
        drawCircle(color = Ink, radius = lensR * 0.18f,
            center = androidx.compose.ui.geometry.Offset(size.width / 2, size.height * 0.62f))
        // Flash bulb top-right
        drawCircle(color = Ink, style = Stroke(width = 1f), radius = size.height * 0.08f,
            center = androidx.compose.ui.geometry.Offset(size.width * 0.84f, size.height * 0.32f))
    }
}
