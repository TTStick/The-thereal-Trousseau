package com.ethereal.trousseau.services

import android.content.Context
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

private val Context.dataStore by preferencesDataStore(name = "trousseau_theme")

private val TEMPERATURE = floatPreferencesKey("temperature") // 0..1 — 0 = cool, 1 = warm
private val DARKNESS = floatPreferencesKey("darkness")       // 0..1
private val TEXTURE = floatPreferencesKey("texture")         // 0..1

/**
 * Mirrors the iOS ThemeSettings: paper warmth / darkness / texture knobs.
 *
 * The values drive a small palette of derived colours:
 *   - baseColor:    the centre of the radial gradient (parchment)
 *   - deepColor:    the corner of the radial gradient
 *   - warmWash:     the diagonal overlay tint
 *
 * Persisted via Jetpack DataStore so settings survive process restarts.
 */
class ThemeSettings(private val appContext: Context) {
    var temperature: Float by mutableStateOf(0.6f)
        private set
    var darkness: Float by mutableStateOf(0.0f)
        private set
    var texture: Float by mutableStateOf(0.7f)
        private set

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    init {
        // Eager-load at construction so the very first composition has the right values.
        runCatching {
            val prefs = runBlocking { appContext.dataStore.data.first() }
            temperature = prefs[TEMPERATURE] ?: 0.6f
            darkness = prefs[DARKNESS] ?: 0.0f
            texture = prefs[TEXTURE] ?: 0.7f
        }
    }

    fun updateTemperature(v: Float) {
        temperature = v.coerceIn(0f, 1f)
        scope.launch { appContext.dataStore.edit { it[TEMPERATURE] = temperature } }
    }

    fun updateDarkness(v: Float) {
        darkness = v.coerceIn(0f, 1f)
        scope.launch { appContext.dataStore.edit { it[DARKNESS] = darkness } }
    }

    fun updateTexture(v: Float) {
        texture = v.coerceIn(0f, 1f)
        scope.launch { appContext.dataStore.edit { it[TEXTURE] = texture } }
    }

    /** Center parchment tone. Warmth shifts toward amber, darkness toward espresso. */
    val baseColor: Color
        get() {
            // Start from #f4ecd8 (244,236,216).
            val r = lerp(244f, 220f, temperature) * (1f - darkness * 0.5f)
            val g = lerp(236f, 188f, temperature) * (1f - darkness * 0.5f)
            val b = lerp(216f, 130f, temperature) * (1f - darkness * 0.5f)
            return Color(r / 255f, g / 255f, b / 255f)
        }

    /** Corner tone, deeper / redder than base. */
    val deepColor: Color
        get() {
            val r = lerp(214f, 150f, temperature) * (1f - darkness * 0.6f)
            val g = lerp(196f, 110f, temperature) * (1f - darkness * 0.6f)
            val b = lerp(168f, 80f, temperature) * (1f - darkness * 0.6f)
            return Color(r / 255f, g / 255f, b / 255f)
        }

    /** Diagonal warm-wash tint applied with low alpha. */
    val warmWash: Color
        get() = Color(
            red = lerp(220f, 240f, temperature) / 255f,
            green = lerp(180f, 180f, temperature) / 255f,
            blue = lerp(110f, 90f, temperature) / 255f,
        )
}

private fun lerp(a: Float, b: Float, t: Float): Float = a + (b - a) * t

val LocalThemeSettings = compositionLocalOf<ThemeSettings> { error("ThemeSettings not provided") }
