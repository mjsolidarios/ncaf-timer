import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key});

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

enum TimerStatus { idle, running, paused, finished }
enum TimerMode { countdown, stopwatch }

class _TimerHomePageState extends State<TimerHomePage>
    with TickerProviderStateMixin {
  // Timer state
  TimerMode _mode = TimerMode.stopwatch;
  TimerStatus _status = TimerStatus.idle;
  Duration _elapsed = Duration.zero;
  Duration _targetDuration = const Duration(minutes: 5);
  Timer? _timer;

  // Event / contest name
  final TextEditingController _nameController =
      TextEditingController(text: 'CONTEST NAME HERE');
  bool _isEditingName = false;
  final FocusNode _nameFocusNode = FocusNode();

  // Contestant number
  int _contestantNumber = 1;

  // Duration setup controllers
  final TextEditingController _hoursController =
      TextEditingController(text: '0');
  final TextEditingController _minutesController =
      TextEditingController(text: '5');
  final TextEditingController _secondsController =
      TextEditingController(text: '0');
  final TextEditingController _millisecondsController =
      TextEditingController(text: '0');

  // Fullscreen / settings panel
  bool _isFullscreen = false;
  bool _showSettings = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        setState(() => _isEditingName = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _blinkController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _millisecondsController.dispose();
    super.dispose();
  }

  // ── Timer logic ──────────────────────────────────────────────────────────

  void _startTimer() {
    if (_mode == TimerMode.countdown) {
      final h = int.tryParse(_hoursController.text) ?? 0;
      final m = int.tryParse(_minutesController.text) ?? 0;
      final s = int.tryParse(_secondsController.text) ?? 0;
      final cs = int.tryParse(_millisecondsController.text) ?? 0;
      _targetDuration = Duration(hours: h, minutes: m, seconds: s, milliseconds: cs * 10);
      if (_targetDuration.inMilliseconds == 0) return;
    }

    setState(() {
      _status = TimerStatus.running;
      if (_mode == TimerMode.countdown && _elapsed >= _targetDuration) {
        _elapsed = Duration.zero;
      } else if (_mode == TimerMode.stopwatch && _status == TimerStatus.finished) {
         _elapsed = Duration.zero; // Unlikely, but safety measure
      }
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() {
        _elapsed += const Duration(milliseconds: 100);
        if (_mode == TimerMode.countdown && _elapsed >= _targetDuration) {
          _elapsed = _targetDuration;
          _status = TimerStatus.finished;
          t.cancel();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _status = TimerStatus.paused);
  }

  void _resumeTimer() {
    setState(() => _status = TimerStatus.running);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() {
        _elapsed += const Duration(milliseconds: 100);
        if (_mode == TimerMode.countdown && _elapsed >= _targetDuration) {
          _elapsed = _targetDuration;
          _status = TimerStatus.finished;
          t.cancel();
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _elapsed = Duration.zero;
      _status = TimerStatus.idle;
    });
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Formats the current time based on the active mode
  String _formatTimerDisplay() {
    final d = _mode == TimerMode.stopwatch
        ? _elapsed
        : (_targetDuration - _elapsed).isNegative
            ? Duration.zero
            : (_targetDuration - _elapsed);
            
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s.$centiseconds';
    return '$m:$s.$centiseconds';
  }

  Color get _timerColor {
    if (_mode == TimerMode.stopwatch) return const Color(0xFF1A1A1A); // Stopwatch never triggers urgency
    
    if (_status == TimerStatus.finished) return const Color(0xFFB71C1C);
    final remaining = _targetDuration - _elapsed;
    if (remaining.inSeconds <= 30 && _status == TimerStatus.running) {
      return const Color(0xFFB71C1C);
    }
    return const Color(0xFF1A1A1A);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-bleed background image ─────────────────────────────
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Main layout ─────────────────────────────────────────────
          SafeArea(
            child: _showSettings
                ? _buildSettingsOverlay()
                : _buildMainDisplay(size, isLandscape),
          ),

          // ── Floating action buttons ─────────────────────────────────
          if (!_showSettings) _buildFloatingButtons(),
        ],
      ),
    );
  }

  // ── Main display ─────────────────────────────────────────────────────────

  Widget _buildMainDisplay(Size size, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? size.width * 0.05 : 16,
        vertical: isLandscape ? size.height * 0.06 : 20,
      ),
      child: isLandscape ? _buildWideBody() : _buildNarrowBody(),
    );
  }

  Widget _buildWideBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top bar, Timer card, Bottom Label perfectly aligned vertically & bounded horizontally
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      _TopBar(
                        nameController: _nameController,
                        isEditingName: _isEditingName,
                        nameFocusNode: _nameFocusNode,
                        onNameTap: () => setState(() => _isEditingName = true),
                        onNameSubmit: () => setState(() => _isEditingName = false),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 8,
                        child: _TimerCard(
                          mode: _mode,
                          timeString: _formatTimerDisplay(),
                          status: _status,
                          timerColor: _timerColor,
                          pulseController: _pulseController,
                          blinkController: _blinkController,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _BottomLabel(nameController: _nameController),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Contestant panel
        Expanded(
          flex: 4,
          child: _ContestantPanel(
            number: _contestantNumber,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowBody() {
    return Column(
      children: [
        // Top bar, Timer card, Bottom Label perfectly constraint matched
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TopBar(
                        nameController: _nameController,
                        isEditingName: _isEditingName,
                        nameFocusNode: _nameFocusNode,
                        onNameTap: () => setState(() => _isEditingName = true),
                        onNameSubmit: () => setState(() => _isEditingName = false),
                      ),
                      const SizedBox(height: 16),
                      _TimerCard(
                        mode: _mode,
                        timeString: _formatTimerDisplay(),
                        status: _status,
                        timerColor: _timerColor,
                        pulseController: _pulseController,
                        blinkController: _blinkController,
                      ),
                      const SizedBox(height: 12),
                      _BottomLabel(nameController: _nameController),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Contestant panel
        Expanded(
          flex: 4,
          child: _ContestantPanel(number: _contestantNumber),
        ),
        const SizedBox(height: 90), // Reserved space for floating action buttons
      ],
    );
  }

  // ── Settings overlay ─────────────────────────────────────────────────────

  Widget _buildSettingsOverlay() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E8).withOpacity(0.97),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.settings_rounded,
                      color: Color(0xFF5C2D0A), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Timer Settings',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5C2D0A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _showSettings = false),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF5C2D0A)),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFD4C4A8)),

              // Mode Toggle
              Text(
                'Timer Mode',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFF9C5000),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<TimerMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: TimerMode.stopwatch,
                      icon: Icon(Icons.timer_outlined),
                      label: Text('Stopwatch')),
                  ButtonSegment(
                      value: TimerMode.countdown,
                      icon: Icon(Icons.timer_rounded),
                      label: Text('Countdown')),
                ],
                selected: {_mode},
                onSelectionChanged: (Set<TimerMode> newSelection) {
                  setState(() {
                    _mode = newSelection.first;
                    _resetTimer();
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: const Color(0xFF406E51),
                ),
              ),
              const SizedBox(height: 24),

              // Contest Name
              Text(
                'Contest Name',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFF9C5000),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4C4A8)),
                ),
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  minLines: 1,
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C2D0A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter contest name',
                    hintStyle: TextStyle(
                      color: const Color(0xFF5C2D0A).withOpacity(0.3),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),

              // Duration
              if (_mode == TimerMode.countdown) ...[
                Text(
                  'Duration',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: const Color(0xFF9C5000),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SettingsField(
                      controller: _hoursController,
                      label: 'HRS',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(':',
                          style: GoogleFonts.notoSerif(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5C2D0A))),
                    ),
                    _SettingsField(
                      controller: _minutesController,
                      label: 'MIN',
                      max: 59,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(':',
                          style: GoogleFonts.notoSerif(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5C2D0A))),
                    ),
                    _SettingsField(
                      controller: _secondsController,
                      label: 'SEC',
                      max: 59,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('.',
                          style: GoogleFonts.notoSerif(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5C2D0A))),
                    ),
                    _SettingsField(
                      controller: _millisecondsController,
                      label: 'CS',
                      max: 99,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Contestant number
              Text(
                'Contestant Number',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFF9C5000),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ContestantStepper(
                    value: _contestantNumber,
                    onDecrement: () => setState(() {
                      if (_contestantNumber > 1) _contestantNumber--;
                    }),
                    onIncrement: () => setState(() => _contestantNumber++),
                    onChanged: (v) => setState(() => _contestantNumber = v),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildSettingsBtn(
                      label: 'Reset',
                      icon: Icons.refresh_rounded,
                      color: cs.error,
                      onTap: () {
                        _resetTimer();
                        setState(() => _showSettings = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildSettingsBtn(
                      label: _status == TimerStatus.idle
                          ? 'Start Timer'
                          : _status == TimerStatus.running
                              ? 'Pause Timer'
                              : _status == TimerStatus.paused
                                  ? 'Resume Timer'
                                  : 'Restart',
                      icon: _status == TimerStatus.running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: const Color(0xFF406E51),
                      onTap: () {
                        if (_status == TimerStatus.idle ||
                            _status == TimerStatus.finished) {
                          _startTimer();
                        } else if (_status == TimerStatus.running) {
                          _pauseTimer();
                        } else {
                          _resumeTimer();
                        }
                        setState(() => _showSettings = false);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSettingsBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Floating control buttons ──────────────────────────────────────────────

  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Settings
          _FloatingBtn(
            icon: Icons.settings_rounded,
            tooltip: 'Settings',
            onTap: () => setState(() => _showSettings = true),
          ),
          const SizedBox(height: 8),
          // Play / Pause / Resume
          if (_status == TimerStatus.idle || _status == TimerStatus.finished)
            _FloatingBtn(
              icon: Icons.play_arrow_rounded,
              tooltip: 'Start',
              color: const Color(0xFF406E51),
              onTap: _startTimer,
              large: true,
            )
          else if (_status == TimerStatus.running)
            _FloatingBtn(
              icon: Icons.pause_rounded,
              tooltip: 'Pause',
              color: const Color(0xFF9C5000),
              onTap: _pauseTimer,
              large: true,
            )
          else
            _FloatingBtn(
              icon: Icons.play_arrow_rounded,
              tooltip: 'Resume',
              color: const Color(0xFF406E51),
              onTap: _resumeTimer,
              large: true,
            ),
          if (_status != TimerStatus.idle) ...[
            const SizedBox(height: 8),
            _FloatingBtn(
              icon: Icons.refresh_rounded,
              tooltip: 'Reset',
              onTap: _resetTimer,
            ),
          ],
          const SizedBox(height: 8),
          _FloatingBtn(
            icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
            onTap: _toggleFullscreen,
          ),
        ],
      ),
    );
  }
}

// ─── Floating Button ──────────────────────────────────────────────────────────

class _FloatingBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  final bool large;

  const _FloatingBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = const Color(0xFF5C3D1A),
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 56.0 : 44.0;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: large ? 28 : 22),
        ),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController nameController;
  final bool isEditingName;
  final FocusNode nameFocusNode;
  final VoidCallback onNameTap;
  final VoidCallback onNameSubmit;

  const _TopBar({
    required this.nameController,
    required this.isEditingName,
    required this.nameFocusNode,
    required this.onNameTap,
    required this.onNameSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return isEditingName
        ? TextField(
            controller: nameController,
            focusNode: nameFocusNode,
            autofocus: true,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.notoSerif(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5C2D0A),
              letterSpacing: 1.5,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.7),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                onPressed: onNameSubmit,
                icon: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF406E51)),
              ),
            ),
            onSubmitted: (_) => onNameSubmit(),
          )
        : GestureDetector(
            onTap: onNameTap,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                nameController.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF5C2D0A),
                  letterSpacing: 2.0,
                  height: 1.15,
                ),
              ),
            ),
          );
  }
}

