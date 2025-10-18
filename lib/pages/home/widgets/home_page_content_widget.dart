import '../import.dart';

class HomePageContentWidget extends StatefulWidget {
  final City city;
  final WeatherData? weather;
  final bool loading;
  final Future<void> Function() onRefresh;
  final List<WeatherWarning> warnings;

  const HomePageContentWidget({
    super.key,
    required this.city,
    required this.weather,
    required this.loading,
    required this.onRefresh,
    this.warnings = const [],
  });

  @override
  State<HomePageContentWidget> createState() => _HomePageContentWidgetState();
}

class _HomePageContentWidgetState extends State<HomePageContentWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (widget.weather == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).weatherDataError,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).checkNetworkAndRetry,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      );
    } else {
      return RefreshIndicator(
        displacement: kToolbarHeight + 75,
        onRefresh: widget.onRefresh,
        child: WeatherView(
          city: widget.city,
          weather: widget.weather!,
          warnings: widget.warnings,
        ),
      );
    }
  }
}
