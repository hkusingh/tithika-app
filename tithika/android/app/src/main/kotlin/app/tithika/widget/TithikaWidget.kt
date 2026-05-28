package app.tithika.widget

import android.content.Context
import android.content.res.Configuration
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.*
import androidx.glance.unit.ColorProvider
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.*
import app.tithika.MainActivity

class TithikaWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences(WidgetKeys.PREFS_NAME, Context.MODE_PRIVATE)
        val isDark = context.isDarkMode

        val tithiName        = prefs.getString(WidgetKeys.TITHI_NAME, "—") ?: "—"
        val isShukla         = prefs.getBoolean(WidgetKeys.IS_SHUKLA, true)
        val lunarMonthLabel  = prefs.getString(WidgetKeys.LUNAR_MONTH_LABEL, "") ?: ""
        val festivalName     = prefs.getString(WidgetKeys.FESTIVAL_NAME, "") ?: ""
        val nakshatraName    = prefs.getString(WidgetKeys.NAKSHATRA_NAME, "—") ?: "—"
        val nakshatraUntil   = prefs.getString(WidgetKeys.NAKSHATRA_UNTIL, "") ?: ""
        val sunriseTime      = prefs.getString(WidgetKeys.SUNRISE_TIME, "—") ?: "—"
        val rahuOffsetPct    = prefs.getDoubleAsFloat(WidgetKeys.RAHU_OFFSET_PCT, 0.0)
        val rahuWidthPct     = prefs.getDoubleAsFloat(WidgetKeys.RAHU_WIDTH_PCT, 12.5)
        val nowPct           = prefs.getDoubleAsFloat(WidgetKeys.NOW_PCT, -1.0)
        val rahuActive       = prefs.getBoolean(WidgetKeys.RAHU_ACTIVE, false)
        val rahuLabel        = prefs.getString(WidgetKeys.RAHU_LABEL, "") ?: ""
        val moonPath         = if (isDark)
            prefs.getString(WidgetKeys.MOON_DARK_PATH, null)
        else
            prefs.getString(WidgetKeys.MOON_LIGHT_PATH, null)
        val moonBitmap       = moonPath?.let { BitmapFactory.decodeFile(it) }

        val bgColor      = if (isDark) Color(0xFF0B0F1E) else Color(0xFFF5F0E8)
        val inkColor     = if (isDark) Color(0xFFF3EEDF) else Color(0xFF1A1F3C)
        val inkSoft      = if (isDark) Color(0xFFAAB0C5) else Color(0xFF4A5070)
        val inkMuted     = if (isDark) Color(0xFF6C7290) else Color(0xFF8890A8)
        val dividerColor = if (isDark) Color(0x22FFFFFF) else Color(0x28000000)
        val tithiColor   = if (isShukla)
            (if (isDark) Color(0xFFE6B85C) else Color(0xFFC8922A))
        else
            (if (isDark) Color(0xFF7B8EE8) else Color(0xFF5A6BD8))
        val rahuTrack    = if (isDark) Color(0x22FFFFFF) else Color(0x28000000)
        val rahuFill     = if (rahuActive)
            (if (isDark) Color(0xFFD46060) else Color(0xFFB84040))
        else
            (if (isDark) Color(0x55D46060) else Color(0x55B84040))
        val festivalColor = if (isDark) Color(0xFFE07840) else Color(0xFFC05A1A)

        provideContent {
            val widgetWidth = LocalSize.current.width
            MediumWidgetContent(
                widgetWidth     = widgetWidth,
                tithiName       = tithiName,
                lunarMonthLabel = lunarMonthLabel,
                festivalName    = festivalName,
                nakshatraName   = nakshatraName,
                nakshatraUntil  = nakshatraUntil,
                sunriseTime     = sunriseTime,
                rahuOffsetPct   = rahuOffsetPct,
                rahuWidthPct    = rahuWidthPct,
                nowPct          = nowPct,
                rahuActive      = rahuActive,
                rahuLabel       = rahuLabel,
                moonBitmap      = moonBitmap,
                bgColor         = bgColor,
                inkColor        = inkColor,
                inkSoft         = inkSoft,
                inkMuted        = inkMuted,
                dividerColor    = dividerColor,
                tithiColor      = tithiColor,
                rahuTrack       = rahuTrack,
                rahuFill        = rahuFill,
                festivalColor   = festivalColor,
            )
        }
    }
}

