import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:krate/models/app/episode.dart';
import 'package:krate/repositories/watch_progress_repository.dart';

class PlayerScreen extends StatefulWidget {
  final Episode episode;
  final int contentId;

  const PlayerScreen({
    super.key,
    required this.episode,
    required this.contentId,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  bool _showControls = true;
  Timer? _controlsTimer;

  // State subscriptions
  final List<StreamSubscription> _subscriptions = [];

  // Local state for reactive UI
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _buffering = false;

  // Repository reference for safe dispose
  late final WatchProgressRepository _wpRepo;

  // Progress tracking
  Timer? _progressTimer;
  int _lastSavedPositionMs = 0;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _wpRepo = context.read<WatchProgressRepository>();

    // Set orientations to landscape only for player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _setupListeners();
    _initPlayer();
  }

  void _setupListeners() {
    _subscriptions.addAll([
      _player.stream.position.listen((p) => setState(() => _position = p)),
      _player.stream.duration.listen((d) => setState(() => _duration = d)),
      _player.stream.playing.listen((p) => setState(() => _playing = p)),
      _player.stream.buffering.listen((b) => setState(() => _buffering = b)),
      _player.stream.completed.listen((completed) {
        if (completed) _onPlaybackFinished();
      }),
    ]);
  }

  Future<void> _initPlayer() async {
    if (widget.episode.videoPath == null) return;

    // 1. Load the media
    await _player.open(Media(widget.episode.videoPath!));

    // 2. Resume progress if available
    final progress = await _wpRepo.getProgress(widget.episode.id!);
    if (progress != null && progress.positionMs > 0) {
      await _player.seek(Duration(milliseconds: progress.positionMs));
    }

    // 3. Start progress tracking timer
    _progressTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _saveProgress(),
    );
  }

  Future<void> _saveProgress() async {
    final position = _player.state.position.inMilliseconds;
    if (position == _lastSavedPositionMs || position <= 0) return;

    await _wpRepo.saveProgress(
      contentId: widget.contentId,
      episodeId: widget.episode.id!,
      positionMs: position,
      isFinished: false,
    );
    _lastSavedPositionMs = position;
  }

  Future<void> _onPlaybackFinished() async {
    await _wpRepo.saveProgress(
      contentId: widget.contentId,
      episodeId: widget.episode.id!,
      positionMs: _player.state.position.inMilliseconds,
      isFinished: true,
    );
    if (mounted) Navigator.pop(context);
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _skip(int seconds) {
    final currentPos = _player.state.position;
    final duration = _player.state.duration;
    var newPos = currentPos + Duration(seconds: seconds);

    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > duration) newPos = duration;

    _player.seek(newPos);
    _startControlsTimer();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _progressTimer?.cancel();
    _controlsTimer?.cancel();

    // Save final progress safely
    _saveProgress();

    // Reset orientations
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Black screen if videoPath is null (shouldn't happen)
          if (widget.episode.videoPath == null)
            const Center(
              child: Text(
                "Error: Video file not found",
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Video Output
          GestureDetector(
            onTap: _toggleControls,
            onDoubleTapDown: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < screenWidth / 2) {
                _skip(-10);
              } else {
                _skip(10);
              }
            },
            child: Video(controller: _controller),
          ),

          // Buffering Indicator
          if (_buffering)
            const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),

          // Custom Controls Overlay
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      color: Colors.black45,
      child: Stack(
        children: [
          // Back Button & Title Row
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.episode.title ?? "Now Playing",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Center Controls (Skip - Play/Pause - Skip)
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 48,
                  ),
                  onPressed: () => _skip(-10),
                ),
                const SizedBox(width: 48),
                IconButton(
                  icon: Icon(
                    _playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 88,
                  ),
                  onPressed: () {
                    _player.playOrPause();
                    _startControlsTimer();
                  },
                ),
                const SizedBox(width: 48),
                IconButton(
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 48,
                  ),
                  onPressed: () => _skip(10),
                ),
              ],
            ),
          ),

          // Bottom Bar (Seeker + Time)
          Positioned(
            bottom: 24,
            left: 32,
            right: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble().clamp(
                      0,
                      _duration.inMilliseconds.toDouble(),
                    ),
                    max: _duration.inMilliseconds.toDouble(),
                    onChanged: (val) {
                      _player.seek(Duration(milliseconds: val.toInt()));
                      _startControlsTimer();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? "$hh:$mm:$ss" : "$mm:$ss";
  }
}
