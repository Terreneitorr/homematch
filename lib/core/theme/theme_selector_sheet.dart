import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_viewmodel.dart';

/// Muestra el recuadro para elegir entre tema Claro, Oscuro o Automático.
/// Úsalo así desde cualquier pantalla:
///   showThemeSelectorSheet(context);
void showThemeSelectorSheet(BuildContext context) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: theme.colorScheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ThemeSelectorSheet(),
  );
}

class _ThemeSelectorSheet extends StatelessWidget {
  const _ThemeSelectorSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeVM = context.watch<ThemeViewModel>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Apariencia',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Elige cómo quieres ver la app',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              icon: Icons.light_mode_outlined,
              label: 'Claro',
              selected: themeVM.themeMode == ThemeMode.light,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.dark_mode_outlined,
              label: 'Oscuro',
              selected: themeVM.themeMode == ThemeMode.dark,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.brightness_auto_outlined,
              label: 'Automático',
              subtitle: 'Sigue la configuración de tu teléfono',
              selected: themeVM.themeMode == ThemeMode.system,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}