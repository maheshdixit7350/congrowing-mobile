import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/call_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/search_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/cri_analytics_screen.dart';
import 'screens/play_screen.dart';
import 'screens/about_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/video_call_screen.dart';
import 'screens/voice_call_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/connections_screen.dart';
import 'screens/user_profile_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'utils/app_theme.dart';
import 'utils/theme_provider.dart';
import 'utils/ad_manager.dart';
import 'services/user_service.dart';
import 'services/signaling.dart';
import 'models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'services/supabase_auth_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'utils/audio_helper.dart';

/// Global flag so other parts of the app can check if Supabase initialised.
bool supabaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase ─────────────────────────────────────────────────────────────
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    supabaseInitialized = true;
    debugPrint('Supabase initialized successfully.');
  } catch (e) {
    supabaseInitialized = false;
    debugPrint('⚠️ Supabase initialization failed: $e');
  }

  bool userLoggedIn = false;
  if (supabaseInitialized) {
    userLoggedIn = SupabaseAuthService.instance.currentUser != null;
  }

  try {
    if (userLoggedIn) {
      await UserService.instance.loadCurrentUser();
      await UserService.instance.setOnlineStatus(true);
    } else {
      // Load mock user directly for prototype
      await UserService.instance.loadCurrentUser();
    }
  } catch (e) {
    debugPrint('⚠️ Error loading user state on startup: $e');
  }

  // ── AdMob ────────────────────────────────────────────────────────────────
  try {
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      AdManager.loadInterstitialAd();
    }
  } catch (e) {
    debugPrint('⚠️ AdMob initialization failed: $e');
  }

  // ── System UI ────────────────────────────────────────────────────────────
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ConGrowingApp());
}

class ConGrowingApp extends StatefulWidget {
  const ConGrowingApp({super.key});

  /// Global navigator key so auth callbacks can push routes.
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<ConGrowingApp> createState() => _ConGrowingAppState();
}

