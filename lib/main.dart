import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:krate/widgets/content_import_test.dart';

import './theme.dart';
import './screens/screens.dart';

import './widgets/tmdb_test_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // runApp(const KrateApp());
  runApp(MaterialApp(home: const ContentImportTest()));
}

class KrateApp extends StatelessWidget {
  const KrateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: KrateTheme.darkTheme,
      home: const MainView(),
    );
  }
}
