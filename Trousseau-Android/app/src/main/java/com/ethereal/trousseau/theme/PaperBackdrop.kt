package com.ethereal.trousseau.theme

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.ethereal.trousseau.services.LocalThemeSettings
import kotlin.math.hypot
import kotlin.math.sin
import kotlin.random.Random

/**
 * Stands in for the SwiftUI `PaperBackdrop`: a layered "real paper" surface.
 *
 * - Radial vignette (centre → corner) using [theme.baseColor] / [theme.deepColor].
 * - Diagonal warm wash scaled by [theme.texture].
 * - Long sepia fibre strands (warm brown) — "deckled edge" feel.
 * - Speckled sepia flecks.
 * - Fine dark hairline grain (equivalent of the web SVG noise).
 *
 * All layers are drawn in their own Canvas so each one is composited on
 * the paper colour rather than overwriting it. The Canvas is composited
 * back with `BlendMode.Multiply` (when supported) so the texture tints
 * the parchment rather than sitting on top of it.
 */
@Composable
fun PaperBackdrop(modifier: Modifier = Modifier) {
    val theme = LocalThemeSettings.current
    Box(modifier = modifier.fillMaxSize()) {
        // Single lightweight parchment layer — keeps Compose repaint cost
        // down so input dispatch never trips a 5s ANR while the heavy
        // foreground-segmentation job is running.
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawRect(
                brush = Brush.radialGradient(
                    colors = listOf(theme.baseColor, theme.deepColor),
                    center = Offset(size.width / 2f, size.height / 2f),
                    radius = hypot(size.width, size.height) * 0.55f,
                )
            )
            if (theme.texture > 0.02f) {
                drawRect(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            theme.warmWash.copy(alpha = 0.10f * theme.texture),
                            Color.Transparent,
                            theme.deepColor.copy(alpha = 0.12f * theme.texture),
                        ),
                        start = Offset(0f, 0f),
                        end = Offset(size.width, size.height),
                    )
                )
            }
        }
    }
}

private fun DrawScope.drawFibres(strength: Float) {
    // Long, thin, hand-drawn fibre lines. Drawn with slight rotation
    // so the page looks like the inside of an old book.
    val density = ((size.width * size.height) / 14000f * strength).toInt()
    val darken = (1.0f - strength * 0.25f).coerceIn(0f, 1f)
    val rng = Random(0xF1B8E1)
    repeat(density) {
        val x = rng.nextFloat() * size.width
        val y = rng.nextFloat() * size.height
        val len = 12f + rng.nextFloat() * 24f
        val angle = (rng.nextFloat() - 0.5f) * 30f
        val tone = Color(
            red = ((168f / 255f) * darken + rng.nextFloat() * 0.06f - 0.03f).coerceIn(0f, 1f),
            green = ((124f / 255f) * darken + rng.nextFloat() * 0.06f - 0.03f).coerceIn(0f, 1f),
            blue = ((82f / 255f) * darken + rng.nextFloat() * 0.06f - 0.03f).coerceIn(0f, 1f),
        )
        val alpha = (rng.nextFloat() * 0.15f + 0.10f) * strength
        rotate(degrees = angle, pivot = Offset(x, y)) {
            drawLine(
                color = tone.copy(alpha = alpha),
                start = Offset(x - len / 2, y),
                end = Offset(x + len / 2, y),
                strokeWidth = 0.7f + rng.nextFloat() * 0.4f,
            )
        }
    }
}

private fun DrawScope.drawFlecks(strength: Float) {
    // Round, soft sepia flecks.
    val density = ((size.width * size.height) / 320f * strength).toInt()
    val darken = (1.0f - strength * 0.25f).coerceIn(0f, 1f)
    val rng = Random(0xC0FFEE)
    repeat(density) {
        val x = rng.nextFloat() * size.width
        val y = rng.nextFloat() * size.height
        val r = rng.nextFloat() * 1.6f + 0.5f
        val tone = Color(
            red = ((148f / 255f) * darken + rng.nextFloat() * 0.12f - 0.06f).coerceIn(0f, 1f),
            green = ((110f / 255f) * darken + rng.nextFloat() * 0.12f - 0.06f).coerceIn(0f, 1f),
            blue = ((62f / 255f) * darken + rng.nextFloat() * 0.12f - 0.06f).coerceIn(0f, 1f),
        )
        val alpha = (rng.nextFloat() * 0.30f + 0.18f) * strength
        drawCircle(color = tone.copy(alpha = alpha), radius = r, center = Offset(x, y))
    }
}

private fun DrawScope.drawNoiseOverlay(strength: Float) {
    val count = ((size.width * size.height) / 8f * strength).toInt()
    val rng = Random(0xBADBEEF)
    repeat(count) {
        val x = rng.nextFloat() * size.width
        val y = rng.nextFloat() * size.height
        val a = (rng.nextFloat() * 0.10f + 0.06f) * strength * 0.85f
        drawRect(
            color = Ink.copy(alpha = a),
            topLeft = Offset(x, y),
            size = Size(1f, 1f),
        )
    }
}

/**
 * Double-line bordered "frame" matching the iOS ParchmentFrame and the
 * web `frame.html` card style.
 */
@Composable
fun ParchmentFrame(
    modifier: Modifier = Modifier,
    doubleLine: Boolean = true,
    contentPadding: Dp = if (doubleLine) 12.dp else 8.dp,
    content: @Composable () -> Unit,
) {
    Box(modifier = modifier.background(LocalThemeSettings.current.baseColor)) {
        Box(modifier = Modifier.fillMaxSize().padding(contentPadding)) {
            content()
        }
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawRect(
                color = Ink,
                style = Stroke(width = 1f),
                size = Size(size.width, size.height),
            )
            if (doubleLine) {
                drawRect(
                    color = Ink,
                    style = Stroke(width = 1f),
                    topLeft = Offset(2f, 2f),
                    size = Size(size.width - 4f, size.height - 4f),
                )
            }
        }
    }
}

// Used in tests for randomness seeding — not exposed.
internal fun sinAmplitude(t: Float) = sin(t)
