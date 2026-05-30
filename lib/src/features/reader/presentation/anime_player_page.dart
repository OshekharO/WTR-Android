import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Foundation flags not used in this file.
import 'dart:async';
import 'package:video_player/video_player.dart';

import '../../../extensions/models/chapter_item.dart';
import '../../../extensions/models/content_item.dart';
import '../../../extensions/registry/source_registry.dart';

/// Full-screen anime episode player built on [Chewie] + [VideoPlayer].
class AnimePlayerPage extends StatefulWidget {
  const AnimePlayerPage({
    super.key,
    required this.item,
    required this.episodeId,
    required this.episodeNo,
    required this.episodeTitle,
    required this.previousChapter,
    required this.nextChapter,
    required this.onPrevious,
    required this.onNext,
  });

  final ContentItem item;
  final int episodeId;
  final int episodeNo;
  final String episodeTitle;
  final ChapterItem? previousChapter;
  final ChapterItem? nextChapter;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  State<AnimePlayerPage> createState() => _AnimePlayerPageState();
}

class _AnimePlayerPageState extends State<AnimePlayerPage> {
  late final Future<String?> _urlFuture;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlFuture = SourceRegistry.instance.active.getEpisodeUrl(
      item: widget.item,
      episodeId: widget.episodeId,
      episodeNo: widget.episodeNo,
    );
    // Landscape for video.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    // Restore portrait.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _initPlayer(String url) async {
    try {
      final uri = Uri.parse(url);
      final controller = uri.path.endsWith('.m3u8')
          ? VideoPlayerController.networkUrl(
              uri,
              httpHeaders: const {'Accept': '*/*'},
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            )
          : VideoPlayerController.networkUrl(uri);

      await controller.initialize();

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        // Use our cross-platform custom controls to match screenshot UI.
        customControls: CustomPlayerControls(videoController: controller),
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

      if (!mounted) {
        controller.dispose();
        chewie.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _chewieController = chewie;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: widget.previousChapter == null
                ? 'No previous episode'
                : 'Previous episode',
            onPressed: widget.onPrevious,
            icon: const Icon(Icons.skip_previous_rounded),
          ),
          IconButton(
            tooltip: widget.nextChapter == null
                ? 'No next episode'
                : 'Next episode',
            onPressed: widget.onNext,
            icon: const Icon(Icons.skip_next_rounded),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Episode ${widget.episodeNo}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (widget.episodeTitle.isNotEmpty)
              Text(
                widget.episodeTitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: FutureBuilder<String?>(
        future: _urlFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final url = snap.data;

          if (url == null || url.trim().isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No video URL available for this episode.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Initialise player once we have the URL.
          if (_videoController == null && _error == null) {
            _initPlayer(url);
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white54, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => _error = null);
                        _initPlayer(url);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
          );
        },
      ),
    );
  }
}

// Cross-platform custom player controls that mimic the screenshot UI.
class CustomPlayerControls extends StatefulWidget {
  const CustomPlayerControls({super.key, required this.videoController, this.chewieController});

  final VideoPlayerController videoController;
  final ChewieController? chewieController;

  @override
  State<CustomPlayerControls> createState() => _CustomPlayerControlsState();
}

class _CustomPlayerControlsState extends State<CustomPlayerControls> {
  late VideoPlayerController controller;
  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    controller = widget.videoController;
    controller.addListener(_onControllerUpdate);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() => _visible = false);
    });
  }

  void _toggleVisibility() {
    setState(() => _visible = !_visible);
    if (_visible) _startHideTimer();
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final duration = controller.value.duration;
    final position = controller.value.position;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleVisibility,
      child: Stack(
        children: [
          // Center large play/pause when visible.
          AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(48),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 36,
                      color: Colors.white,
                      onPressed: () {
                        final back = position - const Duration(seconds: 15);
                        controller.seekTo(back > Duration.zero ? back : Duration.zero);
                        _startHideTimer();
                      },
                      icon: const Icon(Icons.replay_10),
                    ),
                    IconButton(
                      iconSize: 48,
                      color: Colors.white,
                      onPressed: () {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                        _startHideTimer();
                      },
                      icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    IconButton(
                      iconSize: 36,
                      color: Colors.white,
                      onPressed: () {
                        final fwd = position + const Duration(seconds: 15);
                        controller.seekTo(fwd < duration ? fwd : duration);
                        _startHideTimer();
                      },
                      icon: const Icon(Icons.forward_10),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom control bar
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (controller.value.isPlaying) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                            _startHideTimer();
                          },
                        ),
                        Text(_format(position), style: const TextStyle(color: Colors.white70)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider.adaptive(
                              value: duration.inMilliseconds == 0
                                  ? 0
                                  : position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                              min: 0,
                              max: duration.inMilliseconds.toDouble(),
                              onChanged: (v) {
                                final to = Duration(milliseconds: v.toInt());
                                controller.seekTo(to);
                              },
                            ),
                          ),
                        ),
                        Text('-${_format(duration - position)}', style: const TextStyle(color: Colors.white70)),
                        IconButton(
                          onPressed: () async {
                            await controller.setVolume(controller.value.volume > 0 ? 0 : 1);
                            _startHideTimer();
                          },
                          icon: Icon(controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () async {
                            final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
                            // Use ChewieController's fullscreen handling when available (non-async).
                            if (widget.chewieController != null) {
                              try {
                                widget.chewieController!.enterFullScreen();
                              } catch (_) {
                                // fallback to system orientation toggle if Chewie method unavailable
                                if (isPortrait) {
                                  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                                } else {
                                  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                                }
                              }
                            } else {
                              if (isPortrait) {
                                await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                              } else {
                                await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                              }
                            }
                            _startHideTimer();
                          },
                          icon: const Icon(Icons.fullscreen, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
