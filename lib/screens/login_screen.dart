import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../main.dart' show supabaseInitialized;
import '../services/user_service.dart';
import '../services/supabase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _loading = false;
  bool _googleLoading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Email/Password Login ────────────────────────────────────────────────
  void _login() async {
    String emailInput = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    setState(() => _errorMessage = null);

    if (emailInput.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    setState(() => _loading = true);

    if (!supabaseInitialized) {
      await Future.delayed(
          const Duration(milliseconds: 600)); // Simulate network request
      await _onLoginSuccess();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Running in Prototype Mode (Offline)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    try {
      final user =
          await SupabaseAuthService.instance.signInWithEmailAndPassword(
        emailInput,
        password,
      );
      if (user != null) {
        // Navigation is driven by the authStateChanges listener in main.dart.
        // _onLoginSuccess only updates prefs / loads the user profile.
        await _onLoginSuccess();
      } else {
        // Shouldn't normally happen, but reset loading state if it does.
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      final err = e.toString();
      String msg = 'Login failed. Please try again.';
      if (err.contains('Invalid login credentials')) {
        msg = 'Invalid email or password.';
      } else if (err.contains('Email not confirmed')) {
        msg =
            'Email not confirmed. Please check your inbox for the confirmation link, or disable "Confirm Email" in your Supabase Auth dashboard.';
      } else {
        msg = 'Login failed: ${err.split('\n')[0]}';
      }
      if (mounted) {
        setState(() {
          _errorMessage = msg;
          _loading = false;
        });
      }
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────
  void _signInWithGoogle() async {
    if (!supabaseInitialized) {
      setState(() => _googleLoading = true);
      await Future.delayed(
          const Duration(milliseconds: 600)); // Simulate network request
      await _onLoginSuccess();
      if (mounted) {
        setState(() => _googleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Running in Prototype Mode (Offline)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await SupabaseAuthService.instance.signInWithGoogle();
      if (user != null) {
        // Navigation is driven by the authStateChanges listener in main.dart.
        await _onLoginSuccess();
      } else {
        if (mounted) setState(() => _googleLoading = false);
      }
    } catch (e) {
      debugPrint('SUPABASE GOOGLE LOGIN ERROR: $e');
      final err = e.toString();
      String msg = 'Google Sign-In failed.';
      if (err.contains('ApiException: 10') || err.contains('sign_in_failed')) {
        msg =
            'Google Sign-In failed (API Exception 10). This usually means your app\'s SHA-1 debug fingerprint is not registered in the Firebase / Google Cloud Console for this project.';
      } else {
        msg = 'Google Sign-In failed: ${err.split('\n')[0]}';
      }
      if (mounted) {
        setState(() {
          _errorMessage = msg;
          _googleLoading = false;
        });
      }
    }
  }

  Future<void> _onLoginSuccess() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    // Navigation is handled by the global authStateChanges listener in main.dart.
    // Doing it here too causes a double-navigation race condition (SH-1 bug).
    // For non-Supabase (prototype) mode, navigate manually since there is no
    // auth state listener.
    if (!supabaseInitialized) {
      await UserService.instance.loadCurrentUser();
      final onboardingDone = await UserService.instance.isOnboardingComplete();
      if (mounted) {
        if (onboardingDone) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/profile-setup');
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2F44),
                Color(0xFF1A4A6B),
                Color(0xFF2D6E4E),
                Color(0xFF3A7F41),
                Color(0xFF0F2F44),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(77),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top colored strip
                        Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0F2F44),
                                Color(0xFF3A7F41),
                                Color(0xFFF4C430)
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            _buildLogoFallback(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              Text(
                                'Welcome Back',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F2F44),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to continue growing',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: Colors.grey.shade500),
                              ),

                              // Error message
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.red, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // ── Google Sign-In Button ─────────────────────
                              GestureDetector(
                                onTap:
                                    _googleLoading ? null : _signInWithGoogle,
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withAlpha(10),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_googleLoading)
                                        const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.5))
                                      else ...[
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: Image.network(
                                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(Icons.g_mobiledata,
                                                    size: 26,
                                                    color: Colors.blue),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Continue with Google',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                      child: Container(
                                          height: 1,
                                          color: Colors.grey.shade200)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text('or sign in with email',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.grey.shade400,
                                            letterSpacing: 0.5)),
                                  ),
                                  Expanded(
                                      child: Container(
                                          height: 1,
                                          color: Colors.grey.shade200)),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Email Field
                              _buildLabel('EMAIL'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _usernameCtrl,
                                hint: 'Enter your email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 14),

                              // Password Field
                              _buildLabel('PASSWORD'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _passwordCtrl,
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline,
                                obscure: _obscurePassword,
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                  child: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Forgot / Create Account
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, '/forgot-password'),
                                    child: Text('Forgot Password?',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/signup'),
                                    child: Text('Create Account →',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF3A7F41),
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Sign In Button
                              GestureDetector(
                                onTap: _loading ? null : _login,
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFF0F2F44),
                                      Color(0xFF1A4A6B)
                                    ]),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F2F44)
                                            .withAlpha(100),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5))
                                        : Text('SIGN IN',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                letterSpacing: 1.2)),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Terms
                              Text(
                                'By signing in, you agree to our Terms of Service & Privacy Policy',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Container(
      decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24)),
      child: const Center(
          child: Text('CG',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900))),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 1.0),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade900),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
          prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: 20),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 4), child: suffixIcon)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
