package com.scripture.scripture

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

            views.setTextViewText(R.id.verse_text, verseText)
            views.setTextViewText(R.id.verse_ref, verseRef)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
