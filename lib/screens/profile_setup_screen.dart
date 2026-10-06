import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/location_data.dart';
import '../services/user_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentStep = 0;

  /// If gender was already chosen during signup, skip the gender step.
  bool _skipGender = false;

  // ── Step 1: Gender ──────────────────────────────────────────────────────
  String? _selectedGender;
  static const _genderOptions = [
    {'label': 'Male', 'icon': Icons.male_rounded},
    {'label': 'Female', 'icon': Icons.female_rounded},
    {'label': 'Non-binary', 'icon': Icons.transgender_rounded},
    {'label': 'Prefer not to say', 'icon': Icons.person_outline_rounded},
  ];

  // ── Step 2: Location ────────────────────────────────────────────────────
  String? _selectedCountry;
  String? _selectedState;
  final _countrySearchCtrl = TextEditingController();
  List<String> _filteredCountries = [];

  // ── Animation ───────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _filteredCountries = LocationData.countries;

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Check if gender was already set during signup
    _checkExistingGender();
  }

  void _checkExistingGender() {
    final user = UserService.instance.currentUser;
    if (user != null &&
        user.gender != null &&
        user.gender!.isNotEmpty &&
        user.gender != 'Prefer not to say') {
      // Gender already provided during signup — skip that step
      setState(() {
        _selectedGender = user.gender;
        _skipGender = true;
        _currentStep = 0; // This is now the location step (only step)
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _countrySearchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────
  void _nextStep() {
    if (!_skipGender && _currentStep < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (!_skipGender && _currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Save & Navigate ─────────────────────────────────────────────────────
  void _completeOnboardingWithoutTest() async {
    if (_selectedGender == null || _selectedCountry == null || _selectedState == null || _saving) return;
    setState(() => _saving = true);

    try {
      await UserService.instance.completeOnboarding(
        gender: _selectedGender!,
        country: _selectedCountry!,
        state: _selectedState!,
        personalityType: 'Explorer', // Default personality type
        criScore: 500, // Default average CRI score
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Something went wrong. Please try again.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        setState(() => _saving = false);
      }
    }
  }

  // ── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: AppColors.loginGradient),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildProgressBar(),
                  Expanded(
                    child: _skipGender
                        // Gender already set — only show location step
                        ? _buildLocationStep()
                        : PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (i) =>
                                setState(() => _currentStep = i),
                            children: [
                              _buildGenderStep(),
                              _buildLocationStep(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Progress Bar ────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    if (_skipGender) {
      // Only one step — Location
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Location',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    const labels = ['Gender', 'Location'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            children: List.generate(2, (i) {
              final active = i <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: active
                              ? Colors.white
                              : Colors.white.withAlpha(51),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[i],
                        style: GoogleFonts.inter(
                          color: active
                              ? Colors.white
                              : Colors.white.withAlpha(102),
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 1 — GENDER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildGenderStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'How do you identify?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalize your experience',
            style: GoogleFonts.inter(
              color: Colors.white.withAlpha(179),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(_genderOptions.length, (i) {
            final opt = _genderOptions[i];
            final selected = _selectedGender == opt['label'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedGender = opt['label'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withAlpha(38)
                        : Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.white.withAlpha(128)
                          : Colors.white.withAlpha(26),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.white.withAlpha(26),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withAlpha(38)
                              : Colors.white.withAlpha(13),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          opt['icon'] as IconData,
                          color: selected
                              ? Colors.white
                              : Colors.white.withAlpha(179),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          opt['label'] as String,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? AppColors.loginSecondaryLight
                              : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? AppColors.loginSecondaryLight
                                : Colors.white.withAlpha(77),
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          _buildNextButton(
            enabled: _selectedGender != null,
            onTap: _nextStep,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 2 — LOCATION
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Where are you from?',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Connect with people from your region',
              style: GoogleFonts.inter(
                color: Colors.white.withAlpha(179),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Country label
          Text(
            'Country',
            style: GoogleFonts.inter(
              color: Colors.white.withAlpha(204),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildGlassDropdown(
            hint: 'Select your country',
            value: _selectedCountry != null
                ? '${LocationData.getCountryFlag(_selectedCountry!)}   $_selectedCountry'
                : null,
            onTap: () => _showSearchableCountryPicker(),
          ),

          const SizedBox(height: 24),

          // State label
          Text(
            'State / Province',
            style: GoogleFonts.inter(
              color: Colors.white.withAlpha(204),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildGlassDropdown(
            hint: _selectedCountry == null
                ? 'Select country first'
                : 'Select your state / province',
            value: _selectedState,
            onTap: _selectedCountry == null
                ? null
                : () => _showStatePicker(),
          ),

          const SizedBox(height: 40),
          if (_skipGender)
            // Only location step — just show Complete Setup button
            _buildNextButton(
              enabled: _selectedCountry != null && _selectedState != null,
              onTap: _completeOnboardingWithoutTest,
              label: 'Complete Setup',
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildBackButton(onTap: _prevStep),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildNextButton(
                    enabled:
                        _selectedCountry != null && _selectedState != null,
                    onTap: _completeOnboardingWithoutTest,
                    label: 'Complete Setup',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String hint,
    String? value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(38)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: GoogleFonts.inter(
                      color: value != null
                          ? Colors.white
                          : Colors.white.withAlpha(102),
                      fontSize: 15,
                      fontWeight:
                          value != null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withAlpha(128),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchableCountryPicker() {
    _countrySearchCtrl.clear();
    _filteredCountries = LocationData.countries;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF1A2D3D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _countrySearchCtrl,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search country…',
                        hintStyle: GoogleFonts.inter(
                            color: Colors.white.withAlpha(102)),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Colors.white.withAlpha(128)),
                        filled: true,
                        fillColor: Colors.white.withAlpha(13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (q) {
                        setSheetState(() {
                          _filteredCountries = LocationData.countries
                              .where((c) => c
                                  .toLowerCase()
                                  .contains(q.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredCountries.length,
                      itemBuilder: (ctx, i) {
                        final c = _filteredCountries[i];
                        final selected = c == _selectedCountry;
                        final flag = LocationData.getCountryFlag(c);
                        return ListTile(
                          title: Row(
                            children: [
                              Text(
                                flag,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  c,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.loginSecondaryLight)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCountry = c;
                              _selectedState = null; // reset state
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStatePicker() {
    if (_selectedCountry == null) return;
    final states = LocationData.getStates(_selectedCountry!);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A2D3D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Select State / Province',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: states.length,
                  itemBuilder: (ctx, i) {
                    final s = states[i];
                    final selected = s == _selectedState;
                    return ListTile(
                      title: Text(
                        s,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.loginSecondaryLight)
                          : null,
                      onTap: () {
                        setState(() => _selectedState = s);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── SHARED WIDGETS ───────────────────────────────────────────────────────
  Widget _buildNextButton({
    required bool enabled,
    required VoidCallback onTap,
    String label = 'Continue',
  }) {
    return GestureDetector(
      onTap: (enabled && !_saving) ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.loginPrimary,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: enabled
                            ? AppColors.loginPrimary
                            : Colors.white.withAlpha(102),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: enabled
                          ? AppColors.loginPrimary
                          : Colors.white.withAlpha(102),
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBackButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(38)),
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white.withAlpha(179),
          ),
        ),
      ),
    );
  }
}
