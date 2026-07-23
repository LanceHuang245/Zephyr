import 'package:intl/intl.dart';

import '../import.dart';

class FutureWeatherBand extends StatelessWidget {
  final List<DailyWeather> daily;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const FutureWeatherBand({
    required this.daily,
    required this.colorScheme,
    required this.textTheme,
    super.key,
  });

  String _getWeekday(DateTime date, int index, BuildContext context) {
    if (index == 0) {
      return AppLocalizations.of(context).today;
    }
    return DateFormat.E(AppLocalizations.of(context).localeName).format(date);
  }

  List<_ForecastDay> _buildDays(BuildContext context) {
    return List<_ForecastDay>.generate(daily.length, (index) {
      final forecast = daily[index];
      return _ForecastDay(
        dateLabel: _getWeekday(DateTime.parse(forecast.date), index, context),
        maxTemperature: forecast.tempMax ?? 0.0,
        minTemperature: forecast.tempMin ?? 0.0,
        weatherCode: forecast.weatherCode,
        isToday: index == 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const SizedBox.shrink();

    final days = _buildDays(context);
    var lowestTemperature = double.infinity;
    var highestTemperature = -double.infinity;
    for (final day in days) {
      lowestTemperature = day.minTemperature < lowestTemperature
          ? day.minTemperature
          : lowestTemperature;
      highestTemperature = day.maxTemperature > highestTemperature
          ? day.maxTemperature
          : highestTemperature;
    }

    // Compute bounds once; changing the temperature unit only updates chart labels.
    final chartPadding = ((highestTemperature - lowestTemperature).abs() * 0.15)
        .clamp(2.0, 4.0)
        .toDouble();
    final chartMinimum = lowestTemperature - chartPadding;
    final chartMaximum = highestTemperature + chartPadding;
    final header = SizedBox(
      height: 52,
      child: Row(
        children: days.map((day) {
          final labelColor =
              day.isToday ? colorScheme.primary : colorScheme.onSurfaceVariant;
          return Expanded(
            child: Column(
              children: [
                Text(
                  day.dateLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: labelColor,
                    fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Tooltip(
                  message: weatherDesc(day.weatherCode),
                  child: Icon(
                    weatherIcon(day.weatherCode),
                    color: colorScheme.onSurfaceVariant,
                    size: 23,
                  ),
                ),
                if (day.isToday)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 14,
                    height: 2,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );

    return ValueListenableBuilder<String>(
      valueListenable: tempUnitNotifier,
      child: header,
      builder: (context, unit, header) {
        return Column(
          children: [
            header!,
            const SizedBox(height: 6),
            Expanded(
              child: _TemperatureTrack(
                days: days,
                unit: unit,
                minimum: chartMinimum,
                maximum: chartMaximum,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TemperatureTrack extends StatelessWidget {
  final List<_ForecastDay> days;
  final String unit;
  final double minimum;
  final double maximum;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _TemperatureTrack({
    required this.days,
    required this.unit,
    required this.minimum,
    required this.maximum,
    required this.colorScheme,
    required this.textTheme,
  });

  String _formatTemperature(double temperature) {
    final rounded = temperature.roundToDouble();
    final value = temperature == rounded
        ? rounded.toStringAsFixed(0)
        : temperature.toStringAsFixed(1);
    return '$value°$unit';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const topInset = 22.0;
        const bottomInset = 28.0;
        final plotHeight = constraints.maxHeight - topInset - bottomInset;
        final temperatureRange = maximum - minimum;
        final highPoints = <Offset>[];
        final lowPoints = <Offset>[];

        // Keep every date column and its two points aligned on the same centre line.
        for (var index = 0; index < days.length; index++) {
          final day = days[index];
          final x = constraints.maxWidth * (index + 0.5) / days.length;
          final highY = topInset +
              (maximum - day.maxTemperature) / temperatureRange * plotHeight;
          final lowY = topInset +
              (maximum - day.minTemperature) / temperatureRange * plotHeight;
          highPoints.add(Offset(x, highY));
          lowPoints.add(Offset(x, lowY));
        }

        final highColor = colorScheme.error;
        final lowColor = colorScheme.primary;
        final labelWidth = (constraints.maxWidth / days.length)
            .clamp(44.0, 60.0)
            .clamp(0.0, constraints.maxWidth)
            .toDouble();
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _TemperatureTrackPainter(
                highPoints: highPoints,
                lowPoints: lowPoints,
                highColor: highColor,
                lowColor: lowColor,
                surfaceColor: colorScheme.surface,
              ),
            ),
            ...List<Widget>.generate(days.length, (index) {
              final highPoint = highPoints[index];
              final lowPoint = lowPoints[index];
              return Stack(
                children: [
                  _TemperatureLabel(
                    text: _formatTemperature(days[index].maxTemperature),
                    color: highColor,
                    centreX: highPoint.dx,
                    availableWidth: constraints.maxWidth,
                    width: labelWidth,
                    textStyle: textTheme.labelSmall,
                    top: (highPoint.dy - 22)
                        .clamp(0.0, constraints.maxHeight - 18)
                        .toDouble(),
                  ),
                  _TemperatureLabel(
                    text: _formatTemperature(days[index].minTemperature),
                    color: lowColor,
                    centreX: lowPoint.dx,
                    availableWidth: constraints.maxWidth,
                    width: labelWidth,
                    textStyle: textTheme.labelSmall,
                    top: (lowPoint.dy + 8)
                        .clamp(0.0, constraints.maxHeight - 18)
                        .toDouble(),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

class _TemperatureLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double centreX;
  final double availableWidth;
  final double width;
  final double top;
  final TextStyle? textStyle;

  const _TemperatureLabel({
    required this.text,
    required this.color,
    required this.centreX,
    required this.availableWidth,
    required this.width,
    required this.top,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: (centreX - width / 2).clamp(0.0, availableWidth - width).toDouble(),
      top: top,
      width: width,
      child: Text(
        text,
        style: textStyle?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class _TemperatureTrackPainter extends CustomPainter {
  final List<Offset> highPoints;
  final List<Offset> lowPoints;
  final Color highColor;
  final Color lowColor;
  final Color surfaceColor;

  const _TemperatureTrackPainter({
    required this.highPoints,
    required this.lowPoints,
    required this.highColor,
    required this.lowColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (highPoints.isEmpty) return;

    // Shade the daily high-low interval before drawing the two temperature paths.
    final bandPath = Path()..moveTo(highPoints.first.dx, highPoints.first.dy);
    for (final point in highPoints.skip(1)) {
      bandPath.lineTo(point.dx, point.dy);
    }
    for (final point in lowPoints.reversed) {
      bandPath.lineTo(point.dx, point.dy);
    }
    bandPath.close();
    canvas.drawPath(
      bandPath,
      Paint()
        ..color = lowColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    // The first-day guide ties the today label to its plotted values.
    canvas.drawLine(
      Offset(highPoints.first.dx, 0),
      Offset(highPoints.first.dx, size.height),
      Paint()
        ..color = lowColor.withValues(alpha: 0.14)
        ..strokeWidth = 1,
    );

    _drawTrack(canvas, highPoints, highColor, fillNodes: true);
    _drawTrack(canvas, lowPoints, lowColor, fillNodes: false);
  }

  void _drawTrack(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    required bool fillNodes,
  }) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final point in points) {
      canvas.drawCircle(
        point,
        4.5,
        Paint()
          ..color = fillNodes ? color : surfaceColor
          ..style = PaintingStyle.fill,
      );
      if (!fillNodes) {
        canvas.drawCircle(
          point,
          4.5,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TemperatureTrackPainter oldDelegate) {
    return highColor != oldDelegate.highColor ||
        lowColor != oldDelegate.lowColor ||
        surfaceColor != oldDelegate.surfaceColor ||
        !listEquals(highPoints, oldDelegate.highPoints) ||
        !listEquals(lowPoints, oldDelegate.lowPoints);
  }
}

class _ForecastDay {
  final String dateLabel;
  final double maxTemperature;
  final double minTemperature;
  final int? weatherCode;
  final bool isToday;

  const _ForecastDay({
    required this.dateLabel,
    required this.maxTemperature,
    required this.minTemperature,
    required this.weatherCode,
    required this.isToday,
  });
}