// ─── Timer Card ───────────────────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final TimerMode mode;
  final String timeString;
  final TimerStatus status;
  final Color timerColor;
  final AnimationController pulseController;
  final AnimationController blinkController;

  const _TimerCard({
    required this.mode,
    required this.timeString,
    required this.status,
    required this.timerColor,
    required this.pulseController,
    required this.blinkController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseController, blinkController]),
      builder: (context, _) {
        // Blink effect when paused
        final opacity = status == TimerStatus.paused
            ? 0.4 + blinkController.value * 0.6
            : 1.0;

        // Subtle scale pulse when running
        final scale = status == TimerStatus.running
            ? 1.0 + pulseController.value * 0.008
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                if (status == TimerStatus.running)
                  BoxShadow(
                    color: const Color(0xFF9C5000).withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                if (status == TimerStatus.finished)
                  BoxShadow(
                    color: const Color(0xFFB71C1C).withOpacity(0.25),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
              ],
            ),
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: mode == TimerMode.stopwatch
                                ? const Color(0xFF406E51).withOpacity(0.12)
                                : const Color(0xFF9C5000).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mode == TimerMode.stopwatch ? Icons.timer_outlined : Icons.timer_rounded,
                                size: 20,
                                color: mode == TimerMode.stopwatch ? const Color(0xFF406E51) : const Color(0xFF9C5000),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                mode == TimerMode.stopwatch ? 'STOPWATCH' : 'COUNTDOWN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: mode == TimerMode.stopwatch ? const Color(0xFF406E51) : const Color(0xFF9C5000),
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeString,
                          style: GoogleFonts.inter(
                            fontSize: 140,
                            fontWeight: FontWeight.w600,
                            color: timerColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            letterSpacing: -2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Contestant Panel ─────────────────────────────────────────────────────────

class _ContestantPanel extends StatelessWidget {
  final int number;

  const _ContestantPanel({required this.number});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CONTESTANT',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF406E51),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              number.toString().padLeft(2, '0'),
              style: GoogleFonts.inter(
                fontSize: 240,
                height: 1.0, // Removes extra vertical padding from font
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5C2D0A),
                letterSpacing: -4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Label ─────────────────────────────────────────────────────────────

class _BottomLabel extends StatelessWidget {
  final TextEditingController nameController;

  const _BottomLabel({required this.nameController});

  @override
  Widget build(BuildContext context) {
    return Text(
      nameController.text.replaceAll('\n', ' '),
      textAlign: TextAlign.center,
      style: GoogleFonts.notoSerif(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF5C2D0A),
        letterSpacing: 2,
      ),
    );
  }
}

// ─── Settings Field ───────────────────────────────────────────────────────────

class _SettingsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int? max;

  const _SettingsField({
    required this.controller,
    required this.label,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4C4A8)),
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                if (max != null) _MaxValueFormatter(max!),
              ],
              style: GoogleFonts.notoSerif(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5C2D0A),
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: const Color(0xFF5C2D0A).withOpacity(0.3),
                  fontSize: 28,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: const Color(0xFF9C5000),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contestant Stepper ───────────────────────────────────────────────────────

class _ContestantStepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<int> onChanged;

  const _ContestantStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          _StepBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4C4A8)),
              ),
              child: Text(
                value.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C2D0A),
                ),
              ),
            ),
          ),
          _StepBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF5C2D0A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// ─── Max-value formatter ──────────────────────────────────────────────────────

class _MaxValueFormatter extends TextInputFormatter {
  final int max;
  _MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final val = int.tryParse(newValue.text) ?? 0;
    if (val > max) {
      return TextEditingValue(
        text: max.toString(),
        selection: TextSelection.collapsed(offset: max.toString().length),
      );
    }
    return newValue;
  }
}
