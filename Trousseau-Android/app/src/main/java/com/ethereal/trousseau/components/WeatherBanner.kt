package com.ethereal.trousseau.components

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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AcUnit
import androidx.compose.material.icons.outlined.Cloud
import androidx.compose.material.icons.outlined.NightsStay
import androidx.compose.material.icons.outlined.WbSunny
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.theme.Ink
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import kotlin.math.abs

/**
 * Local "what to wear" hint banner — a nod to iOS WeatherBanner.
 *
 * Doesn't fetch real weather (the iOS port is also offline). It picks a
 * season-appropriate suggestion from a fixed list, rotated by day-of-year,
 * and renders a small icon + a one-line "today's mood" advisory in the
 * same Pinyon/Cormorant typography as the rest of the app.
 */
@Composable
fun WeatherBanner(modifier: Modifier = Modifier) {
    val theme = LocalThemeSettings.current
    val (icon, label) = remember { pickDaily() }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 6.dp)
            .background(theme.baseColor.copy(alpha = 0.55f))
            .border(0.5.dp, Ink.copy(alpha = 0.25f))
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(28.dp)
                .background(theme.baseColor.copy(alpha = 0.8f), CircleShape)
                .border(0.5.dp, Ink.copy(alpha = 0.4f), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = Ink.copy(alpha = 0.7f),
                modifier = Modifier.size(16.dp),
            )
        }
        Spacer(modifier = Modifier.width(10.dp))
        Column(modifier = Modifier.weight(1f)) {
            SerifHeadline("TODAY'S MOOD", fontSize = 9.sp, letterSpacing = 2.sp, color = Ink.copy(alpha = 0.55f))
            Spacer(modifier = Modifier.height(2.dp))
            SerifBody(label, fontSize = 13.sp, italic = true, color = Ink.copy(alpha = 0.75f))
        }
        // Tiny right-side label — the season.
        SerifHeadline(
            text = currentSeasonLabel().uppercase(),
            fontSize = 9.sp,
            letterSpacing = 1.sp,
            color = Ink.copy(alpha = 0.5f),
        )
    }
}

private fun pickDaily(): Pair<ImageVector, String> {
    val cal = Calendar.getInstance()
    val doy = cal.get(Calendar.DAY_OF_YEAR)
    val options = listOf(
        Icons.Outlined.WbSunny to "Sunlight through linen — wear the loosest weave you own.",
        Icons.Outlined.Cloud to "A grey sky: the wardrobe is your only colour.",
        Icons.Outlined.AcUnit to "Cold enough to justify the heavy coat.",
        Icons.Outlined.NightsStay to "Cool evening — a collar, perhaps. No more.",
        Icons.Outlined.WbSunny to "Bright. Reach for the linen and the lightest shoe.",
        Icons.Outlined.Cloud to "Soft, overcast light — pale colours will flatter.",
    )
    val (icon, line) = options[doy % options.size]
    return icon to line
}

private fun currentSeasonLabel(): String {
    val cal = Calendar.getInstance()
    val m = cal.get(Calendar.MONTH) + 1
    return when (m) {
        12, 1, 2 -> "Deep winter"
        3, 4, 5 -> "Early spring"
        6, 7, 8 -> "High summer"
        else -> "Late autumn"
    }
}
