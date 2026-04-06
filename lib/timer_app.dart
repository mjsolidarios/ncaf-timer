import 'dart:async';
import 'dart:math' as math;
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

class _TimerHomePageState extends State<TimerHomePage>
    with TickerProviderStateMixin {
  // Timer state
  TimerStatus _status = TimerStatus.idle;
  Duration _elapsed = Duration.zero;
  Duration _targetDuration = const Duration(hours: 1);
  Timer? _timer;

  // Editable event name
  final TextEditingController _nameController =
      TextEditingController(text: 'NCAF 2026 — National Culture & Arts Festival');
  bool _isEditingName = false;
  final FocusNode _nameFocusNode = FocusNode();

  // Duration setup controllers
  final TextEditingController _hoursController = TextEditingController(text: '1');
  final TextEditingController _minutesController = TextEditingController(text: '0');
  final TextEditingController _secondsController = TextEditingController(text: '0');

  // Fullscreen state
  bool _isFullscreen = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

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
    _waveController.dispose();
    _orbController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  // Timer logic
  void _startTimer() {
    final h = int.tryParse(_hoursController.text) ?? 0;
    final m = int.tryParse(_minutesController.text) ?? 0;
    final s = int.tryParse(_secondsController.text) ?? 0;
    _targetDuration = Duration(hours: h, minutes: m, seconds: s);

    if (_targetDuration.inSeconds == 0) return;

    setState(() {
      _status = TimerStatus.running;
      if (_elapsed >= _targetDuration) _elapsed = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
        if (_elapsed >= _targetDuration) {
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
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
        if (_elapsed >= _targetDuration) {
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

  // Helpers
  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  double get _progress {
    if (_targetDuration.inSeconds == 0) return 0;
    return (_elapsed.inSeconds / _targetDuration.inSeconds).clamp(0.0, 1.0);
  }

  Color get _statusColor {
    final cs = Theme.of(context).colorScheme;
    switch (_status) {
      case TimerStatus.idle:
        return cs.primary;
      case TimerStatus.running:
        return cs.secondary;
      case TimerStatus.paused:
        return cs.tertiary;
      case TimerStatus.finished:
        return cs.error;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case TimerStatus.idle:
        return 'Ready';
      case TimerStatus.running:
        return 'Running';
      case TimerStatus.paused:
        return 'Paused';
      case TimerStatus.finished:
        return 'Finished';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 700;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Animated background orbs
          _BackgroundOrbs(
            waveController: _waveController,
            orbController: _orbController,
            colorScheme: cs,
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: 24,
              ),
              child: Column(
                children: [
                  // Top bar
                  _TopBar(
                    isFullscreen: _isFullscreen,
                    onToggleFullscreen: _toggleFullscreen,
                    colorScheme: cs,
                    textTheme: tt,
                  ),
                  const SizedBox(height: 32),

                  // Event name header
                  _EventNameHeader(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    isEditing: _isEditingName,
                    onTap: () => setState(() => _isEditingName = true),
                    onSubmit: () => setState(() => _isEditingName = false),
                    colorScheme: cs,
                    textTheme: tt,
                    isWide: isWide,
                  ),
                  const SizedBox(height: 48),

                  // Timer display
                  _TimerDisplay(
                    elapsed: _elapsed,
                    targetDuration: _targetDuration,
                    progress: _progress,
                    status: _status,
                    statusLabel: _statusLabel,
                    statusColor: _statusColor,
                    pulseController: _pulseController,
                    formatDuration: _formatDuration,
                    colorScheme: cs,
                    textTheme: tt,
                    isWide: isWide,
                  ),
                  const SizedBox(height: 40),

                  // Duration setup (shown only when idle)
                  if (_status == TimerStatus.idle) ...[
                    _DurationSetup(
                      hoursController: _hoursController,
                      minutesController: _minutesController,
                      secondsController: _secondsController,
                      colorScheme: cs,
                      textTheme: tt,
                      isWide: isWide,
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Controls
                  _TimerControls(
                    status: _status,
                    onStart: _startTimer,
                    onPause: _pauseTimer,
                    onResume: _resumeTimer,
                    onReset: _resetTimer,
                    colorScheme: cs,
                    textTheme: tt,
                    isWide: isWide,
                  ),
                  const SizedBox(height: 48),

                  // Footer swoosh decoration
                  _FooterDecoration(colorScheme: cs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background Orbs ─────────────────────────────────────────────────────────

class _BackgroundOrbs extends StatelessWidget {
  final AnimationController waveController;
  final AnimationController orbController;
  final ColorScheme colorScheme;

  const _BackgroundOrbs({
    required this.waveController,
    required this.orbController,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([waveController, orbController]),
      builder: (context, _) {
        final wave = waveController.value;
        final orb = orbController.value;
        return CustomPaint(
          painter: _OrbPainter(
            wave: wave,
            orb: orb,
            primary: colorScheme.primary,
            secondary: colorScheme.secondary,
            tertiary: colorScheme.tertiary,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double wave;
  final double orb;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  _OrbPainter({
    required this.wave,
    required this.orb,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    void drawOrb(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..blendMode = BlendMode.multiply;
      canvas.drawCircle(center, radius, paint);
    }

    final t = orb * 2 * math.pi;
    final w = wave * 2 * math.pi;

    drawOrb(
      Offset(
        size.width * 0.15 + math.sin(t) * size.width * 0.05,
        size.height * 0.2 + math.cos(t * 0.7) * size.height * 0.04,
      ),
      size.width * 0.35,
      primary,
    );

    drawOrb(
      Offset(
        size.width * 0.82 + math.cos(t * 0.8) * size.width * 0.04,
        size.height * 0.35 + math.sin(t * 0.9) * size.height * 0.05,
      ),
      size.width * 0.3,
      secondary,
    );

    drawOrb(
      Offset(
        size.width * 0.5 + math.sin(w * 0.6) * size.width * 0.06,
        size.height * 0.78 + math.cos(w * 0.5) * size.height * 0.03,
      ),
      size.width * 0.28,
      tertiary,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => true;
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _TopBar({
    required this.isFullscreen,
    required this.onToggleFullscreen,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Logo / brand chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'NCAF',
                  style: GoogleFonts.notoSerif(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '2026',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Fullscreen toggle
              Tooltip(
                message: isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
                child: IconButton(
                  onPressed: onToggleFullscreen,
                  icon: Icon(
                    isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        colorScheme.surfaceContainerLow.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Event Name Header ───────────────────────────────────────────────────────

class _EventNameHeader extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final VoidCallback onTap;
  final VoidCallback onSubmit;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isWide;

  const _EventNameHeader({
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.onTap,
    required this.onSubmit,
    required this.colorScheme,
    required this.textTheme,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isEditing)
          TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textAlign: TextAlign.center,
            style: (isWide ? textTheme.headlineLarge : textTheme.headlineMedium)
                ?.copyWith(
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'Enter event name…',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
              suffixIcon: IconButton(
                onPressed: onSubmit,
                icon: const Icon(Icons.check_circle_outline),
                color: colorScheme.primary,
              ),
            ),
            onSubmitted: (_) => onSubmit(),
            maxLines: 2,
          )
        else
          GestureDetector(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                      colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    controller.text,
                    textAlign: TextAlign.center,
                    style:
                        (isWide ? textTheme.headlineLarge : textTheme.headlineMedium)
                            ?.copyWith(
                      color: Colors.white,
                      letterSpacing: isWide ? 1.5 : 0.8,
                      height: 1.3,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ─── Timer Display ───────────────────────────────────────────────────────────

class _TimerDisplay extends StatelessWidget {
  final Duration elapsed;
  final Duration targetDuration;
  final double progress;
  final TimerStatus status;
  final String statusLabel;
  final Color statusColor;
  final AnimationController pulseController;
  final String Function(Duration) formatDuration;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isWide;

  const _TimerDisplay({
    required this.elapsed,
    required this.targetDuration,
    required this.progress,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.pulseController,
    required this.formatDuration,
    required this.colorScheme,
    required this.textTheme,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = targetDuration - elapsed;
    final ringSize = isWide ? 280.0 : 220.0;
    final clockFontSize = isWide ? 56.0 : 40.0;

    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final pulse = status == TimerStatus.running
            ? 1.0 + pulseController.value * 0.015
            : 1.0;

        return Center(
          child: Transform.scale(
            scale: pulse,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient glow
                Container(
                  width: ringSize + 40,
                  height: ringSize + 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.12),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Progress ring
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: progress,
                      status: status,
                      color: statusColor,
                      trackColor: colorScheme.surfaceContainerHigh,
                    ),
                  ),
                ),

                // Glassmorphic inner circle
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: ringSize - 32,
                      height: ringSize - 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surface.withOpacity(0.6),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Elapsed time
                          Text(
                            formatDuration(elapsed),
                            style: GoogleFonts.notoSerif(
                              fontSize: clockFontSize,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Remaining label
                          if (status != TimerStatus.idle)
                            Text(
                              '${formatDuration(remaining.isNegative ? Duration.zero : remaining)} left',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),

                          if (status == TimerStatus.idle)
                            Text(
                              'Set duration below',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final TimerStatus status;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.status,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 10.0;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [color.withOpacity(0.6), color],
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + 2 * math.pi * progress,
          tileMode: TileMode.clamp,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.status != status;
}

// ─── Duration Setup ──────────────────────────────────────────────────────────

class _DurationSetup extends StatelessWidget {
  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final TextEditingController secondsController;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isWide;

  const _DurationSetup({
    required this.hoursController,
    required this.minutesController,
    required this.secondsController,
    required this.colorScheme,
    required this.textTheme,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Duration',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DurationField(
                      controller: hoursController,
                      label: 'Hours',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: GoogleFonts.notoSerif(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _DurationField(
                      controller: minutesController,
                      label: 'Minutes',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      max: 59,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: GoogleFonts.notoSerif(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _DurationField(
                      controller: secondsController,
                      label: 'Seconds',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      max: 59,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _DurationField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final int? max;

  const _DurationField({
    required this.controller,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (max != null) _MaxValueFormatter(max!),
          ],
          style: GoogleFonts.notoSerif(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

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

// ─── Timer Controls ──────────────────────────────────────────────────────────

class _TimerControls extends StatelessWidget {
  final TimerStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isWide;

  const _TimerControls({
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.colorScheme,
    required this.textTheme,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        // Primary action button
        if (status == TimerStatus.idle)
          _GradientButton(
            label: 'Start Timer',
            icon: Icons.play_arrow_rounded,
            gradientColors: [colorScheme.primary, colorScheme.primaryContainer],
            onPressed: onStart,
            textTheme: textTheme,
            colorScheme: colorScheme,
            isPrimary: true,
          )
        else if (status == TimerStatus.running)
          _GradientButton(
            label: 'Pause',
            icon: Icons.pause_rounded,
            gradientColors: [colorScheme.tertiary, colorScheme.tertiaryContainer],
            onPressed: onPause,
            textTheme: textTheme,
            colorScheme: colorScheme,
            isPrimary: true,
          )
        else if (status == TimerStatus.paused)
          _GradientButton(
            label: 'Resume',
            icon: Icons.play_arrow_rounded,
            gradientColors: [colorScheme.secondary, colorScheme.secondaryContainer],
            onPressed: onResume,
            textTheme: textTheme,
            colorScheme: colorScheme,
            isPrimary: true,
          )
        else if (status == TimerStatus.finished)
          _GradientButton(
            label: 'Time\'s Up!',
            icon: Icons.celebration_rounded,
            gradientColors: [colorScheme.error, colorScheme.errorContainer],
            onPressed: () {},
            textTheme: textTheme,
            colorScheme: colorScheme,
            isPrimary: true,
          ),

        // Reset button
        if (status != TimerStatus.idle)
          _GlassButton(
            label: 'Reset',
            icon: Icons.refresh_rounded,
            onPressed: onReset,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.15, end: 0);
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onPressed;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final bool isPrimary;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.onPressed,
    required this.textTheme,
    required this.colorScheme,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPrimary ? 32 : 24,
          vertical: isPrimary ? 16 : 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.35),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.onPrimary, size: isPrimary ? 24 : 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isPrimary ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.04),
                  blurRadius: 32,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Footer Decoration ───────────────────────────────────────────────────────

class _FooterDecoration extends StatelessWidget {
  final ColorScheme colorScheme;

  const _FooterDecoration({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sweeping wave divider
        CustomPaint(
          size: const Size(double.infinity, 40),
          painter: _WaveDividerPainter(
            color1: colorScheme.primary.withOpacity(0.15),
            color2: colorScheme.secondary.withOpacity(0.15),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pagsaulog — Celebrating the Riches of Our Roots',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSerif(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'National Culture & Arts Festival 2026',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms, delay: 200.ms);
  }
}

class _WaveDividerPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  _WaveDividerPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x += size.width / 6) {
      path.quadraticBezierTo(
        x + size.width / 12,
        0,
        x + size.width / 6,
        size.height * 0.5,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color1, color2],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveDividerPainter old) => false;
}
