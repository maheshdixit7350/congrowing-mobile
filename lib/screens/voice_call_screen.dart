import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/signaling.dart';
import '../services/matchmaking_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/ad_manager.dart';
import '../utils/app_colors.dart';
import '../main.dart' show supabaseInitialized;

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {
  final Signaling signaling = Signaling();
  final MatchmakingService matchmaking = MatchmakingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _radarController;
  late AnimationController _pulseController;

  // Route args
  String _otherUid = '';
  String _contactName = 'Stranger';
  String? _contactAvatarUrl;
  bool _isCaller = false;
  String _roomId = '';

  bool _connecting = true;
  bool _audioMuted = false;
  bool _speakerOn = true;
  bool _initialized = false;
  String? _errorMsg;

  // Duration timer
  final Stopwatch _callDuration = Stopwatch();
  Timer? _durationTimer;
  String _durationText = '00:00';

  // Subscriptions
  StreamSubscription? _roomStatusSub;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
      _initVoiceCall();
    }
  }

  Future<void> _initVoiceCall() async {
    if (!supabaseInitialized) {
      setState(() {
        _connecting = false;
        _errorMsg = 'Backend is not initialized.\nPlease check your setup.';
      });
      return;
    }

    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      signaling.onAddRemoteStream = (stream) async {
        _remoteRenderer.srcObject = stream;
        try {
          await _audioPlayer.stop();
        } catch (_) {}

        try {
          Helper.setSpeakerphoneOn(true);
        } catch (e) {
          debugPrint('Audio output setup error: $e');
        }

        for (final track in stream.getAudioTracks()) {
          track.enabled = true;
          try {
            Helper.setVolume(1.0, track);
          } catch (_) {}
        }

        if (mounted) {
          setState(() => _connecting = false);
          _radarController.stop();
          _callDuration.start();
          _startDurationTimer();
        }
      };

      await signaling.openUserMedia(_localRenderer, _remoteRenderer,
          isVideo: false);

      // Start calling ringback tone (for caller only)
      if (_isCaller) {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        try {
          await _audioPlayer.play(AssetSource('audio/calling.wav'));
        } catch (e) {
          debugPrint('Calling audio failed: $e');
        }
      }

      if (_isCaller) {
        if (_otherUid.isNotEmpty) {
          // Direct call to specific user
          await signaling.createRoom(false, calleeUid: _otherUid);
        } else {
          // Fallback: random matchmaking
          final found = await matchmaking.findRandomMatch(false);
          if (found != null) {
            await signaling.joinRoom(found);
          } else {
            await signaling.createRoom(false);
          }
        }
      } else {
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
          if (status == 'ended' && mounted) {
            _audioPlayer.stop();
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
          _errorMsg = 'Failed to start call: $e';
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
    _radarController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _roomStatusSub?.cancel();
    if (_callDuration.isRunning) {
      _callDuration.stop();
      _durationTimer?.cancel();
    }
    try {
      signaling.hangUp(_localRenderer);
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
      try {
        Helper.setSpeakerphoneOn(_speakerOn);
      } catch (_) {}
    } catch (_) {}
  }

  void _toggleMic() {
    setState(() => _audioMuted = !_audioMuted);
    _unmuteAudio();
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    _unmuteAudio();
  }

  void _endCall() {
    _audioPlayer.stop();
    if (_callDuration.isRunning) {
      _callDuration.stop();
      _durationTimer?.cancel();
    }
    try {
      signaling.hangUp(_localRenderer);
    } catch (_) {}

    AdManager.showInterstitialAd(() {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/feedback', arguments: {
          'name': _contactName,
          'otherUid': _otherUid,
          'callType': 'voice',
          'durationSeconds': _callDuration.elapsed.inSeconds,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: GestureDetector(
        onTap: _unmuteAudio,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
              ),
            ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBranding(),
                const Spacer(),
                if (_connecting && _errorMsg == null)
                  _buildCallingUI()
                else if (_errorMsg != null)
                  _buildErrorUI()
                else
                  _buildInCallUI(),
                const Spacer(),
                if (_errorMsg == null) _buildBottomControls(),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Active media renderer for audio routing
          Positioned(
            bottom: 20,
            left: 20,
            child: SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(_remoteRenderer),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBranding() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            _connecting ? (_isCaller ? 'Calling...' : 'Connecting...') : 'Connected',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (!_connecting)
            Text(
              _durationText,
              style: GoogleFonts.inter(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_rounded,
                    color: Colors.greenAccent, size: 14),
                const SizedBox(width: 6),
                Text('Secure Voice Call',
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCallingUI() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _radarController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(3, (index) {
                  final progress = (_radarController.value + (index / 3)) % 1;
                  return Opacity(
                    opacity: 1 - progress,
                    child: Container(
                      width: 260 * progress,
                      height: 260 * progress,
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
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 40)
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
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
                                fontSize: 40,
                                fontWeight: FontWeight.w700))
                        : null,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Text(_contactName,
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          _isCaller ? 'Ringing...' : 'Connecting...',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildInCallUI() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160 + (20 * _pulseController.value),
                  height: 160 + (20 * _pulseController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary
                        .withOpacity(0.08 * (1 - _pulseController.value)),
                  ),
                ),
                CircleAvatar(
                  radius: 70,
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
                              fontSize: 52,
                              fontWeight: FontWeight.w700))
                      : null,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Text(_contactName,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: Colors.greenAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Connected', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 60),
          const SizedBox(height: 20),
          Text(_errorMsg!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Close',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlBtn(
                  icon: _audioMuted
                      ? Icons.mic_off_rounded
                      : Icons.mic_rounded,
                  isActive: !_audioMuted,
                  onTap: _toggleMic,
                ),
                const SizedBox(width: 20),
                _controlBtn(
                  icon: Icons.call_end_rounded,
                  isActive: true,
                  color: Colors.redAccent,
                  isLarge: true,
                  onTap: _endCall,
                ),
                const SizedBox(width: 20),
                _controlBtn(
                  icon: _speakerOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                  isActive: _speakerOn,
                  onTap: _toggleSpeaker,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlBtn(
      {required IconData icon,
      required bool isActive,
      required VoidCallback onTap,
      Color? color,
      bool isLarge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 20 : 16),
        decoration: BoxDecoration(
          color: color ??
              (isActive
                  ? Colors.white.withOpacity(0.1)
                  : Colors.redAccent.withOpacity(0.2)),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.white, size: isLarge ? 32 : 24),
      ),
    );
  }
}
