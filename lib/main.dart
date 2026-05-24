import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'services/camera_service.dart';
import 'services/model_service.dart';
import 'services/permission_handler.dart';

const String _onboardingSeenKey = 'onboarding_seen';
const String _termsAcceptedKey = 'accepted_terms';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class SmartBridgeLogo extends StatelessWidget {
  const SmartBridgeLogo({
    super.key,
    this.size = 38,
    this.backgroundColor,
    this.borderColor,
  });

  final double size;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        color: backgroundColor ?? scheme.primaryContainer,
        border: Border.all(
          color: borderColor ?? scheme.primary.withValues(alpha: 0.45),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.18),
        child: Image.asset(
          'smartbridge.png',
          fit: BoxFit.cover,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return Icon(
                  Icons.sign_language,
                  size: size * 0.5,
                  color: scheme.primary,
                );
              },
        ),
      ),
    );
  }
}

@immutable
class AppUiPreferences {
  const AppUiPreferences({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.highContrast = false,
    this.reduceMotion = false,
    this.hapticsEnabled = true,
    this.autoSpeakSigns = false,
    this.ttsRate = 0.5,
    this.ttsPitch = 1.0,
    this.ttsVolume = 1.0,
    this.recognitionThreshold = 35.0,
    this.historyConfidenceThreshold = 60.0,
    this.frameStride = 2,
  });

  static const String _themeModeKey = 'pref_theme_mode';
  static const String _textScaleKey = 'pref_text_scale';
  static const String _highContrastKey = 'pref_high_contrast';
  static const String _reduceMotionKey = 'pref_reduce_motion';
  static const String _hapticsKey = 'pref_haptics_enabled';
  static const String _autoSpeakSignsKey = 'pref_auto_speak_signs';
  static const String _ttsRateKey = 'pref_tts_rate';
  static const String _ttsPitchKey = 'pref_tts_pitch';
  static const String _ttsVolumeKey = 'pref_tts_volume';
  static const String _recognitionThresholdKey = 'pref_recognition_threshold';
  static const String _historyThresholdKey =
      'pref_history_confidence_threshold';
  static const String _frameStrideKey = 'pref_frame_stride';

  final ThemeMode themeMode;
  final double textScale;
  final bool highContrast;
  final bool reduceMotion;
  final bool hapticsEnabled;
  final bool autoSpeakSigns;
  final double ttsRate;
  final double ttsPitch;
  final double ttsVolume;
  final double recognitionThreshold;
  final double historyConfidenceThreshold;
  final int frameStride;

