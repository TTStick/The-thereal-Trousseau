package com.ethereal.trousseau.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.ethereal.trousseau.R
import com.ethereal.trousseau.services.LocalThemeSettings

// Backwards-compat parchment (updated by theme settings at runtime)
val Ink = Color(0xFF2C2C2C)
val DangerInk = Color(0xFF8A2C2C)
val FadedInk = Ink.copy(alpha = 0.30f)

// Default parchment (matches iOS #f4ecd8)
val DefaultParchment = Color(0xFFF4ECD8)

// Custom font families — Pinyon Script for the brand mark + numbers,
// Cormorant Garamond for body / serif text.
val PinyonScript = FontFamily(
    Font(R.font.pinyon_script, FontWeight.Normal, FontStyle.Normal)
)
val CormorantGaramond = FontFamily(
    Font(R.font.cormorant_garamond, FontWeight.Normal, FontStyle.Normal),
    Font(R.font.cormorant_garamond, FontWeight.Normal, FontStyle.Italic),
    Font(R.font.cormorant_garamond, FontWeight.SemiBold, FontStyle.Normal),
)

private val TrousseauColorScheme = lightColorScheme(
    background = DefaultParchment,
    surface = DefaultParchment,
    primary = Ink,
    onPrimary = DefaultParchment,
    secondary = DangerInk,
    onSecondary = DefaultParchment,
    onBackground = Ink,
    onSurface = Ink,
)

val TrousseauTypography = Typography(
    // Cormorant Garamond body default
    bodyLarge = TextStyle(fontFamily = CormorantGaramond, fontSize = 17.sp),
    bodyMedium = TextStyle(fontFamily = CormorantGaramond, fontSize = 16.sp),
    bodySmall = TextStyle(fontFamily = CormorantGaramond, fontSize = 14.sp),
    titleLarge = TextStyle(fontFamily = CormorantGaramond, fontWeight = FontWeight.SemiBold, fontSize = 20.sp),
    titleMedium = TextStyle(fontFamily = CormorantGaramond, fontSize = 18.sp),
    labelLarge = TextStyle(fontFamily = CormorantGaramond, fontWeight = FontWeight.SemiBold, fontSize = 11.sp, letterSpacing = 2.sp),
)

@Composable
fun ParchmentTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = TrousseauColorScheme,
        typography = TrousseauTypography,
        content = content,
    )
}

// Convenience: current parchment colour (may shift with ThemeSettings.temperature)
@Composable
fun rememberParchmentBase(): Color {
    val s = LocalThemeSettings.current
    return s.baseColor
}

@Composable
fun rememberParchmentDeep(): Color {
    val s = LocalThemeSettings.current
    return s.deepColor
}
