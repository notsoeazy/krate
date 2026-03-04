import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(
              Icons.perm_media_rounded,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8),
            Text(
              "Krate",
              style: Theme.of(context).textTheme.titleLarge,
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: const [
          SectionTitle(title: "Continue Watching"),
          HorizontalMediaRow(),
          SizedBox(height: 24),
          SectionTitle(title: "Recently Added"),
          HorizontalMediaRow(),
          SizedBox(height: 24),
          SectionTitle(title: "Movies"),
          HorizontalMediaRow(),
          SizedBox(height: 24),
          SectionTitle(title: "Series"),
          HorizontalMediaRow(),
          SizedBox(height: 24),
          SectionTitle(title: "Anime"),
          HorizontalMediaRow(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
