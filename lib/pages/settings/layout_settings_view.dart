import 'import.dart';

class LayoutComponent {
  final String id;
  bool isVisible;

  LayoutComponent({required this.id, required this.isVisible});
}

class LayoutSettingsView extends StatefulWidget {
  const LayoutSettingsView({super.key});

  @override
  State<LayoutSettingsView> createState() => _LayoutSettingsViewState();
}

class _LayoutSettingsViewState extends State<LayoutSettingsView> {
  final LayoutService _layoutService = LayoutService();
  List<LayoutComponent> _components = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final allComponentIds = _layoutService.getDefaultLayout();
    final visibleComponentIds = await _layoutService.getLayout();

    setState(() {
      _components = allComponentIds.map((id) {
        return LayoutComponent(
            id: id, isVisible: visibleComponentIds.contains(id));
      }).toList();

      _components.sort((a, b) {
        final aIndex = visibleComponentIds.indexOf(a.id);
        final bIndex = visibleComponentIds.indexOf(b.id);
        if (a.isVisible && b.isVisible) {
          return aIndex.compareTo(bIndex);
        }
        if (a.isVisible) return -1;
        if (b.isVisible) return 1;
        return 0;
      });

      _isLoading = false;
    });
  }

  Future<void> _saveLayout() async {
    final visibleLayout =
        _components.where((c) => c.isVisible).map((c) => c.id).toList();
    await _layoutService.saveLayout(visibleLayout);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Map<String, String> _getComponentNames(BuildContext context) {
    // TODO: Add more components
    return {
      'hourly_forecast': AppLocalizations.of(context).hourlyForecast,
      'rainfall_chart': AppLocalizations.of(context).precipitation,
      'daily_forecast': AppLocalizations.of(context).next7Days,
      'details': AppLocalizations.of(context).detailedData,
    };
  }

  @override
  Widget build(BuildContext context) {
    final componentNames = _getComponentNames(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).customizeHomepage),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLayout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              itemCount: _components.length,
              itemBuilder: (context, index) {
                final component = _components[index];
                return SwitchListTile(
                  key: Key(component.id),
                  title: Row(
                    children: [
                      Icon(Icons.list),
                      const SizedBox(width: 8),
                      Text(componentNames[component.id] ?? component.id),
                    ],
                  ),
                  value: component.isVisible,
                  onChanged: (bool value) {
                    setState(() {
                      component.isVisible = value;
                      final visibleItems =
                          _components.where((c) => c.isVisible).toList();
                      final invisibleItems =
                          _components.where((c) => !c.isVisible).toList();
                      _components = [...visibleItems, ...invisibleItems];
                    });
                  },
                );
              },
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final LayoutComponent item = _components.removeAt(oldIndex);
                  _components.insert(newIndex, item);
                });
              },
            ),
    );
  }
}