@Composable
private fun MediumWidgetContent(
    widgetWidth: Dp,
    tithiName: String,
    lunarMonthLabel: String,
    festivalName: String,
    nakshatraName: String,
    nakshatraUntil: String,
    sunriseTime: String,
    rahuOffsetPct: Float,
    rahuWidthPct: Float,
    nowPct: Float,
    rahuActive: Boolean,
    rahuLabel: String,
    moonBitmap: android.graphics.Bitmap?,
    bgColor: Color,
    inkColor: Color,
    inkSoft: Color,
    inkMuted: Color,
    dividerColor: Color,
    tithiColor: Color,
    rahuTrack: Color,
    rahuFill: Color,
    festivalColor: Color,
) {
    val hPad = 14.dp

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(bgColor)
            .clickable(actionStartActivity<MainActivity>()),
    ) {
        // ── Top: moon + tithi info ────────────────────────────────────────────
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(start = hPad, end = hPad, top = 12.dp, bottom = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (moonBitmap != null) {
                Image(
                    provider = ImageProvider(moonBitmap),
                    contentDescription = null,
                    modifier = GlanceModifier.size(44.dp),
                )
            } else {
                Box(modifier = GlanceModifier.size(44.dp).background(Color(0x22FFFFFF))) {}
            }

            Spacer(modifier = GlanceModifier.width(10.dp))

            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = tithiName,
                    style = TextStyle(
                        color = ColorProvider(tithiColor),
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )
                if (lunarMonthLabel.isNotEmpty()) {
                    Text(
                        text = lunarMonthLabel,
                        style = TextStyle(
                            color = ColorProvider(inkSoft),
                            fontSize = 10.sp,
                        ),
                        maxLines = 1,
                    )
                }
                if (festivalName.isNotEmpty()) {
                    Text(
                        text = "🎉 $festivalName",
                        style = TextStyle(
                            color = ColorProvider(festivalColor),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Medium,
                        ),
                        maxLines = 1,
                    )
                }
            }
        }

        // ── Divider ───────────────────────────────────────────────────────────
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .height(1.dp)
                .padding(horizontal = hPad)
                .background(dividerColor),
        ) {}

        // ── Info rows ─────────────────────────────────────────────────────────
        Column(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(start = hPad, end = hPad, top = 5.dp),
        ) {
            InfoRow(
                icon = "✦", label = nakshatraName, value = nakshatraUntil,
                inkSoft = inkSoft, inkMuted = inkMuted, inkColor = inkColor,
            )
            Spacer(modifier = GlanceModifier.height(2.dp))
            InfoRow(
                icon = "☀️", label = "Sunrise", value = sunriseTime,
                inkSoft = inkSoft, inkMuted = inkMuted, inkColor = inkColor,
            )
        }

        Spacer(modifier = GlanceModifier.height(5.dp))

        // ── Rahu Kaal bar ─────────────────────────────────────────────────────
        RahuSection(
            widgetWidth   = widgetWidth,
            hPad          = hPad,
            rahuOffsetPct = rahuOffsetPct,
            rahuWidthPct  = rahuWidthPct,
            nowPct        = nowPct,
            rahuActive    = rahuActive,
            rahuLabel     = rahuLabel,
            inkSoft       = inkSoft,
            inkMuted      = inkMuted,
            rahuTrack     = rahuTrack,
            rahuFill      = rahuFill,
        )
    }
}

@Composable
private fun InfoRow(
    icon: String,
    label: String,
    value: String,
    inkSoft: Color,
    inkMuted: Color,
    inkColor: Color,
) {
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = icon,
            style = TextStyle(color = ColorProvider(inkMuted), fontSize = 11.sp),
            modifier = GlanceModifier.width(16.dp),
        )
        Spacer(modifier = GlanceModifier.width(5.dp))
        Text(
            text = label,
            style = TextStyle(color = ColorProvider(inkSoft), fontSize = 10.sp),
            modifier = GlanceModifier.defaultWeight(),
            maxLines = 1,
        )
        Text(
            text = value,
            style = TextStyle(
                color = ColorProvider(inkColor),
                fontSize = 10.sp,
                fontWeight = FontWeight.Medium,
            ),
            maxLines = 1,
        )
    }
}

@Composable
private fun RahuSection(
    widgetWidth: Dp,
    hPad: Dp,
    rahuOffsetPct: Float,
    rahuWidthPct: Float,
    nowPct: Float,
    rahuActive: Boolean,
    rahuLabel: String,
    inkSoft: Color,
    inkMuted: Color,
    rahuTrack: Color,
    rahuFill: Color,
) {
    val trackWidth = (widgetWidth - hPad * 2).coerceAtLeast(0.dp)
    val offsetDp   = trackWidth * (rahuOffsetPct / 100f).coerceIn(0f, 1f)
    val fillDp     = trackWidth * (rahuWidthPct  / 100f).coerceIn(0f, 1f)
    val rightDp    = (trackWidth - offsetDp - fillDp).coerceAtLeast(0.dp)

    Column(modifier = GlanceModifier.fillMaxWidth().padding(horizontal = hPad)) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "⚠",
                style = TextStyle(color = ColorProvider(inkMuted), fontSize = 10.sp),
                modifier = GlanceModifier.width(16.dp),
            )
            Spacer(modifier = GlanceModifier.width(5.dp))
            Text(
                text = "Rahu Kaal",
                style = TextStyle(color = ColorProvider(inkSoft), fontSize = 10.sp),
                modifier = GlanceModifier.defaultWeight(),
            )
            if (rahuActive) {
                Text(
                    text = "NOW",
                    style = TextStyle(
                        color = ColorProvider(rahuFill),
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
                Spacer(modifier = GlanceModifier.width(4.dp))
            }
            Text(
                text = rahuLabel,
                style = TextStyle(color = ColorProvider(inkMuted), fontSize = 9.sp),
            )
        }

        Spacer(modifier = GlanceModifier.height(4.dp))

        // Bar track with Rahu fill at the correct position
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .height(5.dp)
                .background(rahuTrack),
        ) {
            if (offsetDp > 0.dp) {
                Box(modifier = GlanceModifier.width(offsetDp).fillMaxHeight()) {}
            }
            Box(
                modifier = GlanceModifier
                    .width(fillDp)
                    .fillMaxHeight()
                    .background(rahuFill),
            ) {}
            if (rightDp > 0.dp) {
                Box(modifier = GlanceModifier.width(rightDp).fillMaxHeight()) {}
            }
        }

        Spacer(modifier = GlanceModifier.height(10.dp))
    }
}

private val Context.isDarkMode: Boolean
    get() = resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES

// home_widget stores Dart doubles as raw Long bits via doubleToRawLongBits.
private fun android.content.SharedPreferences.getDoubleAsFloat(key: String, default: Double): Float {
    val bits = getLong(key, java.lang.Double.doubleToRawLongBits(default))
    return java.lang.Double.longBitsToDouble(bits).toFloat()
}
