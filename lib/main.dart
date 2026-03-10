import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/ui/screens/shell_screen.dart';
import 'package:krate/ui/screens/storage_setup_screen.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: KrateApp()));
}

class KrateApp extends ConsumerWidget {
  const KrateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultStatus = ref.watch(vaultStatusProvider);

    return MaterialApp(
      title: 'Krate',
      debugShowCheckedModeBanner: true,
      theme: AppTheme.of(ThemeVariant.dark),
      home: vaultStatus.when(
        data: (status) {
          if (status == VaultStatus.ok) {
            return const ShellScreen();
          } else {
            return const StorageSetupScreen();
          }
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
