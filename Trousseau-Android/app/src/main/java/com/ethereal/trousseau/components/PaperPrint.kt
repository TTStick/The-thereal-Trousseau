package com.ethereal.trousseau.components

import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer

/**
 * Simulates iOS's `mix-blend-mode: multiply` effect that makes a garment
 * image look "printed onto the parchment" rather than sitting on top of
 * it. The iOS SwiftUI port uses `.blendMode(.multiply)`, but Compose
 * 1.7 doesn't expose that modifier. We approximate it by:
 *
 *   1. Compositing the layer offscreen so colours can blend.
 *   2. Desaturating the image (mutes it toward the parchment palette).
 *   3. Drawing the paper texture underneath so it shows through any
 *      natural alpha holes in the image.
 *   4. Slight alpha (0.94) so the warm paper tone gently mixes in.
 *
 * Result: garments look pressed into the page, not stuck on top.
 */
fun Modifier.paperPrint(): Modifier = this
    .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
    .alpha(0.94f)

/**
 * Variant for cards on a single-tone cell — slightly more saturation
 * retained, less alpha loss.
 */
fun Modifier.paperPrintSubtle(): Modifier = this
    .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
    .alpha(0.97f)

/** ColorFilter that desaturates an image to ~78% — used for the gentle "into-paper" feel. */
val PrintColorFilter: ColorFilter
    get() = ColorFilter.colorMatrix(
        ColorMatrix().apply { setToSaturation(0.78f) }
    )

/** ColorFilter that desaturates a little less (0.88) — for spec detail big images. */
val DetailPrintColorFilter: ColorFilter
    get() = ColorFilter.colorMatrix(
        ColorMatrix().apply { setToSaturation(0.88f) }
    )
