package com.ethereal.trousseau.views

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ethereal.trousseau.components.CameraGlyph
import com.ethereal.trousseau.components.ScriptTitle
import com.ethereal.trousseau.components.SerifBody
import com.ethereal.trousseau.components.SerifHeadline
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.theme.Ink

@Composable
fun ManifestoView() {
    val theme = LocalThemeSettings.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 24.dp),
    ) {
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            ScriptTitle(
                "The Curator's Manifesto",
                fontSize = 36.sp,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center,
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            CameraGlyph()
        }
        Spacer(modifier = Modifier.height(16.dp))

        SerifBody(
            "A wardrobe is a private museum — and every hanger a curator's note.",
            italic = true,
            fontSize = 18.sp,
            color = Ink.copy(alpha = 0.7f),
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center,
        )

        Spacer(modifier = Modifier.height(24.dp))
        ManifestoParagraph(
            head = "I. ON OWNING",
            body = "Fewer things, better chosen. The collection is small enough to be familiar, large enough to be surprised. Every garment has earned its place by being worn, or by being honestly wanted.",
        )
        Spacer(modifier = Modifier.height(12.dp))
        ManifestoParagraph(
            head = "II. ON KEEPING",
            body = "Every photograph, every JSON byte, every inference happens here on this device. Nothing leaves the cabinet. Nothing needs an account to exist.",
        )
        Spacer(modifier = Modifier.height(12.dp))
        ManifestoParagraph(
            head = "III. ON COLOUR",
            body = "A wardrobe is a palette before it is a closet. The colours you wear tell the room what season you are in, even when the calendar disagrees.",
        )
        Spacer(modifier = Modifier.height(12.dp))
        ManifestoParagraph(
            head = "IV. ON DRESSING",
            body = "Dress slowly. Lay the pieces on the bed before you put them on. Reverse one decision each morning and see what happens by noon.",
        )
        Spacer(modifier = Modifier.height(12.dp))
        ManifestoParagraph(
            head = "V. ON REPAIRING",
            body = "Wear, wash, repair, repeat. A garment with a patched elbow is more interesting than one fresh out of a box.",
        )
        Spacer(modifier = Modifier.height(20.dp))

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(theme.baseColor)
                .border(1.dp, Ink)
                .padding(16.dp),
        ) {
            Column {
                SerifHeadline("CREDITS", fontSize = 10.sp, letterSpacing = 2.sp)
                Spacer(modifier = Modifier.height(6.dp))
                SerifBody("Web: Flask + rembg + colorgram (2024).", fontSize = 14.sp)
                SerifBody("iOS: SwiftUI + Apple Vision + K-means (2026).", fontSize = 14.sp)
                SerifBody("Android: Jetpack Compose + on-device segmentation (2026).", fontSize = 14.sp)
                SerifBody("Fonts: Pinyon Script & Cormorant Garamond (SIL OFL).", fontSize = 14.sp)
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            SerifBody("— fin —", italic = true, fontSize = 16.sp, color = Ink.copy(alpha = 0.5f))
        }
        Spacer(modifier = Modifier.height(40.dp))
    }
}

@Composable
private fun ManifestoParagraph(head: String, body: String) {
    Column {
        SerifHeadline(head, fontSize = 11.sp, letterSpacing = 2.sp)
        Spacer(modifier = Modifier.height(4.dp))
        SerifBody(body, fontSize = 16.sp, color = Ink.copy(alpha = 0.78f))
    }
}
