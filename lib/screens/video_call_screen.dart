import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/signaling.dart';
import '../services/matchmaking_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/ad_manager.dart';
import '../utils/app_colors.dart';
import '../main.dart' show supabaseInitialized;

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with SingleTickerProviderStateMixin {
  final Signaling signaling = Signaling();
  final MatchmakingService matchmaking = MatchmakingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _radarController;

  // Route args
  String _otherUid = '';
  String _contactName = 'Stranger';
  String? _contactAvatarUrl;
  bool _isCaller = false;
  String _roomId = '';

  bool _connecting = true;
  bool _audioMuted = false;
  bool _videoMuted = false;
  bool _initialized = false;
  String? _errorMsg;

  // Duration timer
  final Stopwatch _callDuration = Stopwatch();
  Timer? _durationTimer;
  String _durationText = '00:00';

  // Subscriptions
  StreamSubscription? _roomStatusSub;
  Timer? _callingTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _otherUid = args['otherUid'] as String? ?? '';
        _contactName = args['name'] as String? ?? 'Stranger';
        _contactAvatarUrl = args['avatarUrl'] as String?;
        _roomId = args['roomId'] as String? ?? '';
        _isCaller = args['isCaller'] as bool? ?? _roomId.isEmpty;
      } else {
        _isCaller = true;
      }
      _initialized = true;
      _initVideoCall();
    }
  }

  Future<void> _initVideoCall() async {
    if (!supabaseInitialized) {
      setState(() {
        _connecting = false;
        _errorMsg = 'Backend is not configured.\nPlease check your connection.';
      });
      return;
    }

    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      signaling.onAddRemoteStream = (stream) async {
        _remoteRenderer.srcObject = stream;
        try {
          await _audioPlayer.setVolume(0.0);
          await _audioPlayer.stop();
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 200));

        for (final track in signaling.localStream?.getAudioTracks() ?? []) {
          track.enabled = true;
        }

        if (!kIsWeb) {
          try {
            await Helper.setSpeakerphoneOn(true);
          } catch (e) {
            debugPrint('Audio output setup error: $e');
          }
        }

        for (final track in stream.getAudioTracks()) {
          track.enabled = true;
          try {
            Helper.setVolume(1.0, track);
          } catch (_) {}
        }

        if (mounted) {
          _callingTimeoutTimer?.cancel();
          setState(() => _connecting = false);
          _radarController.stop();
          _callDuration.start();
          _startDurationTimer();
        }
      };

      await signaling.openUserMedia(_localRenderer, _remoteRenderer,
          isVideo: true);

      // Start calling ringback tone (for caller only)
      if (_isCaller) {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        try {
          await _audioPlayer.play(AssetSource('audio/calling.wav'));
        } catch (e) {
          debugPrint('Calling audio failed: $e');
        }

        _callingTimeoutTimer = Timer(const Duration(seconds: 35), () {
          if (mounted && _connecting) {
            _audioPlayer.stop();
            try {
              signaling.hangUp(_localRenderer);
            } catch (_) {}
            setState(() {
              _connecting = false;
              _errorMsg = 'No answer from user.';
            });
          }
        });
      }

      if (_isCaller) {
        // ── Caller flow ──────────────────────────────────────────────────
        if (_otherUid.isNotEmpty) {
          // Direct call to specific user
          await signaling.createRoom(true, calleeUid: _otherUid);
        } else {
          // Fallback: random matchmaking
          final found = await matchmaking.findRandomMatch(true);
          if (found != null) {
            await signaling.joinRoom(found);
          } else {
            await signaling.createRoom(true);
          }
        }
      } else {
        // ── Callee flow ──────────────────────────────────────────────────
        // _roomId was passed from the incoming call notification
        if (_roomId.isNotEmpty) {
          await signaling.joinRoom(_roomId);
        } else {
          setState(() {
            _connecting = false;
            _errorMsg = 'Call room not found.';
          });
        }
      }

      final activeRoomId = signaling.roomId;
      if (activeRoomId != null && activeRoomId.isNotEmpty) {
        _roomStatusSub = signaling.listenToRoomStatus(activeRoomId, (status) {
          if ((status == 'connected' || status == 'accepted') && mounted) {
            try {
              _audioPlayer.setVolume(0.0);
              _audioPlayer.stop();
              _audioPlayer.release();
            } catch (_) {}
          }
          if (status == 'ended' && mounted) {
            try {
              _audioPlayer.setVolume(0.0);
              _audioPlayer.stop();
              _audioPlayer.release();
            } catch (_) {}
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _errorMsg = 'Failed to connect: $e';
        });
      }
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final elapsed = _callDuration.elapsed;
        final m = elapsed.inMinutes.toString().padLeft(2, '0');
        final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
        setState(() => _durationText = '$m:$s');
      }
    });
  }

  @override
  void dispose() {
    _callingTimeoutTimer?.cancel();
    _radarController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _roomStatusSub?.cancel();
    if (_callDuration.isRunning) {
      _callDuration.stop();
      _durationTimer?.cancel();
    }
    try {
      signaling.hangUp(_localRenderer, _remoteRenderer);
    } catch (_) {}
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _unmuteAudio() {
    try {
      signaling.localStream?.getAudioTracks().forEach((track) {
        track.enabled = !_audioMuted;
      });
      signaling.remoteStream?.getAudioTracks().forEach((track) {
        track.enabled = true;
        try {
          Helper.setVolume(1.0, track);
        } catch (_) {}
      });
      if (!kIsWeb) {
        try {
          Helper.setSpeakerphoneOn(true);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _toggleMic() {
    setState(() => _audioMuted = !_audioMuted);
    _unmuteAudio();
  }

  void _toggleVideo() {
    setState(() => _videoMuted = !_videoMuted);
    signaling.localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_videoMuted;
    });
  }

  void _endCall() {
    _audioPlayer.stop();
    if (_callDuration.isRunning) {
      _callDuration.stop();
      _durationTimer?.cancel();
    }
    try {
      signaling.hangUp(_localRenderer, _remoteRenderer);
    } catch (_) {}

    AdManager.showInterstitialAd(() {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/feedback', arguments: {
          'name': _contactName,
          'otherUid': _otherUid,
          'callType': 'video',
          'durationSeconds': _callDuration.elapsed.inSeconds,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _unmuteAudio,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // 1. Remote Video (Full Screen)
            Container(
              color: const Color(0xFF0F172A),
              child: _errorMsg == null
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const SizedBox.expand(),
            ),

            // 2. Connecting / Calling UI
            if (_connecting && _errorMsg == null) _buildCallingOverlay(),

            // 3. Error State
            if (_errorMsg != null) _buildErrorOverlay(),

            // 4. In-call branding + controls
            if (!_connecting && _errorMsg == null) ...[
              _buildTopBranding(),
              _buildBottomControls(),
            ],

            // 5. Local Video PIP
            if (_errorMsg == null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                bottom: _connecting ? 40 : 120,
                right: 20,
                child: _buildLocalPIP(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBranding() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _contactName,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(_durationText,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded,
                    color: Colors.greenAccent, size: 14),
                const SizedBox(width: 6),
                Text('Encrypted',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.85), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlBtn(
              icon: _videoMuted
                  ? Icons.videocam_off_rounded
                  : Icons.videocam_rounded,
              label: 'Video',
              isActive: !_videoMuted,
              onTap: _toggleVideo,
            ),
            _controlBtn(
              icon: _audioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: 'Mute',
              isActive: !_audioMuted,
              onTap: _toggleMic,
            ),
            _controlBtn(
              icon: Icons.flip_camera_android_rounded,
              label: 'Flip',
              isActive: true,
              onTap: () {
                signaling.localStream?.getVideoTracks().forEach((track) {
                  // ignore: deprecated_member_use
                  Helper.switchCamera(track);
                });
              },
            ),
            _controlBtn(
              icon: Icons.call_end_rounded,
              label: 'End',
              color: Colors.redAccent,
              isActive: true,
              onTap: _endCall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlBtn(
      {required IconData icon,
      required String label,
      required bool isActive,
      required VoidCallback onTap,
      Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color ??
                      (isActive
                          ? Colors.white.withOpacity(0.2)
                          : Colors.redAccent.withOpacity(0.3)),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLocalPIP() {
    return Container(
      width: 100,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: RTCVideoView(
          _localRenderer,
          mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
    );
  }

  Widget _buildCallingOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contact avatar with radar animation
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (index) {
                      final progress =
                          (_radarController.value + (index / 3)) % 1;
                      return Opacity(
                        opacity: 1 - progress,
                        child: Container(
                          width: 200 * progress,
                          height: 200 * progress,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.5),
                                width: 2),
                          ),
                        ),
                      );
                    }),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 40)
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        backgroundImage: _contactAvatarUrl != null
                            ? NetworkImage(_contactAvatarUrl!)
                            : null,
                        child: _contactAvatarUrl == null
                            ? Text(
                                _contactName.isNotEmpty
                                    ? _contactName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700))
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              _isCaller
                  ? 'Calling $_contactName...'
                  : 'Connecting to $_contactName...',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              _isCaller
                  ? 'Waiting for them to answer'
                  : 'Setting up secure connection',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 48),
            // End call button while ringing
            GestureDetector(
              onTap: _endCall,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle),
                child: const Icon(Icons.call_end_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            Text('Connection Failed',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(_errorMsg!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Go Back',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
