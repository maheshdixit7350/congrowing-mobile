import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../main.dart' show supabaseInitialized;
import '../services/user_service.dart';
import '../services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  String? _errorMessage;
  String? _usernameErrorMessage;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = false;
  bool _loading = false;
  bool _googleLoading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  Timer? _debounceTimer;

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    final cleanValue = value.trim().toLowerCase();
    if (cleanValue.isEmpty) {
      setState(() {
        _usernameErrorMessage = null;
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
      });
      return;
    }

    if (cleanValue.length < 3) {
      setState(() {
        _usernameErrorMessage = 'Username too short';
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!supabaseInitialized) {
        if (mounted) setState(() => _isCheckingUsername = false);
        return;
      }
      try {
        final res = await Supabase.instance.client
            .from('users')
            .select()
            .eq('username', cleanValue)
            .limit(1);

        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            if (res.isNotEmpty) {
              _usernameErrorMessage = 'Username already taken';
              _isUsernameAvailable = false;
            } else {
              _usernameErrorMessage = null;
              _isUsernameAvailable = true;
            }
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isCheckingUsername = false);
      }
    });
  }

  void _signup() async {
    setState(() => _errorMessage = null);

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final username = _usernameCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    if (name.isEmpty ||
        email.isEmpty ||
        username.isEmpty ||
        _selectedGender == null ||
        password.isEmpty ||
        _confirmPasswordCtrl.text.isEmpty) {
      setState(
          () => _errorMessage = 'Please fill in all fields (including gender)');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (password != _confirmPasswordCtrl.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (!_agreeTerms) {
      setState(() => _errorMessage = 'Please agree to the Terms of Service');
      return;
    }

    setState(() => _loading = true);

    if (!supabaseInitialized) {
      await Future.delayed(
          const Duration(milliseconds: 600)); // Simulate network request
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('proto_name', name);
      await prefs.setString('proto_username', username);
      await UserService.instance.loadCurrentUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Welcome to ConGrowing (Prototype), $name!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pushReplacementNamed(context, '/profile-setup');
      }
      return;
    }

    try {
      // Check Username uniqueness on Supabase
      try {
        final res = await Supabase.instance.client
            .from('users')
            .select()
            .eq('username', username)
            .limit(1);
        if (res.isNotEmpty) {
          setState(() {
            _errorMessage =
                'Username "@$username" is already taken. Please choose another one.';
            _loading = false;
          });
          return;
        }
      } catch (_) {
        // Proceed if table is not configured yet
      }

      final user =
          await SupabaseAuthService.instance.signUpWithEmailAndPassword(
        name: name,
        email: email,
        username: username,
        password: password,
        gender: _selectedGender,
      );

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await UserService.instance.loadCurrentUser();
        await UserService.instance.setOnlineStatus(true);
        final onboardingDone = await UserService.instance.isOnboardingComplete();

        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Welcome to ConGrowing, $name!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
          if (onboardingDone) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/profile-setup', (_) => false);
          }
        }
      }
    } catch (e) {
      final err = e.toString();
      String msg = 'An error occurred: ${err.split('\n')[0]}';
      if (err.contains('User already registered') || err.contains('User already exists')) {
        msg = 'The account already exists for that email. Please sign in instead.';
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await UserService.instance.loadCurrentUser();
      final onboardingDone = await UserService.instance.isOnboardingComplete();
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
        if (onboardingDone) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/profile-setup');
        }
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await UserService.instance.loadCurrentUser();
        await UserService.instance.setOnlineStatus(true);
        if (mounted) {
          setState(() => _googleLoading = false);
        }
      } else {
        // User cancelled
        setState(() => _googleLoading = false);
      }
    } catch (e) {
      debugPrint('SUPABASE GOOGLE SIGNUP ERROR: $e');
      setState(() {
        _errorMessage = 'Google Sign-In failed. Please try again.';
        _googleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.loginGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                            Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F2F44),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Join the ConGrowing community',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),

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
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // ── Google Sign-In Button ─────────────────────
                            GestureDetector(
                              onTap: _googleLoading ? null : _signInWithGoogle,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.grey.shade200, width: 1.5),
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
                                          errorBuilder: (c, e, s) => const Icon(
                                              Icons.g_mobiledata,
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
                                  child: Text('or sign up with email',
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

                            _buildField('FULL NAME', _nameCtrl,
                                'Enter your full name', Icons.person_outline),
                            const SizedBox(height: 14),
                            _buildField(
                                'USERNAME',
                                _usernameCtrl,
                                'Choose a unique username',
                                Icons.alternate_email,
                                onChanged: _onUsernameChanged,
                                errorText: _usernameErrorMessage,
                                successText: _isUsernameAvailable
                                    ? 'Username available ✓'
                                    : null,
                                isLoading: _isCheckingUsername),
                            const SizedBox(height: 14),
                            _buildField('EMAIL', _emailCtrl, 'Enter your email',
                                Icons.email_outlined),
                            const SizedBox(height: 14),
                            _buildGenderDropdown(),
                            const SizedBox(height: 14),
                            _buildField(
                              'PASSWORD',
                              _passwordCtrl,
                              'Create a password',
                              Icons.lock_outline,
                              obscure: _obscurePassword,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              'CONFIRM PASSWORD',
                              _confirmPasswordCtrl,
                              'Confirm your password',
                              Icons.lock_outline,
                              obscure: _obscureConfirm,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                child: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _agreeTerms,
                                    onChanged: (v) => setState(
                                        () => _agreeTerms = v ?? false),
                                    activeColor: AppColors.loginSecondary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/terms'),
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.grey.shade500),
                                        children: const [
                                          TextSpan(text: 'I agree to the '),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: TextStyle(
                                              color: AppColors.loginSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: ' & '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: AppColors.loginSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _loading ? null : _signup,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0F2F44),
                                      Color(0xFF1A4A6B)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F2F44)
                                          .withAlpha(102),
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
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'CREATE ACCOUNT',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(
                                      context, '/login'),
                                  child: Text(
                                    'Sign In',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.loginSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint,
    IconData prefixIcon, {
    bool obscure = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
    String? errorText,
    String? successText,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 1.0,
              ),
            ),
            if (isLoading)
              const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.grey))
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: errorText != null
                    ? Colors.red.shade200
                    : Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade900),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
              prefixIcon:
                  Icon(prefixIcon, color: Colors.grey.shade400, size: 20),
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: suffixIcon)
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(errorText,
                style: GoogleFonts.inter(
                    color: Colors.red.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          )
        else if (successText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(successText,
                style: GoogleFonts.inter(
                    color: Colors.green.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          )
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENDER',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text('Select your gender',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.grey.shade400)),
              value: _selectedGender,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
              dropdownColor: Colors.white,
              items: ['Male', 'Female', 'Non-Binary', 'Prefer not to say']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.grey.shade900)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedGender = val;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
