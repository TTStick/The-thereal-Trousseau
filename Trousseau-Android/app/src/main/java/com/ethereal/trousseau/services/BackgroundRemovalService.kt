package com.ethereal.trousseau.services

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Matrix
import com.ethereal.trousseau.TrousseauApplication
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.ByteBufferExtractor
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.imagesegmenter.ImageSegmenter
import com.google.mediapipe.tasks.vision.imagesegmenter.ImageSegmenterResult
import kotlin.math.max
import kotlin.math.min

/**
 * Foreground segmentation for archived specimens.
 *
 * Three iterations live here:
 *
 *  - **v1**: classic edge sampling + flood fill. Works for flat-coloured
 *    backgrounds, fails when a real subject (mannequin, model) is in frame.
 *  - **v2**: ML Kit Subject Segmenter via GMS dynamic modules. Cleaner in
 *    principle, but the model has to be fetched the first time the user
 *    picks a photo — and on locked-down devices (Pixel 6 emulator with no
 *    Play Services access, AOSP builds, offline) the first call returns
 *    null and the user sees the raw photo.
 *  - **v3 (this)**: MediaPipe Tasks Vision ImageSegmenter, with
 *    `selfie_segmentation.tflite` (~244 KB) bundled inside `assets/`. The
 *    model is purpose-trained for portrait / on-figure clothing photos,
 *    which is exactly what comes off the user's camera. No network, no
 *    Play Services, fully on-device.
 *
 * Output pipeline:
 *  1. [process] accepts a Bitmap, downscales it to a sane max dim.
 *  2. ImageSegmenter returns one or more per-pixel confidence masks.
 *  3. We take the first mask (the only one we asked for) and binarise at
 *    0.5 to a 0/1 mask.
 *  4. Build a cut-out bitmap where background pixels are transparent.
 *  5. Letterbox onto a parchment 800×800 canvas at 85% scale — same
 *    presentation as the iOS reference.
 */
object BackgroundRemovalService {

    private const val CANVAS_SIZE = 800
    private const val TARGET_SIZE_PCT = 0.85f
    /**
     * Gamma correction applied to the per-pixel confidence before we use
     * it as an alpha. Slightly below 1 so mid-range (~0.4–0.6) values
     * pull toward 0, which removes the dust speckles from the previous
     * threshold-cut output while preserving a clean feather at the
     * silhouette.
     */
    private const val CONFIDENCE_GAMMA = 0.85f

    @Volatile private var segmenter: ImageSegmenter? = null

    /**
     * Process an input bitmap: segment subject from background and mount on
     * a parchment-coloured square canvas. Mirrors the iOS `process(input:)`
     * flow. Runs synchronously — call from a worker thread.
     */
    fun process(input: Bitmap): Bitmap {
        val src = downscale(input, maxDim = 1024)
        val alpha = segmentForeground(src)
        val cutout = cutOut(src, alpha)
        return composeOnParchment(cutout)
    }

    private fun downscale(src: Bitmap, maxDim: Int): Bitmap {
        val m = max(src.width, src.height)
        if (m <= maxDim) return src
        val scale = maxDim.toFloat() / m
        return Bitmap.createScaledBitmap(
            src,
            (src.width * scale).toInt(),
            (src.height * scale).toInt(),
            true,
        )
    }

    /**
     * Lazily-build the MediaPipe ImageSegmenter from the bundled asset.
     *
     * Returns null if MediaPipe cannot initialise the model (e.g. native
     * library missing on a host CPU). [segmentForeground] falls back to
     * "everything foreground" in that case so the AddSpec sheet still
     * shows something useful.
     */
    private fun ensureSegmenter(): ImageSegmenter? {
        segmenter?.let { return it }
        synchronized(this) {
            segmenter?.let { return it }
            val ctx: Context = TrousseauApplication.instance
            val options = ImageSegmenter.ImageSegmenterOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetPath("selfie_segmentation.tflite")
                        .build()
                )
                .setRunningMode(RunningMode.IMAGE)
                .setOutputConfidenceMasks(true)
                .build()
            val it = try {
                ImageSegmenter.createFromOptions(ctx, options)
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
            segmenter = it
            return it
        }
    }

    /**
     * Run segmentation on [src] and return a binary foreground mask
     * matching [src]'s dimensions.
     */
    private fun segmentForeground(src: Bitmap): FloatArray {
        val seg = ensureSegmenter() ?: return allForeground(src)
        val mpImage = BitmapImageBuilder(src).build()
        val result = try {
            seg.segment(mpImage)
        } catch (e: Exception) {
            e.printStackTrace()
            return allForeground(src)
        }
        return backgroundMaskToAlpha(result, src.width, src.height)
    }