class _ConGrowingAppState extends State<ConGrowingApp>
    with WidgetsBindingObserver {
  final ThemeProvider _themeProvider = ThemeProvider();
  StreamSubscription<dynamic>? _authSub;
  StreamSubscription? _incomingCallSub;
  final Signaling _signalingListener = Signaling();
  final AudioPlayer _incomingRingtonePlayer = AudioPlayer();
  BuildContext? _incomingCallDialogContext;
  bool _isIncomingCallDialogShowing = false;
  String? _activeIncomingRoomId;
  final Set<String> _handledRoomIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (supabaseInitialized) {
      _authSub =
          SupabaseAuthService.instance.authStateChanges.listen((user) async {
        final prefs = await SharedPreferences.getInstance();
        if (user != null) {
          await prefs.setBool('isLoggedIn', true);
          await UserService.instance.loadCurrentUser();
          await UserService.instance.setOnlineStatus(true);
          final onboardingDone =
              await UserService.instance.isOnboardingComplete();
          final nav = ConGrowingApp.navigatorKey.currentState;
          if (nav != null) {
            if (onboardingDone) {
              nav.pushNamedAndRemoveUntil('/home', (_) => false);
            } else {
              nav.pushNamedAndRemoveUntil('/profile-setup', (_) => false);
            }
          }
          // Start listening for incoming calls after login
          _startIncomingCallListener(user.id);
        } else {
          await prefs.setBool('isLoggedIn', false);
          _incomingCallSub?.cancel();
          _incomingCallSub = null;
        }
      });

      // If already logged in, start listener and set online status immediately
      final currentUid = SupabaseAuthService.instance.currentUser?.id;
      if (currentUid != null) {
        _startIncomingCallListener(currentUid);
        UserService.instance.setOnlineStatus(true);
      }

    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!supabaseInitialized) return;
    final currentUid = SupabaseAuthService.instance.currentUser?.id;
    if (currentUid == null) return;

    if (state == AppLifecycleState.resumed) {
      unawaited(UserService.instance.setOnlineStatus(true));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(UserService.instance.setOnlineStatus(false));
    }
  }

  void _startIncomingCallListener(String myUid) {
    _incomingCallSub?.cancel();
    _incomingCallSub = _signalingListener.listenForIncomingCall(
      myUid,
      (roomId, callType, callerId, status) {
        final nav = ConGrowingApp.navigatorKey.currentState;
        if (nav == null) return;

        if (status == 'ringing') {
          if (_isIncomingCallDialogShowing ||
              _activeIncomingRoomId != null ||
              _handledRoomIds.contains(roomId) ||
              Signaling.activeCallRoomId != null) {
            return;
          }
          _activeIncomingRoomId = roomId;
          _showIncomingCallDialog(nav.context, roomId, callType, callerId);
        } else if (status == 'ended' || status == 'connected' || status == 'accepted') {
          _handledRoomIds.add(roomId);
          if (_activeIncomingRoomId == roomId || _isIncomingCallDialogShowing) {
            _activeIncomingRoomId = null;
            _isIncomingCallDialogShowing = false;
            AudioHelper.stopPlayer(_incomingRingtonePlayer);
            try {
              _incomingRingtonePlayer.setVolume(0.0);
              _incomingRingtonePlayer.stop();
              _incomingRingtonePlayer.release();
            } catch (_) {}
            if (_incomingCallDialogContext != null) {
              try {
                Navigator.of(_incomingCallDialogContext!).pop();
              } catch (_) {}
              _incomingCallDialogContext = null;
            }
          }
        }
      },
    );
  }

  void _showIncomingCallDialog(
      BuildContext context, String roomId, String callType, String callerId) {
    if (_isIncomingCallDialogShowing ||
        _handledRoomIds.contains(roomId) ||
        Signaling.activeCallRoomId != null) return;
    _isIncomingCallDialogShowing = true;
    _activeIncomingRoomId = roomId;

    AudioHelper.startLooping(_incomingRingtonePlayer, 'audio/ringing.wav');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _incomingCallDialogContext = ctx;
        return FutureBuilder<UserModel?>(
          future: callerId.isNotEmpty
              ? UserService.instance.getUserById(callerId)
              : Future.value(null),
          builder: (context, snapshot) {
            final callerUser = snapshot.data;
            final callerName = callerUser?.name ?? 'Someone';
            final callerAvatar = callerUser?.avatarUrl;

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: callType == 'video'
                          ? const Color(0xFF6C63FF).withOpacity(0.2)
                          : const Color(0xFF10B981).withOpacity(0.2),
                    ),
                    child: Icon(
                      callType == 'video'
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      color: callType == 'video'
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF10B981),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Incoming ${callType == 'video' ? 'Video' : 'Voice'} Call',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$callerName is calling you',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () {
                    _handledRoomIds.add(roomId);
                    _activeIncomingRoomId = null;
                    _isIncomingCallDialogShowing = false;
                    _incomingCallDialogContext = null;
                    AudioHelper.stopPlayer(_incomingRingtonePlayer);
                    try {
                      _incomingRingtonePlayer.stop();
                    } catch (_) {}
                    try {
                      Supabase.instance.client.from('rooms').update({
                        'status': 'ended',
                        'updated_at': DateTime.now().toIso8601String(),
                      }).eq('id', roomId).then((_) {});
                    } catch (_) {}
                    Navigator.pop(ctx);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: Text('Decline',
                      style: GoogleFonts.inter(
                          color: Colors.redAccent, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () {
                    _handledRoomIds.add(roomId);
                    Signaling.activeCallRoomId = roomId;
                    _activeIncomingRoomId = null;
                    _isIncomingCallDialogShowing = false;
                    _incomingCallDialogContext = null;
                    AudioHelper.stopPlayer(_incomingRingtonePlayer);
                    try {
                      _incomingRingtonePlayer.stop();
                    } catch (_) {}
                    try {
                      Supabase.instance.client.from('rooms').update({
                        'status': 'connected',
                        'updated_at': DateTime.now().toIso8601String(),
                      }).eq('id', roomId).then((_) {});
                    } catch (_) {}
                    Navigator.pop(ctx);
                    final route =
                        callType == 'video' ? '/video-call' : '/voice-call';
                    ConGrowingApp.navigatorKey.currentState?.pushNamed(
                      route,
                      arguments: {
                        'roomId': roomId,
                        'isCaller': false,
                        'name': callerName,
                        'avatarUrl': callerAvatar,
                        'otherUid': callerId,
                      },
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: Text('Accept',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _handledRoomIds.add(roomId);
      _activeIncomingRoomId = null;
      _incomingCallDialogContext = null;
      _isIncomingCallDialogShowing = false;
      AudioHelper.stopPlayer(_incomingRingtonePlayer);
      try {
        _incomingRingtonePlayer.stop();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _incomingCallSub?.cancel();
    _incomingRingtonePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProviderScope(
      provider: _themeProvider,
      child: AnimatedBuilder(
        animation: _themeProvider,
        builder: (context, _) {
          return MaterialApp(
            title: 'ConGrowing',
            navigatorKey: ConGrowingApp.navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeProvider.themeMode,
            initialRoute: '/',
            onGenerateRoute: (settings) {
              final routes = <String, WidgetBuilder>{
                '/': (ctx) => const SplashScreen(),
                '/onboarding': (ctx) => const OnboardingScreen(),
                '/login': (ctx) => const LoginScreen(),
                '/signup': (ctx) => const SignupScreen(),
                '/forgot-password': (ctx) => const ForgotPasswordScreen(),
                '/home': (ctx) => const HomeScreen(),
                '/messages': (ctx) => const MessagesScreen(),
                '/chat': (ctx) => const ChatScreen(),
                '/call': (ctx) => const CallScreen(),
                '/notifications': (ctx) => const NotificationsScreen(),
                '/create-post': (ctx) => const CreatePostScreen(),
                '/my-profile': (ctx) => const MyProfileScreen(),
                '/edit-profile': (ctx) => const EditProfileScreen(),
                '/settings': (ctx) => const SettingsScreen(),
                '/search': (ctx) => const SearchScreen(),
                '/leaderboard': (ctx) => const LeaderboardScreen(),
                '/cri-analytics': (ctx) => const CriAnalyticsScreen(),
                '/play': (ctx) => const PlayScreen(),
                '/about': (ctx) => const AboutScreen(),
                '/privacy-policy': (ctx) => const PrivacyPolicyScreen(),
                '/terms': (ctx) => const TermsScreen(),
                '/video-call': (ctx) => const VideoCallScreen(),
                '/voice-call': (ctx) => const VoiceCallScreen(),
                '/feedback': (ctx) => const FeedbackScreen(),
                '/profile-setup': (ctx) => const ProfileSetupScreen(),
                '/connections': (ctx) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final userId = args?['userId'] as String?;
                  final tabIndex = args?['tabIndex'] as int? ?? 0;
                  return ConnectionsScreen(
                      userId: userId, initialTabIndex: tabIndex);
                },
                '/user-profile': (ctx) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final userId = args?['userId'] as String? ?? '';
                  return UserProfileScreen(userId: userId);
                },
              };

              final builder = routes[settings.name];
              if (builder != null) {
                return MaterialPageRoute(builder: builder, settings: settings);
              }
              return MaterialPageRoute(
                  builder: (ctx) => const SplashScreen(), settings: settings);
            },
          );
        },
      ),
    );
  }
}
