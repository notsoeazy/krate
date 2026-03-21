import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';

class MediaDetailsSeasonSelectionModal extends StatefulWidget {
  final Content content;

  const MediaDetailsSeasonSelectionModal({super.key, required this.content});

  static void show(BuildContext context, Content content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => MediaDetailsSeasonSelectionModal(content: content),
    );
  }

  @override
  State<MediaDetailsSeasonSelectionModal> createState() =>
      _MediaDetailsSeasonSelectionModalState();
}

class _MediaDetailsSeasonSelectionModalState
    extends State<MediaDetailsSeasonSelectionModal> {
  final Set<int> _selectedSeasons = {};

  @override
  Widget build(BuildContext context) {
    final totalSeasons = widget.content.totalSeasons;

    return Consumer(
      builder: (context, ref, child) {
        final service = ref.read(watchProgressServiceProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mark Seasons'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_selectedSeasons.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedSeasons.clear());
                  },
                  child: const Text('Clear selection'),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: totalSeasons,
                  itemBuilder: (context, index) {
                    final seasonNum = index + 1;
                    final isSelected = _selectedSeasons.contains(seasonNum);
                    return CheckboxListTile(
                      title: Text('Season $seasonNum'),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedSeasons.add(seasonNum);
                          } else {
                            _selectedSeasons.remove(seasonNum);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectedSeasons.isEmpty
                              ? null
                              : () async {
                                  await service.clearSeasonsProgress(
                                    widget.content.id!,
                                    _selectedSeasons.toList(),
                                  );
                                  if (mounted) Navigator.pop(context);
                                },
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('Clear Progress'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _selectedSeasons.isEmpty
                              ? null
                              : () async {
                                  await service.markSeasonsFinished(
                                    widget.content.id!,
                                    _selectedSeasons.toList(),
                                  );
                                  if (mounted) Navigator.pop(context);
                                },
                          icon: const Icon(Icons.done_all_rounded),
                          label: const Text('Mark Watched'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
