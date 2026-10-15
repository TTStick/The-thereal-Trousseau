package com.ethereal.trousseau

import android.app.Application
import com.ethereal.trousseau.services.ThemeSettings
import com.ethereal.trousseau.services.WardrobeStore

class TrousseauApplication : Application() {
    val wardrobeStore: WardrobeStore by lazy { WardrobeStore(this) }
    val themeSettings: ThemeSettings by lazy { ThemeSettings(this) }

    companion object {
        /** Global handle for utilities that run outside the Compose tree. */
        lateinit var instance: TrousseauApplication
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }
}
