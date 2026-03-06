import 'package:flutter/material.dart';
import 'package:krate/screens/library/media_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/repositories/content_repository.dart';
import 'package:krate/constants.dart';
import 'package:krate/widgets/widgets.dart';

class MoviesTab extends StatelessWidget {
  const MoviesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentRepository>(
      builder: (context, contentRepo, _) {
        return FutureBuilder<List<Content>>(
          future: contentRepo.getAllContent(type: ContentType.movie),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final movies = snapshot.data ?? [];
            return MediaGrid(
              items: movies,
              onItemSelected: (content) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MediaDetailsScreen(content: content),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
