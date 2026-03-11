import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/utils/constants.dart';

class MediaBackdrop extends StatelessWidget {
  final Content content;

  const MediaBackdrop({super.key, required this.content});

  Widget _posterFallback() {
    if (content.localPosterPath != null) {
      final f = File(content.localPosterPath!);
      if (f.existsSync()) {
        return Image.file(
          f,
          key: ValueKey(content.updatedAt),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        return ColoredBox(
          color: Colors.grey[900]!,
          child: Center(
            child: Icon(
              content.contentType == ContentType.series
                  ? Icons.tv
                  : Icons.movie,
              color: Colors.white12,
              size: 80,
            ),
          ),
        );
      }
    }
    if (content.tmdbPosterPath != null) {
      return CachedNetworkImage(
        imageUrl: '$kTmdbImageBase/$kTmdbPosterSize${content.tmdbPosterPath}',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (content.localBackdropPath != null) {
      final f = File(content.localBackdropPath!);
      if (f.existsSync()) {
        image = Image.file(
          f,
          key: ValueKey(content.updatedAt),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        image = _posterFallback();
      }
    } else if (content.tmdbBackdropPath != null) {
      image = CachedNetworkImage(
        imageUrl: '$kTmdbImageBase/$kTmdbBackdropSize${content.tmdbBackdropPath}',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (ctx, url) => const SizedBox.shrink(),
        errorWidget: (ctx, url, err) => _posterFallback(),
      );
    } else {
      image = _posterFallback();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black45,
                Colors.transparent,
                Colors.transparent,
                Colors.black87,
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
