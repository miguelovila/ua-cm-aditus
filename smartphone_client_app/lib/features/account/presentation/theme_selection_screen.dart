import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/theme/theme_cubit.dart';
import 'package:smartphone_client_app/core/theme/theme_preferences.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final preferences = state.preferences;
          final colorScheme = Theme.of(context).colorScheme;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Mode Section
              _SectionHeader(title: 'Appearance', icon: Icons.brightness_6),
              const SizedBox(height: 12),
              _ThemeModeCard(
                mode: AppThemeMode.system,
                currentMode: preferences.themeMode,
                icon: Icons.brightness_auto,
                title: 'System default',
                subtitle: 'Follow system settings',
                onTap: () {
                  context.read<ThemeCubit>().setThemeMode(AppThemeMode.system);
                },
              ),
              const SizedBox(height: 8),
              _ThemeModeCard(
                mode: AppThemeMode.light,
                currentMode: preferences.themeMode,
                icon: Icons.light_mode,
                title: 'Light',
                subtitle: 'Always use light theme',
                onTap: () {
                  context.read<ThemeCubit>().setThemeMode(AppThemeMode.light);
                },
              ),
              const SizedBox(height: 8),
              _ThemeModeCard(
                mode: AppThemeMode.dark,
                currentMode: preferences.themeMode,
                icon: Icons.dark_mode,
                title: 'Dark',
                subtitle: 'Always use dark theme',
                onTap: () {
                  context.read<ThemeCubit>().setThemeMode(AppThemeMode.dark);
                },
              ),

              const SizedBox(height: 32),

              // Color Scheme Section
              _SectionHeader(title: 'Color', icon: Icons.palette),
              const SizedBox(height: 12),

              // Dynamic color option
              _ColorSchemeCard(
                colorScheme: AppColorScheme.dynamic,
                currentColorScheme: preferences.colorScheme,
                icon: Icons.auto_awesome,
                title: 'Dynamic',
                subtitle: 'Material You colors from wallpaper',
                color: colorScheme.primary,
                onTap: () {
                  context.read<ThemeCubit>().setColorScheme(
                    AppColorScheme.dynamic,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Custom colors grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3,
                children: [
                  _ColorSchemeCard(
                    colorScheme: AppColorScheme.blue,
                    currentColorScheme: preferences.colorScheme,
                    title: 'Blue',
                    color: Colors.blue,
                    onTap: () {
                      context.read<ThemeCubit>().setColorScheme(
                        AppColorScheme.blue,
                      );
                    },
                  ),
                  _ColorSchemeCard(
                    colorScheme: AppColorScheme.red,
                    currentColorScheme: preferences.colorScheme,
                    title: 'Red',
                    color: Colors.red,
                    onTap: () {
                      context.read<ThemeCubit>().setColorScheme(
                        AppColorScheme.red,
                      );
                    },
                  ),
                  _ColorSchemeCard(
                    colorScheme: AppColorScheme.green,
                    currentColorScheme: preferences.colorScheme,
                    title: 'Green',
                    color: Colors.green,
                    onTap: () {
                      context.read<ThemeCubit>().setColorScheme(
                        AppColorScheme.green,
                      );
                    },
                  ),
                  _ColorSchemeCard(
                    colorScheme: AppColorScheme.purple,
                    currentColorScheme: preferences.colorScheme,
                    title: 'Purple',
                    color: Colors.purple,
                    onTap: () {
                      context.read<ThemeCubit>().setColorScheme(
                        AppColorScheme.purple,
                      );
                    },
                  ),
                  _ColorSchemeCard(
                    colorScheme: AppColorScheme.orange,
                    currentColorScheme: preferences.colorScheme,
                    title: 'Orange',
                    color: Colors.orange,
                    onTap: () {
                      context.read<ThemeCubit>().setColorScheme(
                        AppColorScheme.orange,
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  final AppThemeMode mode;
  final AppThemeMode currentMode;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ThemeModeCard({
    required this.mode,
    required this.currentMode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

class _ColorSchemeCard extends StatelessWidget {
  final AppColorScheme colorScheme;
  final AppColorScheme currentColorScheme;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ColorSchemeCard({
    required this.colorScheme,
    required this.currentColorScheme,
    this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = colorScheme == currentColorScheme;
    final themeColorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColorScheme.primaryContainer.withValues(alpha: 0.5)
              : themeColorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? themeColorScheme.primary
                : themeColorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, color: color, size: 24)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeColorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: themeColorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
