package com.ethereal.trousseau.views

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.ethereal.trousseau.components.PrintColorFilter
import com.ethereal.trousseau.components.ScriptTitle
import com.ethereal.trousseau.components.paperPrint
import com.ethereal.trousseau.components.SerifBody
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.services.LocalWardrobeStore
import com.ethereal.trousseau.theme.Ink

private data class PlacedSpecimen(
    val id: String,
    var x: Float = 0f,
    var y: Float = 0f,
    var scale: Float = 1f,
    var rotation: Float = 0f,
)

@Composable
fun CollageCanvasView() {
    val store = LocalWardrobeStore.current
    val theme = LocalThemeSettings.current
    val placed = remember { mutableStateListOf<PlacedSpecimen>() }

    LaunchedEffect(store.specimens.toList()) {
        placed.clear()
        store.specimens.take(6).forEachIndexed { i, spec ->
            val cols = 3
            val r = i / cols
            val c = i % cols
            placed.add(
                PlacedSpecimen(
                    id = spec.id,
                    x = (c - 1) * 110f + r * 30f,
                    y = (r - 1) * 130f,
                    rotation = ((i * 17) % 11 - 5).toFloat(),
                    scale = 1f,
                )
            )
        }
    }

    Column(modifier = Modifier.fillMaxSize().padding(top = 16.dp)) {
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            ScriptTitle("Moodboard", fontSize = 36.sp)
        }
        SerifBody(
            "Drag specimens to arrange. Add via + (camera).",
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            fontSize = 14.sp,
            italic = true,
            color = Ink.copy(alpha = 0.55f),
        )

        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
                .background(theme.baseColor)
                .border(1.dp, Ink),
            contentAlignment = Alignment.Center,
        ) {
            if (placed.isEmpty()) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    SerifBody("Moodboard is empty.", italic = true, color = Ink.copy(alpha = 0.5f))
                    SerifBody("Archive some specimens to start arranging.", italic = true, fontSize = 12.sp, color = Ink.copy(alpha = 0.45f))
                }
            }
            placed.forEach { item ->
                CollageItem(item, store) { dx, dy ->
                    val idx = placed.indexOfFirst { it.id == item.id }
                    if (idx >= 0) placed[idx] = item.copy(x = item.x + dx, y = item.y + dy)
                }
            }
        }
    }
}

@Composable
private fun CollageItem(item: PlacedSpecimen, store: com.ethereal.trousseau.services.WardrobeStore, onDrag: (Float, Float) -> Unit) {
    val spec = store.specimens.firstOrNull { it.id == item.id } ?: return
    val file = remember(spec.image) { store.absolute(spec.image) }
    Box(
        modifier = Modifier
            .size(140.dp)
            .graphicsLayer {
                translationX = item.x
                translationY = item.y
                scaleX = item.scale
                scaleY = item.scale
                rotationZ = item.rotation
            }
            .pointerInput(item.id) {
                detectDragGestures { _, drag -> onDrag(drag.x, drag.y) }
            },
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Transparent)
                .border(1.dp, Ink),
            contentAlignment = Alignment.Center,
        ) {
            AsyncImage(
            colorFilter = PrintColorFilter,
                model = file,
                contentDescription = null,
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(6.dp)
                    .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
                    .paperPrint(),
            )
        }
    }
}
