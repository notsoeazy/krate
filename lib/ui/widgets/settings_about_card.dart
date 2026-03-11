import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutSettingsCard extends StatelessWidget {
  const AboutSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // App Branding
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/krate-icon_transparent.png',
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Krate',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Version 0.2.0-beta',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Credits Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 26,
                  child: SvgPicture.asset('assets/tmdb.svg'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                    style: textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Licenses
            // TODO: Implement licenses
          ],
        ),
      ),
    );
  }
}
