package app.tithika.widget

import android.content.Context
import android.content.res.Configuration
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.*
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import app.tithika.MainActivity

class SmallTithikaWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Single

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences(WidgetKeys.PREFS_NAME, Context.MODE_PRIVATE)
        val isDark = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES

        val tithiName       = prefs.getString(WidgetKeys.TITHI_NAME, "—") ?: "—"
        val isShukla        = prefs.getBoolean(WidgetKeys.IS_SHUKLA, true)
        val lunarMonthLabel = prefs.getString(WidgetKeys.LUNAR_MONTH_LABEL, "") ?: ""
        val festivalName    = prefs.getString(WidgetKeys.FESTIVAL_NAME, "") ?: ""
        val rahuActive      = prefs.getBoolean(WidgetKeys.RAHU_ACTIVE, false)
        val rahuLabel    = prefs.getString(WidgetKeys.RAHU_LABEL, "") ?: ""
        val rahuEndTime  = prefs.getString(WidgetKeys.RAHU_END_TIME, "") ?: ""
        val moonPath     = if (isDark)
            prefs.getString(WidgetKeys.MOON_DARK_PATH, null)
        else
            prefs.getString(WidgetKeys.MOON_LIGHT_PATH, null)
        val moonBitmap   = moonPath?.let { BitmapFactory.decodeFile(it) }

        val bgColor       = if (isDark) Color(0xFF0B0F1E) else Color(0xFFF5F0E8)
        val inkSoft       = if (isDark) Color(0xFFAAB0C5) else Color(0xFF4A5070)
        val inkMuted      = if (isDark) Color(0xFF6C7290) else Color(0xFF8890A8)
        val tithiColor    = if (isShukla)
            (if (isDark) Color(0xFFE6B85C) else Color(0xFFC8922A))
        else
            (if (isDark) Color(0xFF7B8EE8) else Color(0xFF5A6BD8))
        val festivalColor = if (isDark) Color(0xFFE07840) else Color(0xFFC05A1A)
        val rahuColor     = if (rahuActive)
            (if (isDark) Color(0xFFD46060) else Color(0xFFB84040))
        else
            inkMuted

        provideContent {
            SmallWidgetContent(
                tithiName       = tithiName,
                lunarMonthLabel = lunarMonthLabel,
                festivalName    = festivalName,
                rahuActive      = rahuActive,
                rahuLabel       = rahuLabel,
                rahuEndTime     = rahuEndTime,
                moonBitmap      = moonBitmap,
                bgColor         = bgColor,
                inkSoft         = inkSoft,
                inkMuted        = inkMuted,
                tithiColor      = tithiColor,
                festivalColor   = festivalColor,
                rahuColor       = rahuColor,
            )
        }
    }
}

@Composable
private fun SmallWidgetContent(
    tithiName: String,
    lunarMonthLabel: String,
    festivalName: String,
    rahuActive: Boolean,
    rahuLabel: String,
    rahuEndTime: String,
    moonBitmap: android.graphics.Bitmap?,
    bgColor: Color,
    inkSoft: Color,
    inkMuted: Color,
    tithiColor: Color,
    festivalColor: Color,
    rahuColor: Color,
) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(bgColor)
            .clickable(actionStartActivity<MainActivity>())
            .padding(horizontal = 8.dp, vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(modifier = GlanceModifier.defaultWeight())

        if (moonBitmap != null) {
            Image(
                provider = ImageProvider(moonBitmap),
                contentDescription = null,
                modifier = GlanceModifier.size(52.dp),
            )
        } else {
            Box(modifier = GlanceModifier.size(52.dp).background(Color(0x22FFFFFF))) {}
        }

        Spacer(modifier = GlanceModifier.height(4.dp))

        Text(
            text = tithiName,
            style = TextStyle(
                color = ColorProvider(tithiColor),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
            ),
            maxLines = 2,
        )

        if (lunarMonthLabel.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(2.dp))
            Text(
                text = lunarMonthLabel,
                style = TextStyle(
                    color = ColorProvider(inkSoft),
                    fontSize = 8.sp,
                    textAlign = TextAlign.Center,
                ),
                maxLines = 1,
            )
        }

        if (festivalName.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(1.dp))
            Text(
                text = "🎉",
                style = TextStyle(
                    color = ColorProvider(festivalColor),
                    fontSize = 9.sp,
                    textAlign = TextAlign.Center,
                ),
            )
        }

        if (rahuLabel.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(4.dp))
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "⚠",
                        style = TextStyle(color = ColorProvider(rahuColor), fontSize = 8.sp),
                    )
                    Spacer(modifier = GlanceModifier.width(3.dp))
                    Text(
                        text = if (rahuActive) "Rahu Kaal · NOW" else "Rahu Kaal",
                        style = TextStyle(
                            color = ColorProvider(rahuColor),
                            fontSize = 8.sp,
                            fontWeight = if (rahuActive) FontWeight.Bold else FontWeight.Normal,
                        ),
                    )
                }
                Spacer(modifier = GlanceModifier.height(1.dp))
                Text(
                    text = if (rahuActive && rahuEndTime.isNotEmpty())
                        "ends $rahuEndTime"
                    else
                        rahuLabel,
                    style = TextStyle(
                        color = ColorProvider(rahuColor),
                        fontSize = 7.sp,
                        textAlign = TextAlign.Center,
                    ),
                )
            }
        }

        Spacer(modifier = GlanceModifier.defaultWeight())

        Text(
            text = "TITHIKA",
            style = TextStyle(
                color = ColorProvider(inkMuted),
                fontSize = 7.sp,
                textAlign = TextAlign.Center,
            ),
        )
    }
}
