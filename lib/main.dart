import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'utils/app_theme.dart';
import 'utils/theme_provider.dart';
import 'utils/ad_manager.dart';
import 'services/user_service.dart';

/// Global flag so other parts of the app can check if Firebase initialised.
bool firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ─────────────────────────────────────────────────────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');
    // Load current user if already signed in
    await UserService.instance.loadCurrentUser();
    await UserService.instance.setOnlineStatus(true);
  } catch (e) {
    firebaseInitialized = false;
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('   The app will continue without Firebase services.');
    debugPrint('   To fix: place google-services.json in android/app/');
  }

  // ── AdMob ────────────────────────────────────────────────────────────────
  try {
    await MobileAds.instance.initialize();
    AdManager.loadInterstitialAd();
  } catch (e) {
    debugPrint('⚠️ AdMob initialization failed: $e');
  }

  // ── System UI ────────────────────────────────────────────────────────────
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(ConGrowingApp());
}

class ConGrowingApp extends StatelessWidget {
  ConGrowingApp({super.key});

  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  Widget build(BuildContext context) {
    return ThemeProviderScope(
      provider: _themeProvider,
      child: AnimatedBuilder(
        animation: _themeProvider,
        builder: (context, _) {
          return MaterialApp(
            title: 'ConGrowing',
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
              };

              final builder = routes[settings.name];
              if (builder != null) {
                return MaterialPageRoute(builder: builder, settings: settings);
              }
              return MaterialPageRoute(builder: (ctx) => const SplashScreen(), settings: settings);
            },
          );
        },
      ),
    );
  }
}
