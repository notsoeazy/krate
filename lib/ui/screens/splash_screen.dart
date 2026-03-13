import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/ui/screens/shell_screen.dart';
import 'package:krate/ui/screens/storage_setup_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _performStartup();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performStartup() async {
    final startTime = DateTime.now();

    // Wait for vault status to be determined
    final vaultStatus = await ref.read(vaultStatusProvider.future);

    if (vaultStatus != VaultStatus.ok) {
      _navigateTo(const StorageSetupScreen());
      return;
    }

    // Perform quick scan/scout
    final importService = ref.read(importServiceProvider);
    await importService.cleanupFailedImports();

    final syncService = ref.read(vaultSyncServiceProvider);
    final needsSync = await syncService.scout();

    if (needsSync && mounted) {
      final container = ProviderScope.containerOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vault directory changes detected.'),
          action: SnackBarAction(
            label: 'Sync Now',
            onPressed: () {
              container.read(vaultSyncProvider.notifier).sync();
            },
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(milliseconds: 2000) - elapsed;
    if (remaining.inMilliseconds > 0) {
      await Future.delayed(remaining);
    }

    _navigateTo(const ShellScreen());
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/krate-icon_transparent.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 16),
              Text(
                'KRATE',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
