package com.ethereal.trousseau.views

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.ethereal.trousseau.components.PrintColorFilter
import com.ethereal.trousseau.components.ScriptTitle
import com.ethereal.trousseau.components.paperPrint
import com.ethereal.trousseau.components.SerifBody
import com.ethereal.trousseau.components.SerifHeadline
import com.ethereal.trousseau.components.WeatherBanner
import com.ethereal.trousseau.models.Specimen
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.services.LocalWardrobeStore
import com.ethereal.trousseau.theme.DangerInk
import com.ethereal.trousseau.theme.Ink

private enum class GalleryFilter { All, Favorites, Wishlist }

@Composable
fun GalleryView() {
    val store = LocalWardrobeStore.current
    val theme = LocalThemeSettings.current
    var search by remember { mutableStateOf("") }
    var filter by remember { mutableStateOf(GalleryFilter.All) }
    var selectedTags by remember { mutableStateOf(setOf<String>()) }
    var presented by remember { mutableStateOf<String?>(null) }
    var showSettings by remember { mutableStateOf(false) }

    val allTags = remember(store.specimens.toList()) {
        store.specimens.flatMap { it.tags }.distinct().sorted()
    }

    val filtered = remember(store.specimens.toList(), search, filter, selectedTags) {
        var pool = store.specimens.toList()
        when (filter) {
            GalleryFilter.Favorites -> pool = pool.filter { it.isFavorite }
            GalleryFilter.Wishlist -> pool = pool.filter { it.wishlist }
            GalleryFilter.All -> Unit
        }
        if (selectedTags.isNotEmpty()) {
            pool = pool.filter { s -> s.tags.any { it in selectedTags } }
        }
        if (search.isNotEmpty()) {
            val q = search.lowercase()
            pool = pool.filter {
                it.note.lowercase().contains(q) ||
                it.tags.joinToString(" ").lowercase().contains(q)
            }
        }
        pool
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxWidth()) {
            // Weather banner — peeks in with a soft fade.
            AnimatedVisibility(
                visible = true,
                enter = fadeIn(tween(600)) + expandVertically(spring(stiffness = 120f)),
                exit = fadeOut() + shrinkVertically(),
            ) {
                WeatherBanner()
            }

            ScriptTitle(
                text = "The Ethereal Trousseau",
                modifier = Modifier.fillMaxWidth().wrapContentSize(Alignment.Center).padding(top = 8.dp),
                fontSize = 40.sp,
                textAlign = TextAlign.Center,
                maxLines = 1,
            )

            Row(
                modifier = Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                    BasicTextField(
                        value = search,
                        onValueChange = { search = it },
                        singleLine = true,
                        textStyle = TextStyle(
                            fontFamily = MaterialTheme.typography.bodyLarge.fontFamily,
                            fontSize = 17.sp,
                            color = com.ethereal.trousseau.theme.Ink,
                            textAlign = TextAlign.Center,
                        ),
                        modifier = Modifier.fillMaxWidth(),
                        decorationBox = { inner ->
                            Box(contentAlignment = Alignment.Center) {
                                if (search.isEmpty()) {
                                    SerifBody("Search Archives...", color = com.ethereal.trousseau.theme.Ink.copy(alpha = 0.45f), fontSize = 17.sp)
                                }
                                inner()
                            }
                        },
                    )
                }
                Box(
                    modifier = Modifier.size(36.dp).clickable { showSettings = true },
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Settings,
                        contentDescription = "Settings",
                        tint = com.ethereal.trousseau.theme.Ink,
                        modifier = Modifier.size(18.dp),
                    )
                }
            }
            Canvas(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp).height(1.dp)) {
                drawRect(color = com.ethereal.trousseau.theme.Ink, size = Size(size.width, 1f))
            }
            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                GalleryFilter.values().forEach { f ->
                    FilterChipX(
                        label = f.name,
                        selected = filter == f,
                        onClick = { filter = f },
                    )
                }
            }
            Spacer(modifier = Modifier.height(10.dp))

            if (allTags.isNotEmpty()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = 24.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    allTags.forEach { tag ->
                        val on = tag in selectedTags
                        FilterChipX(
                            label = "#${tag.uppercase()}",
                            selected = on,
                            small = true,
                            onClick = {
                                selectedTags = if (on) selectedTags - tag else selectedTags + tag
                            },
                        )
                    }
                }
                Spacer(modifier = Modifier.height(10.dp))
            }

            Canvas(modifier = Modifier.fillMaxWidth().height(4.dp)) {
                drawRect(color = com.ethereal.trousseau.theme.Ink, topLeft = Offset(0f, 0f), size = Size(size.width, 1f))
                drawRect(color = com.ethereal.trousseau.theme.Ink, topLeft = Offset(0f, 3f), size = Size(size.width, 1f))
            }
        }

        if (filtered.isEmpty()) {
            EmptyGalleryState()
        } else {
            LazyVerticalGrid(
                columns = GridCells.Adaptive(minSize = 160.dp),
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                items(filtered, key = { it.id }) { spec ->
                    val idx = filtered.indexOf(spec)
                    GalleryCell(spec, filtered.size - idx) { presented = spec.id }
                }
            }
        }
    }

    presented?.let { id ->
        SpecimenDetailView(specimenId = id, onClose = { presented = null })
    }
    if (showSettings) {
        SettingsSheet(onClose = { showSettings = false })
    }
}

