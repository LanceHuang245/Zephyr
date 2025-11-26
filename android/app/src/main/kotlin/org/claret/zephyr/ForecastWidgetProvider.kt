package org.claret.zephyr

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.graphics.Color
import android.util.Log
import java.text.SimpleDateFormat
import java.util.*

class ForecastWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "ForecastWidget"

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                // 从SharedPreferences获取7日预报数据
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                val widgetDataStr = prefs.getString("flutter.flutter.forecast_widget_data", null)

                var cityName = "--"
                val forecastList = mutableListOf<ForecastDay>()

                if (widgetDataStr != null && widgetDataStr.isNotEmpty()) {
                    try {
                        val widgetData = org.json.JSONObject(widgetDataStr)
                        cityName = widgetData.optString("city_name", "--")

                        val forecastArray = widgetData.optJSONArray("forecast_data")
                        if (forecastArray != null) {
                            for (i in 0 until minOf(forecastArray.length(), 7)) {
                                val dayData = forecastArray.getJSONObject(i)
                                forecastList.add(ForecastDay(
                                    date = dayData.optString("date", ""),
                                    weatherCode = dayData.optInt("weather_code", 0),
                                    weatherDesc = dayData.optString("weather_desc", ""),
                                    tempMax = dayData.optString("temp_max", "--"),
                                    tempMin = dayData.optString("temp_min", "--")
                                ))
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error parsing forecast widget data: $e")
                    }
                }

                // 确保有7天数据，如果没有则使用默认数据
                while (forecastList.size < 7) {
                    val defaultDay = ForecastDay(
                        date = "--",
                        weatherCode = 0,
                        weatherDesc = "--",
                        tempMax = "--",
                        tempMin = "--"
                    )
                    forecastList.add(defaultDay)
                }

                // 创建RemoteViews
                val views = RemoteViews(context.packageName, R.layout.forecast_widget)

                // 设置城市名称
                views.setTextViewText(R.id.forecast_city_name, cityName)

                // 设置7日预报数据
                for (i in forecastList.indices) {
                    val day = forecastList[i]
                    val dayNumber = i + 1

                    // 设置日期
                    views.setTextViewText(
                        context.resources.getIdentifier("forecast_date_$dayNumber", "id", context.packageName),
                        formatDate(day.date)
                    )

                    // 设置天气图标
                    views.setImageViewResource(
                        context.resources.getIdentifier("forecast_icon_$dayNumber", "id", context.packageName),
                        getWeatherIcon(day.weatherCode)
                    )

                    // 设置温度
                    views.setTextViewText(
                        context.resources.getIdentifier("forecast_temp_$dayNumber", "id", context.packageName),
                        "${day.tempMin}/${day.tempMax}"
                    )
                }

                // 根据第一个天气代码设置背景
                val primaryWeatherCode = if (forecastList.isNotEmpty()) forecastList[0].weatherCode else 0
                setWidgetBackground(views, primaryWeatherCode)

                // 创建点击意图
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.forecast_widget_container, pendingIntent)

                // 更新小部件
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating forecast widget", e)
            }
        }

        private fun formatDate(dateStr: String): String {
            return try {
                if (dateStr.isEmpty()) return "--"

                val inputFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                val date = inputFormat.parse(dateStr) ?: return "--"

                val calendar = Calendar.getInstance()
                val today = Calendar.getInstance()
                today.time = Date()

                calendar.time = date

                val dayOfWeek = SimpleDateFormat("E", Locale.getDefault()).format(date)

                // 如果是今天或明天，显示特殊标识
                when {
                    calendar.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
                    calendar.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR) -> "今天"

                    calendar.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
                    calendar.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR) + 1 -> "明天"

                    else -> dayOfWeek
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error formatting date: $e")
                "--"
            }
        }

        private fun getWeatherIcon(weatherCode: Int): Int {
            return when (weatherCode) {
                0 -> R.drawable.ic_weather_sunny // 晴天
                1, 2 -> R.drawable.ic_weather_cloudy // 多云 (中空云)
                3 -> R.drawable.ic_weather_overcast // 阴天 (实心云)
                45, 48 -> R.drawable.ic_weather_foggy // 雾天 (线条)
                51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82 -> R.drawable.ic_weather_rainy // 雨天
                71, 73, 75, 77, 85, 86 -> R.drawable.ic_weather_snowy // 雪天
                95, 96, 99 -> R.drawable.ic_weather_thunder // 雷暴
                else -> R.drawable.ic_weather_default // 默认
            }
        }

        private fun setWidgetBackground(views: RemoteViews, weatherCode: Int) {
            when (weatherCode) {
                0 -> {
                    // 晴天 - 蓝色渐变
                    views.setInt(R.id.forecast_widget_container, "setBackgroundResource", R.drawable.widget_gradient_background)
                }
                1, 2 -> {
                    // 多云 - 浅蓝色渐变
                    views.setInt(R.id.forecast_widget_container, "setBackgroundResource", R.drawable.widget_gradient_background)
                }
                3 -> {
                    // 阴天 - 深灰色渐变
                    views.setInt(R.id.forecast_widget_container, "setBackgroundResource", R.drawable.widget_thunder_gradient)
                }
                45, 48 -> {
                    // 雾天 - 深灰色渐变
                    views.setInt(R.id.forecast_widget_container, "setBackgroundResource", R.drawable.widget_thunder_gradient)
                }
                51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82 -> {
                    // 雨天 - 深蓝色渐变
                    views.setInt(R.id.forecast_widget_container, "setBackgroundResource", R.drawable.widget_rainy_gradient)
                }
                71, 73, 75, 77, 85, 86 -> {
                    // 雪天 - 浅蓝色渐变
                    views.setInt(R.id.forecast_widget_container, "setBackgroundResource", R.drawable.widget_snowy_gradient)
                }
                95, 96, 99 -> {
                    // 雷暴 - 深灰色渐变
                    views.setInt(R.id.forecast_widget_container, "setBackgroundResource", R.drawable.widget_thunder_gradient)
                }
                else -> {
                    // 默认 - 蓝色渐变
                    views.setInt(R.id.forecast_widget_container, "setBackgroundResource", R.drawable.widget_gradient_background)
                }
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "Forecast widget enabled")
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d(TAG, "Forecast widget disabled")
    }
}

data class ForecastDay(
    val date: String,
    val weatherCode: Int,
    val weatherDesc: String,
    val tempMax: String,
    val tempMin: String
)