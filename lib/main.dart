import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/ui/screens/shell_screen.dart';
import 'package:krate/ui/screens/storage_setup_screen.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/ui/screens/splash_screen.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/theme.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/ui/widgets/global_toast_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: KrateApp()));
}

class KrateApp extends ConsumerWidget {
  const KrateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultStatus = ref.watch(startupProvider);

    final textTheme = createTextTheme(context, kBodyFont, kDisplayFont);
    final materialTheme = MaterialTheme(textTheme);

    final themeMode = ref.watch(themeModeProvider);
    final schemeIndex = ref.watch(themeSchemeProvider);

    final scheme = MaterialTheme.schemes[schemeIndex.clamp(0, MaterialTheme.schemes.length - 1)];

    return MaterialApp(
      title: 'Krate',
      debugShowCheckedModeBanner: false,
      theme: materialTheme.theme(scheme.light()),
      darkTheme: materialTheme.theme(scheme.dark()),
      themeMode: themeMode,
      builder: (context, child) => GlobalToastOverlay(child: child!),
      home: vaultStatus.when(
        data: (status) {
          if (status == VaultStatus.ok) return const ShellScreen();
          return const StorageSetupScreen();
        },
        loading: () => const SplashScreen(),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
