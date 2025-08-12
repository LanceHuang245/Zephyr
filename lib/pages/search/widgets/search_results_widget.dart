import 'package:zephyr/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../core/models/city.dart';

class SearchResultsWidget extends StatelessWidget {
  final List<City> results;
  final bool loading;
  final bool isEmpty;
  final ValueChanged<City> onCityTap;

  const SearchResultsWidget({
    super.key,
    required this.results,
    required this.loading,
    required this.isEmpty,
    required this.onCityTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isEmpty && !loading) {
      return Center(
        child: Text(
          AppLocalizations.of(context).searchHintOnSurface,
          style: textTheme.bodyLarge
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      child: ListView.separated(
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final city = results[index];
          return Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onCityTap(city),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.location_city,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${city.admin ?? ''}, ${city.country}",
                            style: textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