    /**
     * Read the MediaPipe confidence mask and return a float-alpha map of
     * [w]×[h] pixels, with values in `[0, 1]` representing foreground
     * probability (0 = definitely background, 1 = definitely subject).
     *
     * The MediaPipe `selfie_segmentation.tflite` ships its confidence mask
     * inverted — high byte values mark the background, low values mark the
     * subject. We flip and normalise accordingly.
     *
     * We deliberately keep the values soft (no threshold) so [cutOut] can
     * use them as a per-pixel alpha. Hard-thresholding at 0.5 produces a
     * speckled, stair-stepped mask because the 256×256 confidence buffer
     * would then be nearest-neighbour'd up to ~1024×1024.
     */
    private fun backgroundMaskToAlpha(
        result: ImageSegmenterResult,
        w: Int,
        h: Int,
    ): FloatArray {
        val masks = result.confidenceMasks().orElse(null) ?: return allForeground(w, h)
        if (masks.isEmpty()) return allForeground(w, h)
        val maskImage = masks[0]
        val mw = maskImage.width
        val mh = maskImage.height
        val buf = ByteBufferExtractor.extract(maskImage)
        buf.rewind()
        val bytes = ByteArray(buf.remaining())
        buf.get(bytes, 0, bytes.size)
        val small = FloatArray(mw * mh) { i ->
            // mask byte == 0 → subject; mask byte == 255 → background.
            // Flip and normalise to a [0, 1] foreground probability.
            (255 - (bytes[i].toInt() and 0xFF)) / 255f
        }
        return bilinearUpsample(small, mw, mh, w, h)
    }

    private fun allForeground(w: Int, h: Int): FloatArray = FloatArray(w * h) { 1f }
    private fun allForeground(src: Bitmap): FloatArray =
        FloatArray(src.width * src.height) { 1f }

    /**
     * Build a cut-out bitmap where each pixel's alpha is the [alpha] map's
     * foreground confidence. We **don't** threshold: hard-thresholding a
     * 256² mask produces visible 4×4-pixel blocks once it is blown up to
     * 1024². Treating the confidence as a soft alpha gives a clean feather
     * along the dress' silhouette and removes the "speckled" artefact
     * around the model's uncertain pixels.
     *
     * Two tiny knobs tame the small remaining noise:
     *  - `CONFIDENCE_GAMMA` < 1 lifts mid-range values so we don't keep
     *    half-faded pixels that look like dust on the parchment;
     *  - we round the final alpha to 8 bits — 256 levels is plenty for a
     *    visible feather, and avoids the stripy artefact that float
     *    rounding errors would otherwise introduce.
     */
    private fun cutOut(src: Bitmap, alpha: FloatArray): Bitmap {
        val w = src.width
        val h = src.height
        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val pixels = IntArray(w * h)
        for (y in 0 until h) {
            for (x in 0 until w) {
                val i = y * w + x
                val raw = alpha[i].coerceIn(0f, 1f)
                val lifted = if (CONFIDENCE_GAMMA == 1f) raw
                             else Math.pow(raw.toDouble(), CONFIDENCE_GAMMA.toDouble()).toFloat()
                val a8 = (lifted * 255f + 0.5f).toInt().coerceIn(0, 255)
                val srcColor = src.getPixel(x, y)
                pixels[i] = (a8 shl 24) or (srcColor and 0x00FFFFFF)
            }
        }
        out.setPixels(pixels, 0, w, 0, 0, w, h)
        return out
    }

    /**
     * Bilinearly upsample a [sw]×[sh] float grid to [dw]×[dh]. Avoids the
     * 4×4-pixel staircase that nearest-neighbour would produce, which is
     * what made the previous output look "speckled" along edges.
     */
    private fun bilinearUpsample(src: FloatArray, sw: Int, sh: Int, dw: Int, dh: Int): FloatArray {
        val out = FloatArray(dw * dh)
        for (y in 0 until dh) {
            val sy = (y.toFloat() * (sh - 1) / (dh - 1).coerceAtLeast(1))
            val y0 = sy.toInt().coerceIn(0, sh - 1)
            val y1 = (y0 + 1).coerceAtMost(sh - 1)
            val fy = sy - y0
            for (x in 0 until dw) {
                val sx = (x.toFloat() * (sw - 1) / (dw - 1).coerceAtLeast(1))
                val x0 = sx.toInt().coerceIn(0, sw - 1)
                val x1 = (x0 + 1).coerceAtMost(sw - 1)
                val fx = sx - x0
                val v00 = src[y0 * sw + x0]
                val v01 = src[y0 * sw + x1]
                val v10 = src[y1 * sw + x0]
                val v11 = src[y1 * sw + x1]
                val top = v00 * (1 - fx) + v01 * fx
                val bot = v10 * (1 - fx) + v11 * fx
                out[y * dw + x] = top * (1 - fy) + bot * fy
            }
        }
        return out
    }

    private fun powf(value: Float, gamma: Float): Float =
        if (gamma == 1f) value else Math.pow(value.toDouble(), gamma.toDouble()).toFloat()

    private fun composeOnParchment(cutout: Bitmap): Bitmap {
        val w = cutout.width
        val h = cutout.height

        val target = (CANVAS_SIZE * TARGET_SIZE_PCT).toInt()
        val scale = min(target.toFloat() / w, target.toFloat() / h)
        val scaledW = (w * scale).toInt()
        val scaledH = (h * scale).toInt()
        val scaledCutout = Bitmap.createScaledBitmap(cutout, scaledW, scaledH, true)

        val canvasSize = CANVAS_SIZE
        val parchment = Color.rgb(244, 236, 216)
        val result = Bitmap.createBitmap(canvasSize, canvasSize, Bitmap.Config.ARGB_8888)
        val rCanvas = Canvas(result)
        rCanvas.drawColor(parchment)
        val xOffset = (canvasSize - scaledW) / 2
        val yOffset = (canvasSize - scaledH) / 2
        val paint = Paint().apply { isAntiAlias = true }
        rCanvas.drawBitmap(scaledCutout, xOffset.toFloat(), yOffset.toFloat(), paint)
        if (scaledCutout !== cutout) scaledCutout.recycle()
        return result
    }
}