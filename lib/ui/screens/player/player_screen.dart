import 'dart:async';
import 'package:awesome_video_player/awesome_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/data/models/watch_history.dart';
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
  bool _hasSeeked = false;
  Timer? _progressTimer;
  DateTime _sessionStartTime = DateTime.now();
  late ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _setupPlayer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the container so it can be safely used even during/after dispose()
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    final position = _controller?.videoPlayerController?.value.position;
    final duration = _controller?.videoPlayerController?.value.duration;
    _saveProgress(currentPosition: position, totalDuration: duration, isClosing: true);
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
      if (mounted) Navigator.of(context).pop();
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

    // Initial check in case it's already ready (local files)
    if (_controller!.videoPlayerController?.value.initialized ?? false) {
      _applySeek(progress);
    }

    _controller!.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.initialized ||
          event.betterPlayerEventType == BetterPlayerEventType.play) {
        _applySeek(progress);
      }
    });

    if (mounted) {
      setState(() => _isInitialized = true);
      _startProgressTimer();
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress({Duration? currentPosition, Duration? totalDuration, bool isClosing = false}) async {
    if (_controller == null || _episode == null) return;

    // Use our cached container reference, rather than looking up context 
    // which fails during widget destruction.
    final container = _container;

    final position = currentPosition ?? await _controller!.videoPlayerController?.position;
    final duration = totalDuration ?? _controller!.videoPlayerController?.value.duration;

    if (position == null || duration == null || duration == Duration.zero) {
      return;
    }

    await container
        .read(watchProgressServiceProvider)
        .saveProgress(
          contentId: _episode!.contentId,
          episodeId: _episode!.id!,
          positionMs: position.inMilliseconds,
          durationMs: duration.inMilliseconds,
        );

    if (isClosing) {
      final now = DateTime.now();
      final sessionDuration = now.difference(_sessionStartTime);
      if (sessionDuration.inSeconds > 5) {
        final history = WatchHistory(
          contentId: _episode!.contentId,
          episodeId: _episode!.id!,
          startedAt: _sessionStartTime,
          finishedAt: now,
          durationWatchedMs: sessionDuration.inMilliseconds,
        );
        await container.read(watchHistoryRepoProvider).record(history);
        container.invalidate(watchHistoryListProvider);
      }
    }
  }

  void _applySeek(WatchProgress? progress) {
    if (_hasSeeked || progress == null || progress.isFinished) return;
    if (_controller?.videoPlayerController?.value.initialized ?? false) {
      _hasSeeked = true;
      _controller!.seekTo(Duration(milliseconds: progress.positionMs));
    }
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
