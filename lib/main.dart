import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/core/router.dart';
import 'package:krate/ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (TMDB API Key)
  await dotenv.load(fileName: ".env");

  runApp(const ProviderScope(child: KrateApp()));
}

class KrateApp extends ConsumerWidget {
  const KrateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Krate',
      debugShowCheckedModeBanner: true,
      theme: AppTheme.of(ThemeVariant.dark),
      routerConfig: router,
    );
  }
}
