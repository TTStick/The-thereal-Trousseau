package com.ethereal.trousseau.views

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.ethereal.trousseau.components.ScriptTitle
import com.ethereal.trousseau.components.SerifBody
import com.ethereal.trousseau.components.SerifHeadline
import com.ethereal.trousseau.components.paperPrintSubtle
import com.ethereal.trousseau.components.PrintColorFilter
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.services.LocalWardrobeStore
import com.ethereal.trousseau.theme.DangerInk
import com.ethereal.trousseau.theme.Ink
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun SpecimenDetailView(specimenId: String, onClose: () -> Unit) {
    val store = LocalWardrobeStore.current
    val theme = LocalThemeSettings.current
    var refreshKey by remember { mutableStateOf(0) }
    val spec = store.specimens.firstOrNull { it.id == specimenId }
    if (spec == null) { onClose(); return }

    var editingTags by remember(specimenId, refreshKey) { mutableStateOf(spec.tags.joinToString(", ")) }
    var editingNote by remember(specimenId, refreshKey) { mutableStateOf(spec.note) }
    var confirmDelete by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onClose,
        confirmButton = {
            TextButton(onClick = onClose) { SerifHeadline("CLOSE", fontSize = 11.sp) }
        },
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Outlined.Close,
                    contentDescription = "Close",
                    tint = Ink,
                    modifier = Modifier.size(20.dp).clickable { onClose() },
                )
                Spacer(modifier = Modifier.width(8.dp))
                ScriptTitle("Specimen Plate", fontSize = 28.sp, modifier = Modifier.weight(1f))
                Box(modifier = Modifier.size(28.dp).clickable { store.toggleFavorite(specimenId); refreshKey++ }) {
                    Icon(
                        if (spec.isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                        contentDescription = "Favorite",
                        tint = if (spec.isFavorite) DangerInk else Ink.copy(alpha = 0.55f),
                        modifier = Modifier.size(18.dp).align(Alignment.Center),
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                Box(modifier = Modifier.size(28.dp).clickable { confirmDelete = true }) {
                    Icon(
                        Icons.Outlined.Delete,
                        contentDescription = "Delete",
                        tint = DangerInk,
                        modifier = Modifier.size(18.dp).align(Alignment.Center),
                    )
                }
            }
        },
        text = {
            Column(modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState())) {
                val file = remember(spec.image) { store.absolute(spec.image) }
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .aspectRatio(1f)
                        .background(theme.baseColor)
                        .border(1.dp, Ink)
                        .padding(8.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    AsyncImage(
                        model = file,
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        colorFilter = PrintColorFilter,
                        modifier = Modifier
                            .fillMaxSize()
                            .paperPrintSubtle(),
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))
                SerifHeadline("PALETTE", fontSize = 10.sp, letterSpacing = 2.sp)
                Spacer(modifier = Modifier.height(6.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    if (spec.colors.isEmpty()) {
                        SerifBody("No palette yet.", italic = true, color = Ink.copy(alpha = 0.5f), fontSize = 14.sp)
                    } else {
                        spec.colors.forEach { hex ->
                            ColorSwatch(hex)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))
                SerifHeadline("NOTE", fontSize = 10.sp, letterSpacing = 2.sp)
                OutlinedTextField(
                    value = editingNote,
                    onValueChange = { editingNote = it },
                    modifier = Modifier.fillMaxWidth(),
                    textStyle = TextStyle(
                        fontFamily = MaterialTheme.typography.bodyLarge.fontFamily,
                        fontSize = 16.sp, color = Ink,
                    ),
                )

                Spacer(modifier = Modifier.height(8.dp))
                SerifHeadline("TAGS", fontSize = 10.sp, letterSpacing = 2.sp)
                OutlinedTextField(
                    value = editingTags,
                    onValueChange = { editingTags = it },
                    modifier = Modifier.fillMaxWidth(),
                    textStyle = TextStyle(
                        fontFamily = MaterialTheme.typography.bodyLarge.fontFamily,
                        fontSize = 16.sp, color = Ink,
                    ),
                )

                Spacer(modifier = Modifier.height(8.dp))
                TextButton(
                    onClick = {
                        val tags = editingTags.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                        store.updateNote(specimenId, editingNote)
                        store.updateTags(specimenId, tags)
                        refreshKey++
                    },
                ) {
                    SerifHeadline("SAVE", fontSize = 11.sp)
                }

                Spacer(modifier = Modifier.height(8.dp))
                SerifHeadline("WEAR LOG", fontSize = 10.sp, letterSpacing = 2.sp)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    TextButton(onClick = {
                        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                        store.addLog(specimenId, today)
                        refreshKey++
                    }) { SerifHeadline("LOG TODAY", fontSize = 11.sp) }
                    Spacer(modifier = Modifier.width(12.dp))
                    val worn = spec.logs.size
                    SerifBody("Worn $worn times.", fontSize = 14.sp, italic = true, color = Ink.copy(alpha = 0.6f))
                }
                spec.logs.take(6).forEach { date ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        SerifBody("· $date", fontSize = 14.sp, color = Ink.copy(alpha = 0.7f))
                        Spacer(modifier = Modifier.width(8.dp))
                        TextButton(onClick = {
                            store.removeLog(specimenId, date); refreshKey++
                        }) { SerifHeadline("REMOVE", fontSize = 9.sp) }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))
                SerifHeadline("ARCHIVED", fontSize = 10.sp, letterSpacing = 2.sp)
                SerifBody(spec.createdAt, fontSize = 14.sp, color = Ink.copy(alpha = 0.6f))

                spec.purchasePrice?.let { p ->
                    Spacer(modifier = Modifier.height(8.dp))
                    val cpw = spec.costPerWear
                    SerifBody(
                        "¥%.2f per wear".format(p) + (cpw?.let { " · ¥%.2f/wear".format(it) } ?: ""),
                        fontSize = 14.sp, italic = true, color = Ink.copy(alpha = 0.7f),
                    )
                }
            }
        },
    )

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            confirmButton = {
                TextButton(onClick = {
                    store.delete(specimenId)
                    confirmDelete = false
                    onClose()
                }) { SerifHeadline("DELETE", fontSize = 11.sp, color = DangerInk) }
            },
            dismissButton = {
                TextButton(onClick = { confirmDelete = false }) { SerifHeadline("KEEP", fontSize = 11.sp) }
            },
            title = { ScriptTitle("Discard this specimen?", fontSize = 24.sp) },
            text = {
                SerifBody(
                    "This will permanently remove the image and JSON entry from your collection.",
                    italic = true, fontSize = 16.sp, color = Ink.copy(alpha = 0.7f),
                )
            },
        )
    }
}

@Composable
private fun ColorSwatch(hex: String) {
    val color = parseHexColor(hex)
    Box(
        modifier = Modifier
            .size(width = 56.dp, height = 56.dp)
            .background(color)
            .border(0.5.dp, Ink),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = hex.uppercase(),
            color = if (luminance(color) > 0.5f) Ink else Color.White,
            fontSize = 8.sp,
        )
    }
}

private fun parseHexColor(hex: String): Color {
    val s = hex.removePrefix("#")
    val r = s.substring(0, 2).toInt(16)
    val g = s.substring(2, 4).toInt(16)
    val b = s.substring(4, 6).toInt(16)
    return Color(r, g, b)
}

private fun luminance(c: Color): Float =
    0.299f * c.red + 0.587f * c.green + 0.114f * c.blue
