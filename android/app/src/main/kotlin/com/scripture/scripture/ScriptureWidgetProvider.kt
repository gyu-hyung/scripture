package com.jgh.malsseumdonghaeng

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ScriptureWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.scripture_widget)

            val verseText = widgetData.getString("verse_text", "여호와는 나의 목자시니 내게 부족함이 없으리로다")
            val verseRef = widgetData.getString("verse_ref", "시편 23:1")
            val themeId = widgetData.getString("widget_theme", "modern_dark")

            // 테마에 따른 색상 설정
            val bgColor: Int
            val textColor: Int
            val accentColor: Int

            when (themeId) {
                "minimalist_light" -> {
                    bgColor = android.graphics.Color.parseColor("#F8F9FA")
                    textColor = android.graphics.Color.parseColor("#2D2D2D")
                    accentColor = android.graphics.Color.parseColor("#0D47A1")
                }
                "serene_blue" -> {
                    bgColor = android.graphics.Color.parseColor("#0D47A1")
                    textColor = android.graphics.Color.parseColor("#FFFFFF")
                    accentColor = android.graphics.Color.parseColor("#BBDEFB")
                }
                "nature_green" -> {
                    bgColor = android.graphics.Color.parseColor("#2E7D32")
                    textColor = android.graphics.Color.parseColor("#FFFFFF")
                    accentColor = android.graphics.Color.parseColor("#C8E6C9")
                }
                else -> { // modern_dark
                    bgColor = android.graphics.Color.parseColor("#15151C")
                    textColor = android.graphics.Color.parseColor("#FFFFFF")
                    accentColor = android.graphics.Color.parseColor("#B8860B")
                }
            }

            views.setInt(R.id.widget_container, "setBackgroundColor", bgColor)
            views.setTextViewText(R.id.verse_text, verseText)
            views.setTextColor(R.id.verse_text, textColor)
            views.setTextViewText(R.id.verse_ref, verseRef)
            views.setTextColor(R.id.verse_ref, accentColor)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