  AppUiPreferences copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? highContrast,
    bool? reduceMotion,
    bool? hapticsEnabled,
    bool? autoSpeakSigns,
    double? ttsRate,
    double? ttsPitch,
    double? ttsVolume,
    double? recognitionThreshold,
    double? historyConfidenceThreshold,
    int? frameStride,
  }) {
    return AppUiPreferences(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoSpeakSigns: autoSpeakSigns ?? this.autoSpeakSigns,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      recognitionThreshold: recognitionThreshold ?? this.recognitionThreshold,
      historyConfidenceThreshold:
          historyConfidenceThreshold ?? this.historyConfidenceThreshold,
      frameStride: frameStride ?? this.frameStride,
    );
  }

  factory AppUiPreferences.fromSharedPreferences(SharedPreferences prefs) {
    final String mode = prefs.getString(_themeModeKey) ?? 'system';

    ThemeMode themeMode = ThemeMode.system;
    if (mode == 'light') {
      themeMode = ThemeMode.light;
    } else if (mode == 'dark') {
      themeMode = ThemeMode.dark;
    }

    return AppUiPreferences(
      themeMode: themeMode,
      textScale: (prefs.getDouble(_textScaleKey) ?? 1.0).clamp(0.85, 1.4),
      highContrast: prefs.getBool(_highContrastKey) ?? false,
      reduceMotion: prefs.getBool(_reduceMotionKey) ?? false,
      hapticsEnabled: prefs.getBool(_hapticsKey) ?? true,
      autoSpeakSigns: prefs.getBool(_autoSpeakSignsKey) ?? false,
      ttsRate: (prefs.getDouble(_ttsRateKey) ?? 0.5).clamp(0.1, 1.0),
      ttsPitch: (prefs.getDouble(_ttsPitchKey) ?? 1.0).clamp(0.5, 2.0),
      ttsVolume: (prefs.getDouble(_ttsVolumeKey) ?? 1.0).clamp(0.0, 1.0),
      recognitionThreshold: (prefs.getDouble(_recognitionThresholdKey) ?? 35.0)
          .clamp(10, 95),
      historyConfidenceThreshold:
          (prefs.getDouble(_historyThresholdKey) ?? 60.0).clamp(35, 99),
      frameStride: (prefs.getInt(_frameStrideKey) ?? 2).clamp(1, 5),
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    String mode = 'system';
    if (themeMode == ThemeMode.light) {
      mode = 'light';
    } else if (themeMode == ThemeMode.dark) {
      mode = 'dark';
    }

    await prefs.setString(_themeModeKey, mode);
    await prefs.setDouble(_textScaleKey, textScale);
    await prefs.setBool(_highContrastKey, highContrast);
    await prefs.setBool(_reduceMotionKey, reduceMotion);
    await prefs.setBool(_hapticsKey, hapticsEnabled);
    await prefs.setBool(_autoSpeakSignsKey, autoSpeakSigns);
    await prefs.setDouble(_ttsRateKey, ttsRate);
    await prefs.setDouble(_ttsPitchKey, ttsPitch);
    await prefs.setDouble(_ttsVolumeKey, ttsVolume);
    await prefs.setDouble(_recognitionThresholdKey, recognitionThreshold);
    await prefs.setDouble(_historyThresholdKey, historyConfidenceThreshold);
    await prefs.setInt(_frameStrideKey, frameStride);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppUiPreferences _prefs = const AppUiPreferences();
  bool _ready = false;

  static const Color _seedColor = Color(0xFF0A7A75);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _prefs = AppUiPreferences.fromSharedPreferences(prefs);
      _ready = true;
    });
  }

  Future<void> _updatePreferences(AppUiPreferences next) async {
    setState(() => _prefs = next);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await next.save(prefs);
  }

  ThemeData _buildTheme(Brightness brightness) {
    ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    scheme = scheme.copyWith(
      primary: brightness == Brightness.dark
          ? const Color(0xFF6AF6ED)
          : const Color(0xFF006F69),
      onPrimary: brightness == Brightness.dark
          ? const Color(0xFF003534)
          : Colors.white,
      primaryContainer: brightness == Brightness.dark
          ? const Color(0xFF1C5D63)
          : const Color(0xFFA7F0EB),
      onPrimaryContainer: brightness == Brightness.dark
          ? const Color(0xFFE6FFFF)
          : const Color(0xFF003735),
      surface: brightness == Brightness.dark
          ? const Color(0xFF101A1F)
          : const Color(0xFFF8FBFC),
      onSurface: brightness == Brightness.dark
          ? const Color(0xFFF5FDFF)
          : const Color(0xFF0E2325),
      surfaceContainer: brightness == Brightness.dark
          ? const Color(0xFF1B2A31)
          : const Color(0xFFEAF4F6),
      surfaceContainerHighest: brightness == Brightness.dark
          ? const Color(0xFF263942)
          : const Color(0xFFDDECEF),
      onSurfaceVariant: brightness == Brightness.dark
          ? const Color(0xFFE1EDF0)
          : const Color(0xFF315258),
      outline: brightness == Brightness.dark
          ? const Color(0xFF9DB8BE)
          : const Color(0xFF5B7B81),
      outlineVariant: brightness == Brightness.dark
          ? const Color(0xFF4C6871)
          : const Color(0xFFB1C7CB),
    );

    if (_prefs.highContrast) {
      scheme = scheme.copyWith(
        primary: brightness == Brightness.dark
            ? const Color(0xFF64FFF6)
            : const Color(0xFF005A56),
        onPrimary: brightness == Brightness.dark
            ? const Color(0xFF002221)
            : Colors.white,
        surface: brightness == Brightness.dark
            ? const Color(0xFF0C1216)
            : Colors.white,
        onSurface: brightness == Brightness.dark ? Colors.white : Colors.black,
      );
    }

    final TextTheme appTextTheme = GoogleFonts.manropeTextTheme(
      ThemeData(useMaterial3: true, brightness: brightness).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    // Minimalistic, high-contrast theme: cleaner surfaces, larger tappables,
    // subtle rounded corners, and reduced chrome to avoid a technical look.
    final Color primary = brightness == Brightness.dark
        ? const Color(0xFF6AF6ED)
        : const Color(0xFF006F69);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: brightness),
      textTheme: appTextTheme,
      scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xFF0B0B0C) : Colors.white,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: brightness == Brightness.dark ? Colors.white : Colors.black,
        titleTextStyle: appTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        toolbarHeight: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.dark ? const Color(0xFF0F1112) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: appTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      iconTheme: IconThemeData(color: brightness == Brightness.dark ? Colors.white : Colors.black, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? const Color(0xFF121315) : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartBridge',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _prefs.themeMode,
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(_prefs.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _ready
          ? AppEntryGate(
              prefs: _prefs,
              onPreferencesChanged: _updatePreferences,
            )
          : const _LoadingScaffold(label: 'Loading SmartBridge...'),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({
    super.key,
    required this.prefs,
    required this.onPreferencesChanged,
  });

  final AppUiPreferences prefs;
  final ValueChanged<AppUiPreferences> onPreferencesChanged;

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _gateReady = false;
  bool _hasSeenOnboarding = false;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _loadGateState();
  }

  Future<void> _loadGateState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _hasSeenOnboarding = prefs.getBool(_onboardingSeenKey) ?? false;
      _acceptedTerms = prefs.getBool(_termsAcceptedKey) ?? false;
      _gateReady = true;
    });
  }

  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
    await prefs.setBool(_termsAcceptedKey, true);

    if (!mounted) return;
    setState(() {
      _hasSeenOnboarding = true;
      _acceptedTerms = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_gateReady) {
      return const _LoadingScaffold(label: 'Preparing your workspace...');
    }

    if (!_hasSeenOnboarding || !_acceptedTerms) {
      return OnboardingFlow(onAccepted: _completeOnboarding);
    }

    return SmartBridgeShell(
      prefs: widget.prefs,
      onPreferencesChanged: widget.onPreferencesChanged,
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 14),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.onAccepted});

  final Future<void> Function() onAccepted;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  static const int _slideCount = 5;
  int _page = 0;
  bool _agreed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _slideCount - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (!_agreed || _submitting) return;

    setState(() => _submitting = true);
    await widget.onAccepted();
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  Future<void> _back() async {
    if (_page == 0) return;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToTerms() async {
    if (_page >= _slideCount - 1) {
      return;
    }

    await _pageController.animateToPage(
      _slideCount - 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  Widget _buildBullet(ColorScheme scheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required String title,
    required String body,
    required String kicker,
    Widget? footer,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primaryContainer,
                          scheme.surfaceContainerHighest,
                        ],
                      ),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 30,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: scheme.primaryContainer.withValues(alpha: 0.55),
                    ),
                    child: Text(
                      kicker,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  if (footer != null) ...[const SizedBox(height: 20), footer],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTutorialFooter(ColorScheme scheme) {
    final List<String> supportedGestures = <String>[
      'Open Palm',
      'Closed Fist',
      'Pointing Up',
      'Thumb Up',
      'Thumb Down',
      'Victory',
      'I Love You',
      'None',
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.78),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.asset(
              'assets/tutorial/hand_signs_guide.png',
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recognized gestures',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: supportedGestures
                      .map((String gesture) => Chip(label: Text(gesture)))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tip: Start with Open Palm, Closed Fist, and Victory for best consistency.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'If prediction flickers, move to better lighting and keep only one hand in frame.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsFooter(ColorScheme scheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.78),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBullet(
                  scheme,
                  'Accuracy is not guaranteed. Always verify critical meaning with a qualified interpreter.',
                ),
                _buildBullet(
                  scheme,
                  'Do not rely on this app alone for medical, legal, emergency, or high-risk decisions.',
                ),
                _buildBullet(
                  scheme,
                  'Camera and microphone data are used only to run translation features while you are using them.',
                ),
                _buildBullet(
                  scheme,
                  'Use in safe environments. Never operate while driving, crossing roads, or in hazardous settings.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: scheme.secondaryContainer.withValues(alpha: 0.28),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data and reliability summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _buildBullet(
                  scheme,
                  'Recognition confidence can vary with lighting, camera angle, and hand visibility.',
                ),
                _buildBullet(
                  scheme,
                  'No cloud upload is required for basic translation flow; permissions can be revoked in Settings.',
                ),
                _buildBullet(
                  scheme,
                  'You remain responsible for verifying critical communication outcomes.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I agree to the Terms and Conditions'),
            subtitle: const Text(
              'You can review this notice again later in the About page.',
            ),
            value: _agreed,
            onChanged: (bool? value) {
              setState(() => _agreed = value ?? false);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double progress = (_page + 1) / _slideCount;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -70,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer.withValues(alpha: 0.48),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.tertiaryContainer.withValues(alpha: 0.35),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.44),
                  scheme.surface,
                  scheme.surface,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Card(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    SmartBridgeLogo(
                                      size: 46,
                                      backgroundColor: scheme.surface,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SmartBridge Setup',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                          Text(
                                            'Step ${_page + 1} of $_slideCount',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 8,
                                    value: progress,
                                    backgroundColor:
                                        scheme.surfaceContainerHighest,
                                  ),
                                ),
                                if (_page < _slideCount - 1) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: _skipToTerms,
                                      icon: const Icon(
                                        Icons.fast_forward_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Skip to Terms'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (int value) =>
                                  setState(() => _page = value),
                              children: [
                                _buildSlide(
                                  icon: Icons.waving_hand_rounded,
                                  kicker: 'Welcome',
                                  title:
                                      'Your communication bridge starts here',
                                  body:
                                      'SmartBridge helps you turn hand gestures, speech, and text into faster two-way communication.',
                                  footer: Align(
                                    alignment: Alignment.topLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: const [
                                        Chip(label: Text('Camera recognition')),
                                        Chip(label: Text('Speech-to-text')),
                                        Chip(label: Text('Text-to-speech')),
                                        Chip(
                                          label: Text('Accessibility controls'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _buildSlide(
                                  icon: Icons.hub_outlined,
                                  kicker: 'Workflow',
                                  title: 'Translate in three quick steps',
                                  body:
                                      '1) Keep your hand centered. 2) Hold the gesture steady for a moment. 3) Review confidence and optional voice output.',
                                  footer: Align(
                                    alignment: Alignment.topLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildBullet(
                                          scheme,
                                          'Best performance in bright, even lighting.',
                                        ),
                                        _buildBullet(
                                          scheme,
                                          'Use one visible hand at a time for clearer results.',
                                        ),
                                        _buildBullet(
                                          scheme,
                                          'Keep 40–80 cm distance from the camera.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _buildSlide(
                                  icon: Icons.image_search_outlined,
                                  kicker: 'Tutorial',
                                  title: 'Sample hand-sign guide',
                                  body:
                                      'Use this quick visual reference to practice supported gestures before running live recognition.',
                                  footer: _buildTutorialFooter(scheme),
                                ),
                                _buildSlide(
                                  icon: Icons.accessibility_new,
                                  kicker: 'Accessibility',
                                  title: 'Adapt SmartBridge to your comfort',
                                  body:
                                      'Tune text size, contrast, haptics, motion, and voice behavior anytime from Settings.',
                                  footer: Align(
                                    alignment: Alignment.topLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildBullet(
                                          scheme,
                                          'High contrast mode for stronger readability.',
                                        ),
                                        _buildBullet(
                                          scheme,
                                          'Reduced motion if you are sensitive to animation.',
                                        ),
                                        _buildBullet(
                                          scheme,
                                          'Voice speed, pitch, and volume controls.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _buildSlide(
                                  icon: Icons.gavel_rounded,
                                  kicker: 'Agreement',
                                  title: 'Terms and Conditions',
                                  body:
                                      'Please review these usage conditions carefully before entering the app.',
                                  footer: _buildTermsFooter(scheme),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                for (int i = 0; i < _slideCount; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.only(right: 6),
                                    width: i == _page ? 22 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: i == _page
                                          ? scheme.primary
                                          : scheme.outlineVariant.withValues(
                                              alpha: 0.5,
                                            ),
                                    ),
                                  ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _page == 0 ? null : _back,
                                  child: const Text('Back'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed:
                                      (_page == _slideCount - 1 && !_agreed) ||
                                          _submitting
                                      ? null
                                      : _next,
                                  child: Text(
                                    _page == _slideCount - 1
                                        ? (_submitting
                                              ? 'Entering...'
                                              : 'Enter App')
                                        : 'Next',
                                  ),
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
        ],
      ),
    );
  }
}

class SmartBridgeShell extends StatefulWidget {
  const SmartBridgeShell({
    super.key,
    required this.prefs,
    required this.onPreferencesChanged,
  });

  final AppUiPreferences prefs;
  final ValueChanged<AppUiPreferences> onPreferencesChanged;

  @override
  State<SmartBridgeShell> createState() => _SmartBridgeShellState();
}

class _SmartBridgeShellState extends State<SmartBridgeShell> {
  static const double _maxContentWidth = 940;

  final PageController _pageController = PageController();
  final List<HistoryItem> _history = <HistoryItem>[];

  int _currentIndex = 0;

  static const List<String> _titles = [
    'Translate',
    'History',
    'Settings',
    'About',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onAddHistory(HistoryItem item) {
    setState(() => _history.add(item));
  }

  void _onClearHistory() {
    setState(() => _history.clear());
  }

  ThemeMode _nextThemeMode(ThemeMode current) {
    switch (current) {
      case ThemeMode.system:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
    }
  }

  IconData _themeIconForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  String _themeTooltipForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Theme: System (tap to set Light)';
      case ThemeMode.light:
        return 'Theme: Light (tap to set Dark)';
      case ThemeMode.dark:
        return 'Theme: Dark (tap to set System)';
    }
  }

  Future<void> _goToPage(int index) async {
    if (index == _currentIndex) {
      return;
    }

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final List<Widget> pages = [
      TranslatorPage(prefs: widget.prefs, onAddHistory: _onAddHistory),
      HistoryPage(history: _history, onClearHistory: _onClearHistory),
      SettingsPage(
        prefs: widget.prefs,
        onPreferencesChanged: widget.onPreferencesChanged,
        onClearHistory: _onClearHistory,
      ),
      const AboutPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SmartBridgeLogo(
              size: 34,
              backgroundColor: scheme.surface,
              borderColor: scheme.outlineVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SmartBridge',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    _titles[_currentIndex],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _themeTooltipForMode(widget.prefs.themeMode),
            icon: Icon(_themeIconForMode(widget.prefs.themeMode)),
            onPressed: () {
              final ThemeMode next = _nextThemeMode(widget.prefs.themeMode);
              widget.onPreferencesChanged(
                widget.prefs.copyWith(themeMode: next),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.18),
              scheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Swipe left or right to switch pages quickly.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(
                  parent: PageScrollPhysics(),
                ),
                allowImplicitScrolling: true,
                onPageChanged: (int value) {
                  setState(() => _currentIndex = value);
                },
                children: pages
                    .map(
                      (Widget page) => Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxContentWidth,
                          ),
                          child: page,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sign_language_outlined),
            selectedIcon: Icon(Icons.sign_language),
            label: 'Translate',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({
    super.key,
    required this.prefs,
    required this.onAddHistory,
  });

  final AppUiPreferences prefs;
  final ValueChanged<HistoryItem> onAddHistory;

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final CameraService _cameraService = CameraService();
  final ModelService _modelService = ModelService();

  late final AnimationController _listeningController;
  late final AnimationController _speakingController;
  final TextEditingController _ttsController = TextEditingController();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _permissionsGranted = false;
  bool _isCameraInitialized = false;
  bool _isCameraRunning = false;
  bool _isModelLoaded = false;
  bool _isFallbackMode = false;
  bool _isProcessingFrame = false;

  int _selectedCameraIndex = 0;
  int _frameCounter = 0;

  String _recognizedText = '';
  String _speechText = '';
  String _initializationError = '';

  List<SignPrediction> _topPredictions = <SignPrediction>[];

  bool get _motionEnabled => !widget.prefs.reduceMotion;

  @override
  void initState() {
    super.initState();
    _listeningController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );
    _speakingController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _configureTtsCallbacks();
    _applyVoiceSettings();
    _initializeServices();
  }

  @override
  void didUpdateWidget(covariant TranslatorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool voicePrefsChanged =
        oldWidget.prefs.ttsRate != widget.prefs.ttsRate ||
        oldWidget.prefs.ttsPitch != widget.prefs.ttsPitch ||
        oldWidget.prefs.ttsVolume != widget.prefs.ttsVolume;

    if (voicePrefsChanged) {
      _applyVoiceSettings();
    }

    if (!_motionEnabled) {
      _listeningController.stop();
      _speakingController.stop();
    }
  }

  Future<void> _applyVoiceSettings() async {
    await _tts.setSpeechRate(widget.prefs.ttsRate);
    await _tts.setPitch(widget.prefs.ttsPitch);
    await _tts.setVolume(widget.prefs.ttsVolume);
  }

  void _configureTtsCallbacks() {
    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = true);
      if (_motionEnabled) {
        _speakingController.repeat(reverse: true);
      }
    });

    void onDone() {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
      _speakingController.stop();
      _speakingController.reset();
    }

    _tts.setCompletionHandler(onDone);
    _tts.setCancelHandler(onDone);
    _tts.setErrorHandler((message) {
      onDone();
      _showSnackBar('TTS error: ${message.toString()}');
    });
  }

  Future<void> _initializeServices() async {
    setState(() {
      _initializationError = '';
      _isFallbackMode = false;
    });

    try {
      final bool granted = await PermissionHandler.requestAllPermissions();
      if (!mounted) return;

      setState(() => _permissionsGranted = granted);
      if (!granted) {
        setState(() {
          _initializationError =
              'Camera and microphone permissions are needed for full mode.';
          _isFallbackMode = true;
        });
      }

      if (granted) {
        await _cameraService.initializeCamera();
        if (_cameraService.cameras.isNotEmpty) {
          await _cameraService.startCameraStream(
            cameraIndex: _selectedCameraIndex,
            frameProcessor: _processFrame,
          );

          if (!mounted) return;
          setState(() {
            _isCameraInitialized = true;
            _isCameraRunning = true;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
        _isCameraRunning = false;
        _isFallbackMode = true;
        _initializationError = 'Camera error: $e';
      });
    }

    try {
      await _modelService.loadModel();
      if (!mounted) return;
      setState(() => _isModelLoaded = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isModelLoaded = false;
        _isFallbackMode = true;
      });
      if (kDebugMode) {
        debugPrint('Model initialization failed: $e');
      }
    }

    if (!mounted) return;
    if (_isFallbackMode) {
      _showSnackBar('Running in manual fallback mode');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    _frameCounter++;
    if (_frameCounter % widget.prefs.frameStride != 0) {
      return;
    }

    if (_isProcessingFrame ||
        !_isModelLoaded ||
        !_isCameraRunning ||
        !mounted) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final int sensorOrientation =
          _cameraService.cameraController?.description.sensorOrientation ?? 0;
      final SignPrediction prediction = await _modelService.runInference(
        image,
        sensorOrientation: sensorOrientation,
      );

      final List<SignPrediction> topPredictions = _modelService
          .getTopKPredictions(prediction.rawScores, topK: 3);

      if (!mounted) return;

      if (prediction.label == 'No hand') {
        if (_topPredictions.isNotEmpty) {
          setState(() => _topPredictions = <SignPrediction>[]);
        }
        return;
      }

      final bool shouldUpdateRecognized =
          prediction.label != 'Error' &&
          prediction.label != 'Unknown' &&
          prediction.confidence >= widget.prefs.recognitionThreshold &&
          prediction.label != _recognizedText;

      setState(() {
        _topPredictions = topPredictions;
        if (shouldUpdateRecognized) {
          _recognizedText = prediction.label;
        }
      });

      if (shouldUpdateRecognized) {
        if (widget.prefs.autoSpeakSigns) {
          await _speak(prediction.label, addToHistory: false);
        }

        if (prediction.confidence >= widget.prefs.historyConfidenceThreshold) {
          widget.onAddHistory(
            HistoryItem(
              type: 'sign',
              text: prediction.label,
              confidence: prediction.confidence.toInt(),
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Frame processing error: $e');
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _vibrateLight() {
    if (widget.prefs.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _vibrateMedium() {
    if (widget.prefs.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _toggleListening() async {
    _vibrateMedium();

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      _listeningController.stop();
      _listeningController.reset();

      if (_speechText.isNotEmpty) {
        widget.onAddHistory(
          HistoryItem(
            type: 'speech',
            text: _speechText,
            timestamp: DateTime.now(),
          ),
        );
      }
      return;
    }

    try {
      final bool available = await _speech.initialize(
        onError: (error) => _showSnackBar('Speech error: $error'),
        onStatus: (status) {
          if (status == 'notListening' && mounted) {
            setState(() => _isListening = false);
            _listeningController.stop();
          }
        },
      );

      if (!mounted) return;

      if (!available) {
        _showSnackBar('Speech recognition is not available');
        return;
      }

      setState(() => _isListening = true);
      if (_motionEnabled) {
        _listeningController.repeat(reverse: true);
      }

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _speechText = result.recognizedWords);
        },
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Speech service is unavailable in this environment');
      if (kDebugMode) {
        debugPrint('Speech init error: $e');
      }
    }
  }

  Future<void> _speak(String text, {bool addToHistory = true}) async {
    if (text.trim().isEmpty) return;

    if (_isSpeaking) {
      await _tts.stop();
      return;
    }

    _vibrateLight();
    await _tts.speak(text);

    if (addToHistory) {
      widget.onAddHistory(
        HistoryItem(type: 'tts', text: text.trim(), timestamp: DateTime.now()),
      );
    }
  }

  Future<void> _startCamera() async {
    if (_isCameraRunning) {
      _showSnackBar('Camera already running');
      return;
    }

    try {
      if (!_permissionsGranted) {
        final bool granted = await PermissionHandler.requestAllPermissions();
        if (!mounted) return;
        setState(() => _permissionsGranted = granted);
        if (!granted) {
          _showSnackBar('Permission is required for camera mode');
          return;
        }
      }

      await _cameraService.initializeCamera();
      if (_selectedCameraIndex >= _cameraService.cameras.length) {
        _selectedCameraIndex = 0;
      }

      await _cameraService.startCameraStream(
        cameraIndex: _selectedCameraIndex,
        frameProcessor: _processFrame,
      );

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _isCameraRunning = true;
        _initializationError = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
        _isCameraRunning = false;
        _initializationError = 'Unable to start camera: $e';
      });
      _showSnackBar('Unable to start camera');
    }
  }

  Future<void> _stopCamera() async {
    await _cameraService.dispose();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = false;
      _isCameraRunning = false;
      _isProcessingFrame = false;
    });
  }

  Future<void> _switchCamera() async {
    if (!_isCameraRunning || _cameraService.cameras.length < 2) {
      _showSnackBar('No additional camera available');
      return;
    }

    final int nextIndex =
        (_selectedCameraIndex + 1) % _cameraService.cameras.length;
    final bool switched = await _cameraService.switchCamera(
      cameraIndex: nextIndex,
      frameProcessor: _processFrame,
    );

    if (!mounted) return;

    if (switched) {
      setState(() => _selectedCameraIndex = nextIndex);
    } else {
      _showSnackBar('Unable to switch camera');
    }
  }

  Future<void> _captureSnapshot() async {
    if (!_isCameraRunning) {
      _showSnackBar('Start camera first');
      return;
    }

    final XFile? image = await _cameraService.captureImage();
    if (image == null) {
      _showSnackBar('Snapshot failed');
      return;
    }
    _showSnackBar('Snapshot captured');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  double _cameraAspectRatio() {
    final CameraController? controller = _cameraService.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return 4 / 3;
    }

    final double ratio = controller.value.aspectRatio;
    if (!ratio.isFinite || ratio <= 0) {
      return 4 / 3;
    }

    return ratio.clamp(0.75, 1.65);
  }

  Widget _buildMicPulse() {
    if (!_isListening || !_motionEnabled) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _listeningController,
      builder: (BuildContext context, Widget? child) {
        final double scale = 1 + (_listeningController.value * 0.14);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    final Size? previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    final double previewAspectRatio = previewSize.height / previewSize.width;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: previewAspectRatio,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildCameraCard() {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    Widget content;
    if (_initializationError.isNotEmpty) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: scheme.error),
          const SizedBox(height: 10),
          Text(
            _initializationError,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: PermissionHandler.openAppSettingsPage,
                child: const Text('Open Settings'),
              ),
              FilledButton(
                onPressed: _initializeServices,
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      );
    } else if (!_isCameraRunning) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          const SizedBox.shrink(),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _startCamera,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [Icon(Icons.play_arrow), SizedBox(width: 8), Text('Start')],
            ),
          ),
        ],
      );
    } else if (!_isCameraInitialized ||
        _cameraService.cameraController == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildCameraPreview(_cameraService.cameraController!),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                _recognizedText.isEmpty ? 'No sign detected' : _recognizedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 640;

                // Minimal control row: only essential actions
                return Row(
                  children: [
                    Icon(Icons.videocam_outlined, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    const Spacer(),
                    IconButton(
                      tooltip: _isCameraRunning ? 'Stop' : 'Start',
                      onPressed: _isCameraRunning ? _stopCamera : _startCamera,
                      icon: Icon(_isCameraRunning ? Icons.stop : Icons.play_arrow),
                    ),
                    IconButton(
                      tooltip: 'Switch',
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.cameraswitch_outlined),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double previewHeight =
                    ((constraints.maxWidth / _cameraAspectRatio()) * 1.18)
                        .clamp(290.0, 520.0);

                return Container(
                  width: double.infinity,
                  height: previewHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: content,
                );
              },
            ),
            const SizedBox(height: 10),
            if (_topPredictions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _topPredictions.map((SignPrediction prediction) {
                  return Chip(
                    label: Text(
                      '${prediction.label} (${prediction.confidence.toStringAsFixed(0)}%)',
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Chip(label: Text(_permissionsGranted ? 'Permissions: OK' : 'Permissions: Required')),
                const SizedBox(width: 8),
                Chip(label: Text(_isModelLoaded ? 'Model: Ready' : 'Model: Loading')),
                const SizedBox(width: 8),
                Chip(label: Text(_isFallbackMode ? 'Mode: Manual' : 'Mode: AI')),
                const Spacer(),
                // compact recognized text preview
                if (_recognizedText.isNotEmpty)
                  Flexible(
                    child: Text(
                      _recognizedText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _buildCameraCard(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mic_rounded),
                    const SizedBox(width: 8),
                    const Text(
                      'Speech to Text',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color:
                            (_isListening
                                    ? scheme.errorContainer
                                    : scheme.primaryContainer)
                                .withValues(alpha: 0.9),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text(
                        _isListening ? 'Listening' : 'Idle',
                        style: TextStyle(
                          color: _isListening
                              ? scheme.onErrorContainer
                              : scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final Color micBackground = _isListening
                        ? scheme.errorContainer
                        : scheme.primaryContainer;
                    final Color micForeground = _isListening
                        ? scheme.onErrorContainer
                        : scheme.onPrimaryContainer;

                    final Widget micButton = Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildMicPulse(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: micBackground,
                            border: Border.all(
                              color: micForeground.withValues(alpha: 0.22),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: micBackground.withValues(alpha: 0.38),
                                blurRadius: _isListening ? 20 : 12,
                                spreadRadius: _isListening ? 2 : 0,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _toggleListening,
                            iconSize: 34,
                            icon: Icon(
                              _isListening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: micForeground,
                            ),
                          ),
                        ),
                      ],
                    );

                    final Widget transcriptBox = Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.78,
                        ),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.subtitles_outlined,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _speechText.isEmpty
                                  ? 'Tap the microphone to start live transcription.'
                                  : _speechText,
                              style: TextStyle(
                                color: _speechText.isEmpty
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (constraints.maxWidth < 620) {
                      return Column(
                        children: [
                          Align(alignment: Alignment.center, child: micButton),
                          const SizedBox(height: 12),
                          transcriptBox,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        micButton,
                        const SizedBox(width: 14),
                        Expanded(child: transcriptBox),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Text to Speech',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ttsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Type text to speak...',
                  ),
                ),
                const SizedBox(height: 12),
                if (_isSpeaking && _motionEnabled)
                  SizedBox(
                    height: 28,
                    child: AnimatedBuilder(
                      animation: _speakingController,
                      builder: (BuildContext context, Widget? child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(3, (int index) {
                            final double v =
                                (_speakingController.value + (index * 0.2)) %
                                1.0;
                            final double h = 8 + (v * 16);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 6,
                              height: h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                color: scheme.primary,
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    final String text = _ttsController.text.isNotEmpty
                        ? _ttsController.text
                        : (_recognizedText.isNotEmpty
                              ? _recognizedText
                              : _speechText);
                    _speak(text);
                  },
                  icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                  label: Text(_isSpeaking ? 'Stop' : 'Speak'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();

    _listeningController.dispose();
    _speakingController.dispose();
    _ttsController.dispose();

    _cameraService.dispose();
    _modelService.dispose();
    super.dispose();
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.history,
    required this.onClearHistory,
  });

  final List<HistoryItem> history;
  final VoidCallback onClearHistory;

  String _formatTime(DateTime time) {
    final String hh = time.hour.toString().padLeft(2, '0');
    final String mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'sign':
        return Icons.sign_language;
      case 'speech':
        return Icons.mic;
      case 'tts':
        return Icons.volume_up;
      default:
        return Icons.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 54,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 10),
            const Text('No history yet.'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: IconButton(
              onPressed: onClearHistory,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear',
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: history.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final HistoryItem item = history[index];
              return Card(
                child: ListTile(
                  leading: Icon(_iconForType(item.type)),
                  title: Text(item.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_formatTime(item.timestamp)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.prefs,
    required this.onPreferencesChanged,
    required this.onClearHistory,
  });

  final AppUiPreferences prefs;
  final ValueChanged<AppUiPreferences> onPreferencesChanged;
  final VoidCallback onClearHistory;

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  IconData _themeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accessibility',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool compact = constraints.maxWidth < 420;
                    if (compact) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ThemeMode.values.map((ThemeMode mode) {
                          return ChoiceChip(
                            avatar: Icon(
                              _themeModeIcon(mode),
                              size: 18,
                              color: prefs.themeMode == mode
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            label: Text(_themeModeLabel(mode)),
                            selected: prefs.themeMode == mode,
                            onSelected: (_) {
                              onPreferencesChanged(
                                prefs.copyWith(themeMode: mode),
                              );
                            },
                          );
                        }).toList(),
                      );
                    }

                    return SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      multiSelectionEnabled: false,
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto),
                          label: Text('System'),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode),
                          label: Text('Light'),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: <ThemeMode>{prefs.themeMode},
                      onSelectionChanged: (Set<ThemeMode> selection) {
                        onPreferencesChanged(
                          prefs.copyWith(themeMode: selection.first),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                _LabeledSlider(
                  label: 'Text size',
                  value: prefs.textScale,
                  min: 0.85,
                  max: 1.4,
                  divisions: 11,
                  valueLabel: '${prefs.textScale.toStringAsFixed(2)}x',
                  onChanged: (double value) {
                    onPreferencesChanged(prefs.copyWith(textScale: value));
                  },
                ),
                Row(
                  children: [
                    Expanded(child: const Text('High contrast')),
                    Switch.adaptive(
                      value: prefs.highContrast,
                      onChanged: (bool value) => onPreferencesChanged(prefs.copyWith(highContrast: value)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: const Text('Reduce motion')),
                    Switch.adaptive(
                      value: prefs.reduceMotion,
                      onChanged: (bool value) => onPreferencesChanged(prefs.copyWith(reduceMotion: value)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: const Text('Haptics')),
                    Switch.adaptive(
                      value: prefs.hapticsEnabled,
                      onChanged: (bool value) => onPreferencesChanged(prefs.copyWith(hapticsEnabled: value)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recognition and Voice',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: const Text('Auto-speak')),
                    Switch.adaptive(
                      value: prefs.autoSpeakSigns,
                      onChanged: (bool value) => onPreferencesChanged(prefs.copyWith(autoSpeakSigns: value)),
                    ),
                  ],
                ),
                _LabeledSlider(
                  label: 'Recognition threshold',
                  value: prefs.recognitionThreshold,
                  min: 10,
                  max: 95,
                  divisions: 17,
                  valueLabel: '${prefs.recognitionThreshold.toStringAsFixed(0)}%',
                  onChanged: (double value) {
                    onPreferencesChanged(prefs.copyWith(recognitionThreshold: value));
                  },
                ),
                _LabeledSlider(
                  label: 'History confidence',
                  value: prefs.historyConfidenceThreshold,
                  min: 35,
                  max: 99,
                  divisions: 16,
                  valueLabel: '${prefs.historyConfidenceThreshold.toStringAsFixed(0)}%',
                  onChanged: (double value) {
                    onPreferencesChanged(prefs.copyWith(historyConfidenceThreshold: value));
                  },
                ),
                _LabeledSlider(
                  label: 'Frame stride',
                  value: prefs.frameStride.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  valueLabel: prefs.frameStride.toString(),
                  onChanged: (double value) {
                    onPreferencesChanged(
                      prefs.copyWith(frameStride: value.round()),
                    );
                  },
                ),
                _LabeledSlider(
                  label: 'Voice speed',
                  value: prefs.ttsRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  valueLabel: prefs.ttsRate.toStringAsFixed(1),
                  onChanged: (double value) {
                    onPreferencesChanged(prefs.copyWith(ttsRate: value));
                  },
                ),
                _LabeledSlider(
                  label: 'Voice pitch',
                  value: prefs.ttsPitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  valueLabel: prefs.ttsPitch.toStringAsFixed(1),
                  onChanged: (double value) {
                    onPreferencesChanged(prefs.copyWith(ttsPitch: value));
                  },
                ),
                _LabeledSlider(
                  label: 'Voice volume',
                  value: prefs.ttsVolume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  valueLabel: prefs.ttsVolume.toStringAsFixed(1),
                  onChanged: (double value) {
                    onPreferencesChanged(prefs.copyWith(ttsVolume: value));
                  },
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_applications_outlined),
                  title: const Text('Open app permissions'),
                  subtitle: const Text(
                    'Manage camera and microphone access from system settings.',
                  ),
                  onTap: PermissionHandler.openAppSettingsPage,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Clear translation history'),
                  onTap: onClearHistory,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(valueLabel),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<PackageInfo> _getPackageInfo() => PackageInfo.fromPlatform();

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _getPackageInfo(),
      builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
        final String version = snapshot.hasData
            ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
            : '1.0.0+1';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SmartBridgeLogo(size: 46),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SmartBridge',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Communication Assistant',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'A communication assistant with live camera gesture recognition, speech-to-text, and text-to-speech support.',
                    ),
                    const SizedBox(height: 12),
                    Text('Version: $version'),
                    const SizedBox(height: 4),
                    Text(
                      'Release date: April 15, 2026',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Designed for fast everyday communication support in classrooms, homes, and public spaces.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            _sectionCard(
              context: context,
              title: 'System Functions',
              children: const [
                Text('1. Real-time hand gesture detection with camera input.'),
                Text('2. Voice transcription using speech recognition.'),
                Text('3. Spoken output through text-to-speech.'),
                Text('4. Accessibility customization and motion controls.'),
                Text('5. Swipe-based page navigation for easier access.'),
                Text('6. History logging with confidence summaries.'),
                Text('7. Adjustable confidence thresholds for recognition.'),
                Text('8. Manual fallback mode when sensors are unavailable.'),
              ],
            ),
            _sectionCard(
              context: context,
              title: 'Hand-Sign Tutorial Guide',
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/tutorial/hand_signs_guide.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Practice each gesture in front of the camera. Hold your hand steady for 1-2 seconds and keep your palm within the frame center.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Supported classes: Open_Palm, Closed_Fist, Pointing_Up, Thumb_Up, Thumb_Down, Victory, ILoveYou, and None.',
                ),
                const SizedBox(height: 6),
                const Text(
                  'For better stability: use even lighting, avoid cluttered backgrounds, and position your hand around 40-80 cm from the camera.',
                ),
              ],
            ),
            _sectionCard(
              context: context,
              title: 'Permissions and Privacy',
              children: const [
                Text('• Camera access is required for gesture recognition.'),
                Text(
                  '• Microphone access is required for speech-to-text input.',
                ),
                Text('• Translation history is stored locally on your device.'),
                Text('• Review app permissions anytime in Settings.'),
              ],
            ),
            _sectionCard(
              context: context,
              title: 'Terms Notice',
              children: const [
                Text(
                  'SmartBridge provides assistive output and may not always be perfectly accurate.',
                ),
                SizedBox(height: 6),
                Text(
                  'Do not rely on this app as the only source for medical, legal, emergency, safety-critical, or financial communication decisions.',
                ),
                SizedBox(height: 6),
                Text(
                  'By using SmartBridge, you agree to use it responsibly, maintain situational awareness, and verify critical information through qualified professionals when needed.',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class HistoryItem {
  HistoryItem({
    required this.type,
    required this.text,
    required this.timestamp,
    this.confidence,
  });

  final String type;
  final String text;
  final DateTime timestamp;
  final int? confidence;
}
