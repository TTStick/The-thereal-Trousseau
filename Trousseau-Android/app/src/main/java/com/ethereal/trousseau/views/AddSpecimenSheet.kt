package com.ethereal.trousseau.views

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.painter.BitmapPainter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ethereal.trousseau.components.PrintColorFilter
import com.ethereal.trousseau.components.ScriptTitle
import com.ethereal.trousseau.components.paperPrint
import com.ethereal.trousseau.components.SerifBody
import com.ethereal.trousseau.components.SerifHeadline
import com.ethereal.trousseau.models.Specimen
import com.ethereal.trousseau.services.BackgroundRemovalService
import com.ethereal.trousseau.services.ColorPaletteService
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.services.LocalWardrobeStore
import com.ethereal.trousseau.theme.DangerInk
import com.ethereal.trousseau.theme.Ink
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.concurrent.Executors

@Composable
fun AddSpecimenSheet(onDismiss: () -> Unit) {
    val ctx = LocalContext.current
    val store = LocalWardrobeStore.current
    val theme = LocalThemeSettings.current
    val scope = rememberCoroutineScope()
    // Dedicated executor: keep the heavy foreground-segmentation job off the
    // shared Default pool that Compose also uses for rendering. Otherwise a
    // single-core emulator pegs the only Default thread and trips an ANR.
    val bgDispatcher = remember { Executors.newSingleThreadExecutor().asCoroutineDispatcher() }

    var rawBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var processed by remember { mutableStateOf<Bitmap?>(null) }
    var processing by remember { mutableStateOf(false) }
    var note by remember { mutableStateOf("") }
    var tagsField by remember { mutableStateOf(TextFieldValue("")) }
    var error by remember { mutableStateOf<String?>(null) }

    val pickImage = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
        if (uri == null) return@rememberLauncherForActivityResult
        scope.launch {
            try {
                val bytes = withContext(Dispatchers.IO) {
                    ctx.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                } ?: return@launch
                val raw = withContext(Dispatchers.IO) {
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                } ?: return@launch
                rawBitmap = raw
                processing = true
                val result = withContext(bgDispatcher) {
                    BackgroundRemovalService.process(raw)
                }
                processed = result
            } catch (e: Exception) {
                error = e.message
            } finally {
                processing = false
            }
        }
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            Button(
                onClick = onDismiss,
                colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent, contentColor = Ink),
            ) { SerifHeadline("CLOSE", fontSize = 11.sp) }
        },
        title = {
            ScriptTitle(
                "Archive New Specimen",
                fontSize = 28.sp,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center,
            )
        },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .aspectRatio(1f)
                        .background(theme.baseColor)
                        .border(1.dp, Ink),
                    contentAlignment = Alignment.Center,
                ) {
                    val bmp = processed ?: rawBitmap
                    if (bmp != null) {
                        Image(
                            painter = BitmapPainter(bmp.asImageBitmap()),
                            colorFilter = PrintColorFilter,
                            contentDescription = null,
                            contentScale = ContentScale.Fit,
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(8.dp)
                                .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
                                .paperPrint(),
                        )
                    } else {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            SerifBody(
                                if (processing) "Processing on device…" else "Choose a photo to archive.",
                                italic = true,
                                fontSize = 16.sp,
                                color = Ink.copy(alpha = 0.5f),
                                textAlign = TextAlign.Center,
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))

                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(
                        onClick = { pickImage.launch("image/*") },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = theme.baseColor, contentColor = Ink),
                        shape = RoundedCornerShape(0.dp),
                        border = BorderStroke(1.dp, Ink),
                    ) { SerifHeadline("PICK PHOTO", fontSize = 11.sp) }
                    Button(
                        onClick = {
                            val src = rawBitmap ?: return@Button
                            scope.launch {
                                processing = true
                                try {
                                    processed = withContext(bgDispatcher) {
                                        BackgroundRemovalService.process(src)
                                    }
                                } finally {
                                    processing = false
                                }
                            }
                        },
                        modifier = Modifier.weight(1f),
                        enabled = rawBitmap != null && !processing,
                        colors = ButtonDefaults.buttonColors(containerColor = theme.baseColor, contentColor = Ink),
                        shape = RoundedCornerShape(0.dp),
                        border = BorderStroke(1.dp, Ink),
                    ) { SerifHeadline("RE-PROCESS", fontSize = 11.sp) }
                }

                Spacer(modifier = Modifier.height(12.dp))
                SerifHeadline("NOTE", fontSize = 10.sp, letterSpacing = 2.sp)
                OutlinedTextField(
                    value = note,
                    onValueChange = { note = it },
                    modifier = Modifier.fillMaxWidth(),
                    textStyle = TextStyle(
                        fontFamily = MaterialTheme.typography.bodyLarge.fontFamily,
                        fontSize = 16.sp, color = Ink,
                    ),
                )
                Spacer(modifier = Modifier.height(8.dp))
                SerifHeadline("TAGS (comma-separated)", fontSize = 10.sp, letterSpacing = 2.sp)
                OutlinedTextField(
                    value = tagsField.text,
                    onValueChange = { tagsField = TextFieldValue(it) },
                    modifier = Modifier.fillMaxWidth(),
                    textStyle = TextStyle(
                        fontFamily = MaterialTheme.typography.bodyLarge.fontFamily,
                        fontSize = 16.sp, color = Ink,
                    ),
                )

                Spacer(modifier = Modifier.height(12.dp))
                Button(
                    onClick = {
                        val raw = rawBitmap ?: return@Button
                        val proc = processed ?: return@Button
                        scope.launch {
                            try {
                                val id = store.newUUID()
                                val rawBytes = withContext(Dispatchers.IO) {
                                    val baos = java.io.ByteArrayOutputStream()
                                    raw.compress(Bitmap.CompressFormat.JPEG, 92, baos)
                                    baos.toByteArray()
                                }
                                val rawRel = withContext(Dispatchers.IO) { store.saveRaw(rawBytes, id) }
                                val procRel = withContext(Dispatchers.IO) { store.saveProcessed(proc, id) }
                                val colors = withContext(Dispatchers.Default) { ColorPaletteService.palette(proc) }
                                val tags = tagsField.text.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                                val spec = Specimen(
                                    id = id,
                                    image = procRel,
                                    rawImage = rawRel,
                                    note = note,
                                    tags = tags,
                                    colors = colors,
                                    logs = emptyList(),
                                    createdAt = store.nowISO(),
                                )
                                withContext(Dispatchers.IO) { store.append(spec) }
                                onDismiss()
                            } catch (e: Exception) {
                                error = e.message
                            }
                        }
                    },
                    enabled = processed != null && !processing,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Ink, contentColor = theme.baseColor),
                    shape = RoundedCornerShape(0.dp),
                ) {
                    SerifHeadline("ARCHIVE TO COLLECTION", fontSize = 12.sp, color = theme.baseColor)
                }
                error?.let {
                    Spacer(modifier = Modifier.height(8.dp))
                    SerifBody("Error: $it", color = DangerInk, italic = true)
                }
            }
        },
    )
}
