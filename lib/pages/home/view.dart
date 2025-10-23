import 'package:zephyr/core/import.dart';

import 'import.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<City> cities = [];
  int pageIndex = 0;
  Map<String, WeatherData?> weatherMap = {};
  Map<String, List<WeatherWarning>> warningsMap = {};
  Map<String, bool> loadingMap = {};
  PageController? _pageController;
  final ValueNotifier<bool> _isFabVisibleNotifier = ValueNotifier(true);

  String _getMapKey(City city) {
    return '${city.lat}_${city.lon}_${weatherSourceNotifier.value}';
  }

  @override
  void initState() {
    super.initState();
    tempUnitNotifier.addListener(_onUnitChanged);
    weatherSourceNotifier.addListener(_onSourceChanged);
    _loadCities();
  }

  @override
  void dispose() {
    _isFabVisibleNotifier.dispose();
    tempUnitNotifier.removeListener(_onUnitChanged);
    weatherSourceNotifier.removeListener(_onSourceChanged);
    _pageController?.dispose();
    super.dispose();
  }

  void _onSourceChanged() {
    if (!mounted) return;
    for (var city in cities) {
      _loadWeather(city, force: false);
    }
  }

  void _onUnitChanged() {
    if (!mounted) return;
    for (var city in cities) {
      _loadWeather(city, force: true);
    }
  }

  Future<void> _loadCities() async {
    final prefs = await SharedPreferences.getInstance();
    final citiesStr = prefs.getString('cities');
    final mainIndex = prefs.getInt('main_city_index') ?? 0;
    List<City> list = [];
    int idx = 0;
    if (citiesStr != null) {
      list = City.listFromJson(citiesStr);
      idx = mainIndex < list.length ? mainIndex : 0;
      if (list.isNotEmpty && idx != 0) {
        final mainCity = list.removeAt(idx);
        list.insert(0, mainCity);
        idx = 0;
      }
    }
    if (!mounted) return;

    if (list.isNotEmpty && idx >= list.length) {
      idx = 0;
    }

    setState(() {
      cities = list;
      pageIndex = idx;
      if (_pageController == null || _pageController!.hasClients == false) {
        _pageController = PageController(initialPage: idx);
      }
    });

    for (var city in cities) {
      _loadWeather(city);
    }

    if (cities.isNotEmpty) {
      final mainCity = cities.first;
      final weather = weatherMap[_getMapKey(mainCity)];
      if (weather != null) {
        await WidgetService.updateWidget(city: mainCity, weatherData: weather);
      }
    }
  }

  Future<void> _loadWeather(City city, {bool force = false}) async {
    if (!mounted) return;
    setState(() {
      loadingMap[_getMapKey(city)] = true;
    });
    Map<String, dynamic>? cached;
    if (!force) {
      cached = await loadCachedWeather(city);
    }
    if (cached != null) {
      setState(() {
        weatherMap[_getMapKey(city)] = cached!['weather'];
        warningsMap[_getMapKey(city)] = cached['warnings'];
        loadingMap[_getMapKey(city)] = false;
      });
    } else {
      await _refreshWeather(city);
    }
  }

  Future<void> _refreshWeather(City city) async {
    Map<String, dynamic>? data;
    try {
      data = await WeatherFetchService.getFreshWeatherData(city);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to refresh weather: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      weatherMap[_getMapKey(city)] = data?['weather'];
      warningsMap[_getMapKey(city)] = data?['warnings'] ?? [];
      loadingMap[_getMapKey(city)] = false;
    });
  }

  void _onPageChanged(int idx) async {
    if (!mounted) return;
    if (idx >= 0 && idx < cities.length) {
      setState(() {
        pageIndex = idx;
      });
    }
  }

  Future<void> _onAddCity() async {
    final result = await Navigator.pushNamed(context, '/search');
    if (result is City) {
      final prefs = await SharedPreferences.getInstance();
      final citiesStr = prefs.getString('cities');
      List<City> list = citiesStr != null ? City.listFromJson(citiesStr) : [];
      if (!list.any((c) => c.lat == result.lat && c.lon == result.lon)) {
        list.add(result);
        await prefs.setString('cities', City.listToJson(list));
      }

      await _loadCities();

      final citiesStr2 = prefs.getString('cities');
      List<City> list2 =
          citiesStr2 != null ? City.listFromJson(citiesStr2) : [];
      int newIdx =
          list2.indexWhere((c) => c.lat == result.lat && c.lon == result.lon);

      if (newIdx >= 0 && newIdx < cities.length) {
        setState(() {
          pageIndex = newIdx;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController != null && _pageController!.hasClients) {
            _pageController!.animateToPage(
              newIdx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  Future<void> _onOpenSettings() async {
    await Navigator.pushNamed(context, '/settings');
    await _loadCities();
    setState(() {
      pageIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cities.isNotEmpty) {
        _pageController?.jumpToPage(0);
      }
    });
  }

  Future<void> _onLocate() async {
    NotificationUtils.showSnackBar(
      context,
      AppLocalizations.of(context).locating,
    );
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      NotificationUtils.showSnackBar(
        context,
        AppLocalizations.of(context).locationPermissionDenied,
      );
      return;
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      NotificationUtils.showSnackBar(
        context,
        AppLocalizations.of(context).locatingSuccess,
      );
    }
    final city = await LocationService.getCityFromPosition(pos);
    final prefs = await SharedPreferences.getInstance();
    if (city.name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      NotificationUtils.showSnackBar(
        context,
        AppLocalizations.of(context).locationNotRecognized,
      );
      return;
    }
    final citiesStr = prefs.getString('cities');
    List<City> list = citiesStr != null ? City.listFromJson(citiesStr) : [];
    if (!list.any((c) => c.lat == city.lat && c.lon == city.lon)) {
      list.add(city);
      await prefs.setString('cities', City.listToJson(list));
      await _loadCities();
      final citiesStr2 = prefs.getString('cities');
      List<City> list2 =
          citiesStr2 != null ? City.listFromJson(citiesStr2) : [];
      int newIdx =
          list2.indexWhere((c) => c.lat == city.lat && c.lon == city.lon);
      if (newIdx >= 0 && newIdx < cities.length) {
        setState(() {
          pageIndex = newIdx;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController != null && _pageController!.hasClients) {
            _pageController!.animateToPage(
              newIdx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } else {
      int existIdx =
          list.indexWhere((c) => c.lat == city.lat && c.lon == city.lon);
      if (existIdx >= 0 && existIdx < cities.length) {
        setState(() {
          pageIndex = existIdx;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController != null && _pageController!.hasClients) {
            _pageController!.animateToPage(
              existIdx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCity = cities.isNotEmpty && pageIndex < cities.length
        ? cities[pageIndex]
        : null;
    final currentWeather =
        currentCity != null ? weatherMap[_getMapKey(currentCity)] : null;
    final weatherCode = currentWeather?.current?.weatherCode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HomeAppBarWidget(
        currentCityName: currentCity?.name,
        citiesLength: cities.length,
        pageIndex: pageIndex,
        onAddCity: _onAddCity,
        onOpenSettings: _onOpenSettings,
        onLocate: _onLocate,
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _isFabVisibleNotifier,
        builder: (context, isVisible, child) {
          return AnimatedScale(
            scale: isVisible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton(
              onPressed: _onAddCity,
              child: const Icon(Icons.search),
            ),
          );
        },
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: cities.isEmpty
                ? const SizedBox.shrink()
                : WeatherBg(
                    key: ValueKey(weatherCode),
                    weatherCode: weatherCode,
                  ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification &&
                  notification.metrics.axis == Axis.vertical) {
                final direction = notification.direction;
                if (direction == ScrollDirection.reverse) {
                  if (_isFabVisibleNotifier.value) {
                    _isFabVisibleNotifier.value = false;
                  }
                } else if (direction == ScrollDirection.forward) {
                  if (!_isFabVisibleNotifier.value) {
                    _isFabVisibleNotifier.value = true;
                  }
                }
              }
              return false;
            },
            child: cities.isEmpty
                ? EmptyCityTip(onAdd: _onAddCity, onLocate: _onLocate)
                : PageView.builder(
                    controller: _pageController,
                    itemCount: cities.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, idx) {
                      final city = cities[idx];
                      final weather = weatherMap[_getMapKey(city)];
                      final warnings = warningsMap[_getMapKey(city)] ?? [];
                      final loading = loadingMap[_getMapKey(city)] ?? true;

                      return HomePageContentWidget(
                        city: city,
                        weather: weather,
                        loading: loading,
                        onRefresh: () => _refreshWeather(city),
                        warnings: warnings,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
