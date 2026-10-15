package com.ethereal.trousseau.views

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.OutlinedButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.ethereal.trousseau.components.PrintColorFilter
import com.ethereal.trousseau.components.ScriptTitle
import com.ethereal.trousseau.components.paperPrint
import com.ethereal.trousseau.components.SerifBody
import com.ethereal.trousseau.components.SerifHeadline
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.services.LocalWardrobeStore
import com.ethereal.trousseau.theme.Ink
import kotlin.random.Random

private val ORACLES = listOf(
    "Wear the heaviest linen you own.",
    "Choose what your grandmother would recognise.",
    "Trust the colour you avoided yesterday.",
    "Repeat an old favourite — nothing is owed to novelty.",
    "Dress for the room, not the weather.",
    "Sober palette, one indulgence.",
    "One garment from three years ago, one from this season.",
    "Whatever you reach for first.",
    "Wear the colour that mirrors the morning light.",
    "Pair two textures, never three.",
    "Leave something at home. The shape will still hold.",
    "If you hesitate, choose the older piece.",
)

@Composable
fun CensusView() {
    val store = LocalWardrobeStore.current
    val theme = LocalThemeSettings.current
    val rng = remember { Random(System.currentTimeMillis()) }
    var oracleIndex by remember { mutableStateOf(rng.nextInt(ORACLES.size)) }

    LaunchedEffect(Unit) {
        oracleIndex = rng.nextInt(ORACLES.size)
    }

    val total = store.specimens.size
    val favorites = store.specimens.count { it.isFavorite }
    val wishlist = store.specimens.count { it.wishlist }
    val totalLogs = store.specimens.sumOf { it.logs.size }
    val allTags = store.specimens.flatMap { it.tags }.distinct().sorted()
    val paletteFlattened = store.specimens.flatMap { it.colors }.distinct()
    val totalSpent = store.specimens.mapNotNull { it.purchasePrice }.sum()
    val avgPerWear = store.specimens.mapNotNull { it.costPerWear }.takeIf { it.isNotEmpty() }?.average()

    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 8.dp)) {
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            ScriptTitle("The Census", fontSize = 40.sp)
        }
        SerifBody("A tally of your private collection.", italic = true, fontSize = 14.sp, color = Ink.copy(alpha = 0.6f), modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)

        Spacer(modifier = Modifier.height(16.dp))
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            StatBlock("Specimens", total.toString())
            StatBlock("Favorites", favorites.toString())
            StatBlock("Wishlist", wishlist.toString())
            StatBlock("Worn", totalLogs.toString())
        }
        Spacer(modifier = Modifier.height(8.dp))
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            StatBlock("Tags", allTags.size.toString())
            StatBlock("Hues", paletteFlattened.size.toString())
            StatBlock("Spent", "¥%.0f".format(totalSpent))
            StatBlock("Avg/Wear", avgPerWear?.let { "¥%.1f".format(it) } ?: "—")
        }

        Spacer(modifier = Modifier.height(20.dp))
        SerifHeadline("TAG INVENTORY", fontSize = 10.sp, letterSpacing = 2.sp)
        if (allTags.isEmpty()) {
            SerifBody("No tags yet.", italic = true, color = Ink.copy(alpha = 0.5f), fontSize = 14.sp)
        } else {
            Row(modifier = Modifier.fillMaxWidth().padding(top = 4.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                allTags.take(8).forEach { tag ->
                    TagPill(tag)
                }
            }
            if (allTags.size > 8) {
                SerifBody("+${allTags.size - 8} more", fontSize = 12.sp, italic = true, color = Ink.copy(alpha = 0.5f), modifier = Modifier.padding(top = 6.dp))
            }
        }

        Spacer(modifier = Modifier.height(20.dp))
        SerifHeadline("MOST WORN", fontSize = 10.sp, letterSpacing = 2.sp)
        val top = store.specimens.sortedByDescending { it.logs.size }.take(4)
        if (top.isEmpty() || top.all { it.logs.isEmpty() }) {
            SerifBody("Nothing worn yet — log a date from any specimen.", italic = true, color = Ink.copy(alpha = 0.5f), fontSize = 14.sp)
        } else {
            LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
                items(top, key = { it.id }) { spec ->
                    val file = remember(spec.id) { store.absolute(spec.image) }
                    Box(
                        modifier = Modifier
                            .size(120.dp)
                            .background(theme.baseColor)
                            .border(1.dp, Ink)
                            .padding(6.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        AsyncImage(
            colorFilter = PrintColorFilter,
                            model = file,
                            contentDescription = null,
                            contentScale = ContentScale.Fit,
                            modifier = Modifier
                                .fillMaxSize()
                                .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
                                .paperPrint(),
                        )
                        Box(
                            modifier = Modifier
                                .align(Alignment.TopStart)
                                .background(theme.baseColor.copy(alpha = 0.85f))
                                .padding(horizontal = 4.dp, vertical = 2.dp),
                        ) {
                            SerifHeadline("×${spec.logs.size}", fontSize = 9.sp)
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(theme.baseColor)
                .border(1.dp, Ink)
                .padding(16.dp),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                SerifHeadline("ORACLE", fontSize = 10.sp, letterSpacing = 2.sp, color = Ink.copy(alpha = 0.6f))
                Spacer(modifier = Modifier.height(8.dp))
                ScriptTitle(
                    ORACLES[oracleIndex],
                    fontSize = 22.sp,
                    color = Ink,
                    textAlign = TextAlign.Center,
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(
                        onClick = { oracleIndex = (oracleIndex + 1) % ORACLES.size },
                        border = androidx.compose.foundation.BorderStroke(1.dp, Ink),
                    ) { SerifHeadline("ANOTHER", fontSize = 10.sp) }
                }
            }
        }
        Spacer(modifier = Modifier.height(20.dp))
    }
}

@Composable
private fun StatBlock(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        ScriptTitle(value, fontSize = 26.sp)
        SerifHeadline(label.uppercase(), fontSize = 9.sp, letterSpacing = 1.sp, color = Ink.copy(alpha = 0.6f))
    }
}

@Composable
private fun TagPill(tag: String) {
    val theme = LocalThemeSettings.current
    Box(
        modifier = Modifier
            .background(theme.baseColor)
            .border(0.5.dp, Ink)
            .padding(horizontal = 8.dp, vertical = 4.dp),
    ) {
        SerifHeadline("#${tag.uppercase()}", fontSize = 10.sp)
    }
}
