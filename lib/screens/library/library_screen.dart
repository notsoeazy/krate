import 'package:flutter/material.dart';

import './animes_tab.dart';
import './movies_tab.dart';
import './series_tab.dart';
import '../../widgets/widgets.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const List<Tab> tabs = <Tab>[
    Tab(text: "Movies"),
    Tab(text: "Series"),
    Tab(text: "Animes"),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: Text("Library", style: Theme.of(context).textTheme.titleLarge),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          ],
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: tabs,
          ),
        ),
        body: const TabBarView(
          children: [
            MediaGrid(), // Movies
            MediaGrid(), // Series
            MediaGrid(), // Animes
          ],
        ),
      ),
    );
  }
}