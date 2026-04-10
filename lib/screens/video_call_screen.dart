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

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> with SingleTickerProviderStateMixin {
  final Signaling signaling = Signaling();
  final MatchmakingService matchmaking = MatchmakingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late AnimationController _radarController;
  
  bool _connecting = true;
  bool _audioMuted = false;
  bool _videoMuted = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initVideoCall();
  }

  Future<void> _initVideoCall() async {
    if (!firebaseInitialized) {
      setState(() {
        _connecting = false;
        _errorMsg = 'Firebase is not configured.\nPlease check your connection.';
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

      await signaling.openUserMedia(_localRenderer, _remoteRenderer, isVideo: true);
      
      // Start ringing while waiting for connection
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource('https://www.soundjay.com/phone/phone-calling-1.mp3'));
      
      // Find a match or create a room
      String? roomId = await matchmaking.findRandomMatch(true);
      if (roomId != null) {
        await signaling.joinRoom(roomId);
      } else {
        roomId = await signaling.createRoom(true);
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

  @override
  void dispose() {
    _radarController.dispose();
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

  void _toggleVideo() {
    setState(() => _videoMuted = !_videoMuted);
    signaling.localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_videoMuted;
    });
  }

  void _endCall() {
    _audioPlayer.stop();
    try {
      signaling.hangUp(_localRenderer);
    } catch (_) {}
    
    // Show ad after call, then navigate
    AdManager.showInterstitialAd(() {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/feedback', arguments: {
          'name': 'Stranger',
          'otherUid': '', 
          'callType': 'video', 
          'durationSeconds': 0,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Remote Video (Full Screen)
          Container(
            color: const Color(0xFF0F172A),
            child: _errorMsg == null && !_connecting
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : const SizedBox.expand(),
          ),

          // 2. Connecting Radar UI
          if (_connecting && _errorMsg == null) _buildRadarOverlay(),

          // 3. Error State
          if (_errorMsg != null) _buildErrorOverlay(),

          // 4. Scrims & Branding
          if (!_connecting && _errorMsg == null) ...[
            _buildTopBranding(),
            _buildBottomControls(),
          ],

          // 5. Local Video (PIP)
          if (_errorMsg == null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _connecting ? 40 : 120,
              right: 20,
              child: _buildLocalPIP(),
            ),
        ],
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
                'Connected with Stranger',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text('End-to-End Encrypted', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
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
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('4.8 CRI', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlBtn(
              icon: _videoMuted ? Icons.videocam_off_rounded : Icons.videocam_rounded,
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

  Widget _controlBtn({required IconData icon, required String label, required bool isActive, required VoidCallback onTap, Color? color}) {
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
                  color: color ?? (isActive ? Colors.white.withOpacity(0.2) : Colors.redAccent.withOpacity(0.3)),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
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

  Widget _buildRadarOverlay() {
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
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (index) {
                      double progress = (_radarController.value + (index / 3)) % 1;
                      return Opacity(
                        opacity: 1 - progress,
                        child: Container(
                          width: 200 * progress,
                          height: 200 * progress,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                          ),
                        ),
                      );
                    }),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 40)],
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person_search_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
            Text('Looking for a High CRI Match...', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Finding someone safe and verified for you', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
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
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            Text('Connection Failed', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(_errorMsg!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Return Home', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
