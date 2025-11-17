import '../import.dart';

enum WidgetType { current, forecast }

class RequestHomewidgetWidget extends StatelessWidget {
  const RequestHomewidgetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<bool?>(
      future: HomeWidget.isRequestPinWidgetSupported(),
      builder: (context, snapshot) {
        final supported = snapshot.data ?? false;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: supported ? () => _showWidgetSelectionDialog(context) : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.widgets,
                        color: Platform.isIOS
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.38)
                            : Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).addHomeWidget,
                        style: textTheme.titleMedium?.copyWith(
                            color: Platform.isIOS
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.38)
                                : null)),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down,
                        color: Platform.isIOS
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.38)
                            : Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWidgetSelectionDialog(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).selectWidgetType,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 当前天气小部件
              _buildWidgetOption(
                context,
                title: AppLocalizations.of(context).currentWeatherWidget,
                subtitle: AppLocalizations.of(context).currentWeatherWidgetDesc,
                icon: Icons.wb_sunny,
                onTap: () => _requestWidget(context, WidgetType.current),
              ),

              const SizedBox(height: 12),

              // 7日预报小部件
              _buildWidgetOption(
                context,
                title: AppLocalizations.of(context).forecastWeatherWidget,
                subtitle: AppLocalizations.of(context).forecastWeatherWidgetDesc,
                icon: Icons.calendar_view_week,
                onTap: () => _requestWidget(context, WidgetType.forecast),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWidgetOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _requestWidget(BuildContext context, WidgetType widgetType) {
    switch (widgetType) {
      case WidgetType.current:
        HomeWidget.requestPinWidget(
          name: 'WeatherWidgetProvider',
          androidName: 'WeatherWidgetProvider',
          qualifiedAndroidName: 'org.claret.zephyr.WeatherWidgetProvider',
        );
        break;
      case WidgetType.forecast:
        HomeWidget.requestPinWidget(
          name: 'ForecastWidgetProvider',
          androidName: 'ForecastWidgetProvider',
          qualifiedAndroidName: 'org.claret.zephyr.ForecastWidgetProvider',
        );
        break;
    }
  }
}
