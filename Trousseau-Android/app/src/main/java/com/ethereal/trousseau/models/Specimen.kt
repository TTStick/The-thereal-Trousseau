package com.ethereal.trousseau.models

import kotlinx.serialization.Serializable

/**
 * One archived garment. Mirrors the JSON shape used by the web + iOS versions.
 * Stored in the application's internal files dir as `wardrobe_db.json`.
 */
@Serializable
data class Specimen(
    val id: String,
    /** Processed, background-removed image. Relative path under app files dir. */
    var image: String,
    /** Original raw photo, kept so the user can re-process. */
    var rawImage: String,
    var note: String = "",
    var tags: List<String> = emptyList(),
    /** Hex colors (e.g. "#8b5a3d"), first is the most prominent. */
    var colors: List<String> = emptyList(),
    /** ISO yyyy-MM-dd strings — when this garment was worn. */
    var logs: List<String> = emptyList(),
    /** ISO-8601 instant the specimen was archived. */
    var createdAt: String,
    /** Original purchase price (CNY). Optional. */
    var purchasePrice: Double? = null,
    var isFavorite: Boolean = false,
    var wishlist: Boolean = false,
) {
    val wornCount: Int get() = logs.size

    val costPerWear: Double?
        get() {
            val p = purchasePrice ?: return null
            if (logs.isEmpty()) return null
            return p / logs.size
        }
}
