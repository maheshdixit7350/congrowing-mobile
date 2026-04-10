import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/signaling.dart';
import '../services/matchmaking_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/ad_manager.dart';
import '../utils/app_colors.dart';
import '../main.dart' show firebaseInitialized;

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
  final Signaling signaling = Signaling();
  final MatchmakingService matchmaking = MatchmakingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late AnimationController _radarController;
  late AnimationController _pulseController;
  
  bool _connecting = true;
  bool _audioMuted = false;
  bool _speakerOn = false;
  String? _errorMsg;

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

    _initVoiceCall();
  }

  Future<void> _initVoiceCall() async {
    if (!firebaseInitialized) {
      setState(() {
        _connecting = false;
        _errorMsg = 'Firebase is not initialized.\nPlease check your setup.';
      });
      return;
    }

    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      
      signaling.onAddRemoteStream = ((stream) {
        _remoteRenderer.srcObject = stream;
        _audioPlayer.stop(); // Stop ringing when connected
        if (mounted) {
          setState(() {
            _connecting = false;
          });
          _radarController.stop();
        }
      });

      await signaling.openUserMedia(_localRenderer, _remoteRenderer, isVideo: false);
      
      // Start ringing while waiting for connection
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource('https://www.soundjay.com/phone/phone-calling-1.mp3'));
      
      String? roomId = await matchmaking.findRandomMatch(false);
      if (roomId != null) {
        await signaling.joinRoom(roomId);
      } else {
        roomId = await signaling.createRoom(false);
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

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    try {
      signaling.hangUp(_localRenderer);
    } catch (_) {}
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _toggleMic() {
    setState(() => _audioMuted = !_audioMuted);
    signaling.localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_audioMuted;
    });
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    try {
      Helper.setSpeakerphoneOn(_speakerOn);
    } catch (_) {}
  }

  void _endCall() {
    _audioPlayer.stop();
    try {
      signaling.hangUp(_localRenderer);
    } catch (_) {}
    
    // Show ad after call
    AdManager.showInterstitialAd(() {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/feedback', arguments: {
          'name': 'Stranger',
          'otherUid': '',
          'callType': 'voice',
          'durationSeconds': 0,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
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
                  _buildRadarUI()
                else if (_errorMsg != null)
                  _buildErrorUI()
                else
                  _buildInCallUI(),

                const Spacer(),

                // Controls
                if (_errorMsg == null) _buildBottomControls(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Hidden renderer for audio routing
          Offstage(child: RTCVideoView(_remoteRenderer)),
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
            _connecting ? 'Looking for Match' : 'Connected',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_rounded, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 8),
              Text('Secure Voice Call', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarUI() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _radarController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: List.generate(3, (index) {
                double progress = (_radarController.value + (index / 3)) % 1;
                return Opacity(
                  opacity: 1 - progress,
                  child: Container(
                    width: 250 * progress,
                    height: 250 * progress,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                    ),
                  ),
                );
              })..add(
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 40)],
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.mic_none_rounded, color: Colors.white, size: 40),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        Text('Matching by Character Index...', style: GoogleFonts.inter(color: Colors.white70, fontSize: 15)),
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
                    color: AppColors.primary.withOpacity(0.1 * (1 - _pulseController.value)),
                  ),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30)],
                  ),
                  child: const Center(
                    child: Icon(Icons.person_outline_rounded, size: 70, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Text('Stranger', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text('4.9 Rating', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
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
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
          const SizedBox(height: 20),
          Text(_errorMsg!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Close', style: GoogleFonts.inter(color: Colors.white)),
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
                  icon: _audioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
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
                  icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
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

  Widget _controlBtn({required IconData icon, required bool isActive, required VoidCallback onTap, Color? color, bool isLarge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 20 : 16),
        decoration: BoxDecoration(
          color: color ?? (isActive ? Colors.white.withOpacity(0.1) : Colors.redAccent.withOpacity(0.2)),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.white, size: isLarge ? 32 : 24),
      ),
    );
  }
}
