package com.ethereal.trousseau.components

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp
import com.ethereal.trousseau.theme.CormorantGaramond
import com.ethereal.trousseau.theme.Ink
import com.ethereal.trousseau.theme.PinyonScript

/**
 * Script-style title (Pinyon Script), used for h1, brand mark, and specimen
 * numbers — matches iOS Font.scriptTitle().
 */
@Composable
fun ScriptTitle(
    text: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 48.sp,
    color: androidx.compose.ui.graphics.Color = Ink,
    textAlign: TextAlign? = null,
    maxLines: Int = Int.MAX_VALUE,
) {
    Text(
        text = text,
        modifier = modifier,
        color = color,
        textAlign = textAlign,
        maxLines = maxLines,
        style = TextStyle(
            fontFamily = PinyonScript,
            fontSize = fontSize,
            fontWeight = FontWeight.Normal,
            fontStyle = FontStyle.Normal,
        ),
    )
}

/** Cormorant Garamond body / serif. Matches iOS Font.serifBody(). */
@Composable
fun SerifBody(
    text: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 17.sp,
    italic: Boolean = false,
    color: androidx.compose.ui.graphics.Color = Ink,
    textAlign: TextAlign? = null,
) {
    Text(
        text = text,
        modifier = modifier,
        color = color,
        textAlign = textAlign,
        style = TextStyle(
            fontFamily = CormorantGaramond,
            fontSize = fontSize,
            fontStyle = if (italic) FontStyle.Italic else FontStyle.Normal,
            fontWeight = FontWeight.Normal,
        ),
    )
}

/** Cormorant Garamond SemiBold, used for headlines and small caps labels. */
@Composable
fun SerifHeadline(
    text: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 11.sp,
    letterSpacing: TextUnit = 2.sp,
    color: androidx.compose.ui.graphics.Color = Ink,
    textAlign: TextAlign? = null,
) {
    Text(
        text = text,
        modifier = modifier,
        color = color,
        textAlign = textAlign,
        style = TextStyle(
            fontFamily = CormorantGaramond,
            fontSize = fontSize,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = letterSpacing,
        ),
    )
}
