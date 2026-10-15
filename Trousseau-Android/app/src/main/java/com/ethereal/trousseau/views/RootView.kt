package com.ethereal.trousseau.views

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.RowScope
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Layers
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material.icons.outlined.PhotoLibrary
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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ethereal.trousseau.components.AddSpecimenButton
import com.ethereal.trousseau.services.LocalThemeSettings
import com.ethereal.trousseau.theme.Ink
import com.ethereal.trousseau.theme.PaperBackdrop

enum class RootTab { Collection, Collage, Census, About }

private val BottomBarHeight = 64.dp
private val CameraLift = 18.dp
private val CameraSize = 56.dp
private val IndicatorHeight = 2.dp
private val IndicatorWidthFraction = 0.30f

@Composable
fun RootView() {
    var tab by remember { mutableStateOf(RootTab.Collection) }
    val tabIndex = tab.ordinal

    Box(modifier = Modifier.fillMaxSize()) {
        PaperBackdrop()

        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = BottomBarHeight + CameraLift)
        ) {
            when (tab) {
                RootTab.Collection -> GalleryView()
                RootTab.Collage -> CollageCanvasView()
                RootTab.Census -> CensusView()
                RootTab.About -> ManifestoView()
            }
        }

        // The bottom bar is anchored to the bottom of the outer Box via .align().
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter),
        ) {
            BottomBar(
                totalWidth = LocalDensity.current.run { /* placeholder */ androidx.compose.ui.unit.Dp.Unspecified },
                selectedIndex = tabIndex,
                onTabChange = { tab = it },
            )
        }
    }
}

/**
 * Bottom nav with sliding indicator + centre camera button.
 * The caller must place this inside a parent that's been measured (i.e. after
 * the surrounding Box has measured maxWidth). We use BoxWithConstraints to
 * peek at the parent's available width so the indicator offset is exact.
 */
@Composable
private fun BoxWithConstraintsScopePlaceholder() = Unit

@Composable
private fun BottomBar(
    @Suppress("UNUSED_PARAMETER") totalWidth: androidx.compose.ui.unit.Dp,
    selectedIndex: Int,
    onTabChange: (RootTab) -> Unit,
) {
    val theme = LocalThemeSettings.current
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxWidth()
            .height(BottomBarHeight + CameraLift),
    ) {
        val totalWidthPx = with(LocalDensity.current) { maxWidth.toPx() }
        val cameraWidthPx = with(LocalDensity.current) { (CameraSize + 12.dp).toPx() }
        val tabAreaWidthPx = totalWidthPx - cameraWidthPx
        val tabWidthPx = tabAreaWidthPx / 4f
        val indicatorWidthPx = tabWidthPx * IndicatorWidthFraction

        // Bar background
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(BottomBarHeight)
                .align(Alignment.BottomCenter)
                .background(theme.baseColor),
        )
        // 1-px divider above the bar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
                .align(Alignment.TopStart)
                .background(Ink),
        )

        val tabs = listOf(RootTab.Collection, RootTab.Collage, RootTab.Census, RootTab.About)
        val targetCenterX = tabWidthPx * (selectedIndex + 0.5f) +
                if (selectedIndex >= 2) cameraWidthPx / 2f else 0f
        val animatedCenterX by animateFloatAsState(
            targetValue = targetCenterX,
            animationSpec = spring(stiffness = 200f, dampingRatio = 0.7f),
            label = "indicator-x",
        )
        Box(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .offset {
                    androidx.compose.ui.unit.IntOffset(
                        x = (animatedCenterX - indicatorWidthPx / 2f).toInt(),
                        y = -IndicatorHeight.roundToPx(),
                    )
                }
                .size(
                    width = with(LocalDensity.current) { indicatorWidthPx.toDp() },
                    height = IndicatorHeight,
                )
                .background(Ink),
        )

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(BottomBarHeight)
                .align(Alignment.BottomCenter),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            tabs.forEachIndexed { i, t ->
                BottomTabButton(
                    icon = when (t) {
                        RootTab.Collection -> Icons.Outlined.PhotoLibrary
                        RootTab.Collage -> Icons.Outlined.Layers
                        RootTab.Census -> Icons.Outlined.MenuBook
                        RootTab.About -> Icons.Outlined.Info
                    },
                    label = t.name,
                    selected = i == selectedIndex,
                    onClick = { onTabChange(t) },
                )
            }
        }

        Box(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .offset(y = -CameraLift)
                .size(CameraSize),
            contentAlignment = Alignment.Center,
        ) {
            AddSpecimenButton()
        }
    }
}

@Composable
private fun RowScope.BottomTabButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
) {
    val tint = if (selected) Ink else Ink.copy(alpha = 0.55f)
    Box(
        modifier = Modifier
            .weight(1f)
            .height(BottomBarHeight)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = tint,
                modifier = Modifier
                    .size(20.dp)
                    .graphicsLayer {
                        scaleX = if (selected) 1.08f else 1f
                        scaleY = if (selected) 1.08f else 1f
                    },
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelLarge.copy(letterSpacing = 1.sp),
                color = tint,
            )
        }
    }
}
