import '../import.dart';

class LLMSelectorWidget extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onTap;

  const LLMSelectorWidget({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final disabledColor = colorScheme.onSurface.withValues(alpha: 0.38);
    final activeColor = colorScheme.onSurface;
    final primaryColor = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  onTap: enabled ? onTap : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: enabled ? primaryColor : disabledColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LLM Configuration',
                            style: textTheme.titleMedium?.copyWith(
                              color: enabled ? activeColor : disabledColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              indent: 12,
              endIndent: 12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Switch(
                value: enabled,
                onChanged: onEnabledChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
