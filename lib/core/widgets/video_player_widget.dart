import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool isActive;
  final VoidCallback onPlay;

  const VideoPlayerWidget({
    super.key,
    this.videoUrl,
    this.thumbnailUrl,
    required this.isActive,
    required this.onPlay,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  bool _showControls = true;
  Timer? _hideTimer;
  double _aspectRatio = 16 / 9;

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _initController();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initController();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeController();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ── Controller ─────────────────────────────────────────────

  Future<void> _initController() async {
    if (_isInitializing || widget.videoUrl == null) return;
    setState(() => _isInitializing = true);

    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      // Detect video completion → reset to start, keep controls visible
      controller.addListener(_onVideoListener);

      setState(() {
        _controller = controller;
        _aspectRatio = controller.value.aspectRatio;
        _isInitializing = false;
        _showControls = true;
      });

      await _controller!.play();
      _startHideTimer();
    } catch (_) {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _disposeController() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onVideoListener);
    _controller?.dispose();
    _controller = null;
    _isInitializing = false;
    _showControls = true;
    if (mounted) setState(() {});
  }

  void _onVideoListener() {
    if (_controller == null) return;
    final value = _controller!.value;
    // When video reaches the end
    if (!value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _controller!.seekTo(Duration.zero);
      if (mounted) setState(() => _showControls = true);
    }
  }

  // ── Controls helpers ───────────────────────────────────────

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && (_controller?.value.isPlaying ?? false)) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _hideTimer?.cancel();
        _showControls = true; // keep controls visible when paused
      } else {
        _controller!.play();
        _startHideTimer();
      }
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _openFullscreen() async {
    if (_controller == null) return;
    _controller!.pause();
    _hideTimer?.cancel();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenPlayer(controller: _controller!),
      ),
    );

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted && _controller != null) {
      _controller!.play();
      _startHideTimer();
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Not active or controller not ready → thumbnail
    if (!widget.isActive || (_controller == null && !_isInitializing)) {
      return _Thumbnail(
        url: widget.thumbnailUrl,
        aspectRatio: _aspectRatio,
        onTap: widget.onPlay,
      );
    }

    // Initializing → loading placeholder
    if (_isInitializing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return _LoadingPlaceholder(aspectRatio: _aspectRatio);
    }

    return _buildPlayer();
  }

  Widget _buildPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ① Video
            VideoPlayer(_controller!),

            // ② Centre play indicator (shown when paused)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (context, value, _) {
                if (value.isPlaying) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                );
              },
            ),

            // ③ Bottom controls overlay (auto-hides)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: _buildControlsOverlay(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.78),
          ],
          stops: const [0.45, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller!,
            builder: (context, value, _) {
              final position = value.position;
              final duration = value.duration;
              final progress = duration.inMilliseconds > 0
                  ? (position.inMilliseconds / duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Play / Pause
                    IconButton(
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _togglePlayPause,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                    ),

                    // Played time
                    Text(
                      _fmt(position),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                    const SizedBox(width: 4),

                    // Seek bar
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white38,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: (v) {
                            // Reset auto-hide timer while seeking
                            _startHideTimer();
                            _controller!.seekTo(Duration(
                              milliseconds:
                                  (v * duration.inMilliseconds).round(),
                            ));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Total duration
                    Text(
                      _fmt(duration),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),

                    // Fullscreen
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded,
                          color: Colors.white, size: 22),
                      onPressed: _openFullscreen,
                      padding: const EdgeInsets.only(left: 4),
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Fullscreen player
// ────────────────────────────────────────────────────────────

class _FullscreenPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  const _FullscreenPlayer({required this.controller});

  @override
  State<_FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<_FullscreenPlayer> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Defer play() until after the first frame to avoid
    // setState() called during build via ValueNotifier.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.play();
        _startHideTimer();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && widget.controller.value.isPlaying) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
        _hideTimer?.cancel();
        _showControls = true;
      } else {
        widget.controller.play();
        _startHideTimer();
      }
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            // Centre play indicator when paused
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                if (value.isPlaying) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 38),
                  ),
                );
              },
            ),

            // Bottom controls
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: _buildControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.45, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              final position = value.position;
              final duration = value.duration;
              final progress = duration.inMilliseconds > 0
                  ? (position.inMilliseconds / duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Row(
                  children: [
                    // Play / Pause
                    IconButton(
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: _togglePlayPause,
                    ),

                    // Played time
                    Text(_fmt(position),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 6),

                    // Seek bar
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white38,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: (v) {
                            _startHideTimer();
                            widget.controller.seekTo(Duration(
                              milliseconds:
                                  (v * duration.inMilliseconds).round(),
                            ));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Total duration
                    Text(_fmt(duration),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),

                    // Exit fullscreen
                    IconButton(
                      icon: const Icon(Icons.fullscreen_exit_rounded,
                          color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Thumbnail
// ────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final String? url;
  final double aspectRatio;
  final VoidCallback onTap;

  const _Thumbnail(
      {required this.url, required this.aspectRatio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const ColoredBox(color: Color(0xFF1C1C1C));
                },
                errorBuilder: (context, e, s) =>
                    const ColoredBox(color: Color(0xFF1C1C1C)),
              )
            else
              const ColoredBox(color: Color(0xFF1C1C1C)),
            // Play button
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Loading placeholder
// ────────────────────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  final double aspectRatio;
  const _LoadingPlaceholder({required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: const ColoredBox(
        color: Color(0xFF1C1C1C),
        child: Center(
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        ),
      ),
    );
  }
}
