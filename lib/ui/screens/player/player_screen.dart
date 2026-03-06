import 'package:awesome_video_player/awesome_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/data/models/watch_progress.dart';
import 'package:krate/providers/providers.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final int episodeId;

  const PlayerScreen({super.key, required this.episodeId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  BetterPlayerController? _controller;
  Episode? _episode;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _saveProgress();
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _setupPlayer() async {
    final epRepo = ref.read(episodeRepoProvider);
    final wpRepo = ref.read(watchProgressRepoProvider);

    final ep = await epRepo.getById(widget.episodeId);
    if (ep == null || ep.videoPath == null) {
      if (mounted) context.pop();
      return;
    }

    final progress = await wpRepo.getByEpisodeId(ep.id!);

    _episode = ep;

    final config = BetterPlayerConfiguration(
      autoPlay: true,
      fit: BoxFit.contain,
      allowedScreenSleep: false,
      fullScreenByDefault: true,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        enableSkips: true,
        enableFullscreen: true,
        enableMute: true,
        enableProgressText: true,
        enablePlaybackSpeed: true,
        enableSubtitles: true,
        enableQualities: false,
        playerTheme: BetterPlayerTheme.material,
        controlBarColor: Colors.black45,
      ),
    );

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.file,
      ep.videoPath!,
      subtitles: ep.subtitlePath != null
          ? [
              BetterPlayerSubtitlesSource(
                type: BetterPlayerSubtitlesSourceType.file,
                urls: [ep.subtitlePath!],
                name: 'External Subtitles',
                selectedByDefault: true,
              ),
            ]
          : null,
    );

    _controller = BetterPlayerController(
      config,
      betterPlayerDataSource: dataSource,
    );

    if (progress != null && !progress.isFinished) {
      _controller!.seekTo(Duration(milliseconds: progress.positionMs));
    }

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _saveProgress() async {
    if (_controller == null || _episode == null) return;

    final position = await _controller!.videoPlayerController?.position;
    final duration = _controller!.videoPlayerController?.value.duration;

    if (position == null || duration == null || duration == Duration.zero) {
      return;
    }

    final isFinished =
        position.inMilliseconds >
        (duration.inMilliseconds * kFinishedThreshold);

    final progress = WatchProgress(
      contentId: _episode!.contentId,
      episodeId: _episode!.id!,
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
      isFinished: isFinished,
      lastWatchedAt: DateTime.now(),
    );

    await ref.read(watchProgressRepoProvider).save(progress);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          BetterPlayer(controller: _controller!),
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
