package com.ethereal.trousseau.services

import android.graphics.Bitmap
import android.graphics.Color
import kotlin.math.sqrt

/**
 * Extracts a 3-colour palette from an image, mirroring the iOS
 * ColorPaletteService and the web `colorgram.py` pipeline:
 *
 *   1. Downsample to 100×100 (RGBA bytes).
 *   2. Skip fully transparent pixels.
 *   3. K-means with k = max(count+1, 4) clusters.
 *   4. Filter out near-parchment background tones.
 *   5. Return top [count] hex strings, most prominent first.
 */
object ColorPaletteService {

    /**
     * Returns up to [count] hex strings ("#rrggbb") ordered by prominence,
     * with parchment-like background tones filtered out.
     */
    fun palette(image: Bitmap, count: Int = 3): List<String> {
        val target = 100
        val scaled = Bitmap.createScaledBitmap(image, target, target, true)
        val w = scaled.width
        val h = scaled.height
        val pixels = IntArray(w * h)
        scaled.getPixels(pixels, 0, w, 0, 0, w, h)
        scaled.recycle()

        val samples = ArrayList<Rgb>()
        for (c in pixels) {
            val a = Color.alpha(c)
            if (a < 16) continue
            samples.add(
                Rgb(
                    Color.red(c).toFloat(),
                    Color.green(c).toFloat(),
                    Color.blue(c).toFloat(),
                )
            )
        }
        if (samples.size <= 4) return emptyList()

        val k = kotlin.math.max(count + 1, 4)
        val clusters = kmeans(samples, k, iterations = 8)
        val sorted = clusters.sortedByDescending { it.weight }

        // Filter out near-parchment (#f4ecd8 = 244,236,216).
        val filtered = sorted.filter { c ->
            !(c.center.r > 230 && c.center.g > 220 && c.center.b > 200)
        }
        val chosen = (if (filtered.isEmpty()) sorted else filtered).take(count)
        return chosen.map { hex(it.center) }
    }

    // -- internals --

    private data class Rgb(val r: Float, val g: Float, val b: Float)

    private data class Cluster(val center: Rgb, val weight: Int)

    private fun kmeans(samples: List<Rgb>, k: Int, iterations: Int): List<Cluster> {
        if (samples.size < k) {
            return samples.map { Cluster(it, 1) }
        }
        // Deterministic init: pick every n-th sample.
        var centers = ArrayList<Rgb>()
        val step = kotlin.math.max(1, samples.size / k)
        for (i in 0 until k) {
            centers.add(samples[(i * step) % samples.size])
        }
        val assignments = IntArray(samples.size)
        repeat(iterations) {
            var changed = false
            for (i in samples.indices) {
                var bestIdx = 0
                var bestDist = Float.POSITIVE_INFINITY
                for (c in 0 until k) {
                    val d = distSq(samples[i], centers[c])
                    if (d < bestDist) { bestDist = d; bestIdx = c }
                }
                if (assignments[i] != bestIdx) {
                    assignments[i] = bestIdx
                    changed = true
                }
            }
            if (!changed) return@repeat

            val sums = Array(k) { floatArrayOf(0f, 0f, 0f) }
            val counts = IntArray(k)
            for (i in samples.indices) {
                val a = assignments[i]
                sums[a][0] += samples[i].r
                sums[a][1] += samples[i].g
                sums[a][2] += samples[i].b
                counts[a]++
            }
            for (c in 0 until k) {
                if (counts[c] > 0) {
                    centers[c] = Rgb(
                        sums[c][0] / counts[c],
                        sums[c][1] / counts[c],
                        sums[c][2] / counts[c],
                    )
                }
            }
        }
        val weights = IntArray(k)
        for (a in assignments) weights[a]++
        return (0 until k).map { Cluster(centers[it], weights[it]) }
    }

    private fun distSq(a: Rgb, b: Rgb): Float {
        val dr = a.r - b.r; val dg = a.g - b.g; val db = a.b - b.b
        return dr * dr + dg * dg + db * db
    }

    private fun hex(rgb: Rgb): String {
        val r = rgb.r.toInt().coerceIn(0, 255)
        val g = rgb.g.toInt().coerceIn(0, 255)
        val b = rgb.b.toInt().coerceIn(0, 255)
        return String.format("#%02x%02x%02x", r, g, b)
    }
}