@Composable
private fun FilterChipX(label: String, selected: Boolean, small: Boolean = false, onClick: () -> Unit) {
    val theme = LocalThemeSettings.current
    val pad = if (small) 4.dp else 5.dp
    Box(
        modifier = Modifier
            .border(0.75.dp, com.ethereal.trousseau.theme.Ink)
            .background(if (selected) com.ethereal.trousseau.theme.Ink else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = if (small) 10.dp else 12.dp, vertical = pad),
        contentAlignment = Alignment.Center,
    ) {
        SerifHeadline(
            text = label.uppercase(),
            fontSize = if (small) 10.sp else 11.sp,
            letterSpacing = if (small) 1.sp else 2.sp,
            color = if (selected) theme.baseColor else com.ethereal.trousseau.theme.Ink,
        )
    }
}

@Composable
private fun EmptyGalleryState() {
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(modifier = Modifier.weight(1f))
        SerifBody("Collection Empty", italic = true, fontSize = 20.sp, color = com.ethereal.trousseau.theme.Ink.copy(alpha = 0.6f))
        Spacer(modifier = Modifier.height(8.dp))
        SerifBody(
            "Tap the camera to archive your first garment.",
            italic = true,
            fontSize = 16.sp,
            color = com.ethereal.trousseau.theme.Ink.copy(alpha = 0.5f),
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.weight(2f))
    }
}

@Composable
private fun GalleryCell(spec: Specimen, number: Int, onClick: () -> Unit) {
    val theme = LocalThemeSettings.current
    val store = LocalWardrobeStore.current
    val file = remember(spec.image) { store.absolute(spec.image) }
    var pressed by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.97f else 1f,
        animationSpec = spring(stiffness = 320f, dampingRatio = 0.55f),
        label = "cell-press",
    )
    Column(
        modifier = Modifier
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .clickable {
                pressed = true
                onClick()
            },
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .background(theme.baseColor)
                .border(1.dp, com.ethereal.trousseau.theme.Ink)
                .padding(8.dp),
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
            if (spec.isFavorite) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(6.dp)
                        .size(28.dp)
                        .background(theme.baseColor.copy(alpha = 0.85f), CircleShape)
                        .border(0.75.dp, com.ethereal.trousseau.theme.Ink, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = Icons.Filled.Favorite,
                        contentDescription = null,
                        tint = DangerInk,
                        modifier = Modifier.size(14.dp),
                    )
                }
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        ScriptTitle("No. $number", fontSize = 20.sp)
    }
}
