package com.ethereal.trousseau.services

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.ethereal.trousseau.models.Specimen
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

/**
 * JSON-backed wardrobe persistence, equivalent to the iOS WardrobeStore
 * and the web Flask `wardrobe_db.json`.
 *
 * Storage:
 *   <filesDir>/Trousseau/wardrobe_db.json
 *   <filesDir>/Trousseau/clothes/<uuid>.jpg
 *   <filesDir>/Trousseau/uploads/<uuid>_raw.jpg
 */
class WardrobeStore(private val appContext: Context) {

    private val json = Json {
        ignoreUnknownKeys = true
        prettyPrint = true
        encodeDefaults = true
    }

    private val iso8601: SimpleDateFormat
        get() = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }

    private val ymd: SimpleDateFormat
        get() = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
            timeZone = TimeZone.getDefault()
        }

    private val rootDir: File by lazy {
        File(appContext.filesDir, "Trousseau").apply { mkdirs() }
    }
    private val clothesDir: File by lazy { File(rootDir, "clothes").apply { mkdirs() } }
    private val uploadsDir: File by lazy { File(rootDir, "uploads").apply { mkdirs() } }
    private val dbFile: File by lazy { File(rootDir, "wardrobe_db.json") }

    val specimens: MutableList<Specimen> = mutableStateListOf()
    var loaded: Boolean by mutableStateOf(false)
        private set

    init {
        load()
    }

    fun reload() = load()

    private fun load() {
        try {
            if (!dbFile.exists()) {
                specimens.clear()
                loaded = true
                return
            }
            val text = dbFile.readText(Charsets.UTF_8)
            val list: List<Specimen> = json.decodeFromString(text)
            specimens.clear()
            // Newest first.
            specimens.addAll(list.sortedByDescending { it.createdAt })
        } catch (e: Exception) {
            e.printStackTrace()
            specimens.clear()
        } finally {
            loaded = true
        }
    }

    private fun save() {
        try {
            val text = json.encodeToString(specimens.toList())
            dbFile.writeText(text, Charsets.UTF_8)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun absolute(relPath: String): File = File(rootDir, relPath)

    fun append(s: Specimen) {
        specimens.add(0, s)
        save()
    }

    fun update(s: Specimen) {
        val idx = specimens.indexOfFirst { it.id == s.id }
        if (idx >= 0) {
            specimens[idx] = s
            save()
        }
    }

    fun delete(id: String) {
        val s = specimens.firstOrNull { it.id == id } ?: return
        try {
            absolute(s.image).takeIf { it.exists() }?.delete()
            absolute(s.rawImage).takeIf { it.exists() }?.delete()
        } catch (_: Exception) {}
        specimens.removeAll { it.id == id }
        save()
    }

    fun specimen(id: String): Specimen? = specimens.firstOrNull { it.id == id }

    fun addLog(id: String, date: String) {
        val s = specimen(id) ?: return
        if (!s.logs.contains(date)) {
            val newLogs = (s.logs + date).sortedDescending()
            update(s.copy(logs = newLogs))
        }
    }

    fun removeLog(id: String, date: String) {
        val s = specimen(id) ?: return
        update(s.copy(logs = s.logs.filter { it != date }))
    }

    fun markWornToday(id: String) {
        addLog(id, ymd.format(Date()))
    }

    fun toggleFavorite(id: String) {
        val s = specimen(id) ?: return
        update(s.copy(isFavorite = !s.isFavorite))
    }

    fun toggleWishlist(id: String) {
        val s = specimen(id) ?: return
        update(s.copy(wishlist = !s.wishlist))
    }

    fun updateNote(id: String, note: String) {
        val s = specimen(id) ?: return
        update(s.copy(note = note))
    }

    fun updateTags(id: String, tags: List<String>) {
        val s = specimen(id) ?: return
        update(s.copy(tags = tags))
    }

    fun updateColors(id: String, colors: List<String>) {
        val s = specimen(id) ?: return
        update(s.copy(colors = colors))
    }

    fun updatePurchasePrice(id: String, price: Double?) {
        val s = specimen(id) ?: return
        update(s.copy(purchasePrice = price))
    }

    /** Persist a raw photo (the user-supplied original) and return its relative path. */
    fun saveRaw(rawBytes: ByteArray, uuid: String): String {
        val rel = "uploads/${uuid}_raw.jpg"
        val f = absolute(rel)
        f.writeBytes(rawBytes)
        return rel
    }

    /** Persist a processed image (the parchment-mounted garment) and return its relative path. */
    fun saveProcessed(bitmap: Bitmap, uuid: String, quality: Int = 95): String {
        val rel = "clothes/${uuid}.jpg"
        val f = absolute(rel)
        FileOutputStream(f).use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
        }
        return rel
    }

    fun decodeRelative(rel: String): Bitmap? {
        val f = absolute(rel)
        if (!f.exists()) return null
        return BitmapFactory.decodeFile(f.absolutePath)
    }

    fun newUUID(): String = UUID.randomUUID().toString()
    fun nowISO(): String = iso8601.format(Date())
}

val LocalWardrobeStore = compositionLocalOf<WardrobeStore> { error("WardrobeStore not provided") }
