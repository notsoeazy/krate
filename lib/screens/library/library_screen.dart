import 'package:flutter/material.dart';
import 'package:krate/screens/library/animes_tab.dart';
import 'package:krate/screens/library/movies_tab.dart';
import 'package:krate/screens/library/series_tab.dart';
import 'package:provider/provider.dart';
import 'package:krate/services/scanner_service.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Library"),
          actions: [
            Consumer<ScannerService>(
              builder: (context, scanner, _) {
                if (scanner.isScanning) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: scanner.progress > 0 ? scanner.progress : null,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.sync_rounded),
                  tooltip: "Scan Library",
                  onPressed: () => scanner.scanLibrary(),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Movies"),
              Tab(text: "Series"),
              Tab(text: "Anime"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [MoviesTab(), SeriesTab(), AnimesTab()],
        ),
      ),
    );
  }
}
