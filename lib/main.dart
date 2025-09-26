import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF2196F3); // Azul Material vibrante
    return MaterialApp(
      title: 'Calculadora Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        textTheme: const TextTheme(bodyMedium: TextStyle(letterSpacing: 0.2)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      themeMode: _mode,
      home: CalculatorPage(
        onToggleTheme: () {
          setState(() {
            _mode = _mode == ThemeMode.dark
                ? ThemeMode.light
                : (_mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.dark);
          });
        },
        isDark: _mode == ThemeMode.dark,
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  const CalculatorPage({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with TickerProviderStateMixin {
  String _display = '0';
  String _expression = '';
  String _fullFormula = '';
  double? _first;
  String? _op;
  bool _awaitingSecond = false;
  bool _justCalculated = false;

  late AnimationController _displayController;
  late AnimationController _numberController;
  late AnimationController _formulaController;
  late Animation<double> _displayAnimation;
  late Animation<double> _numberAnimation;
  late Animation<double> _formulaFadeAnimation;
  late Animation<Offset> _formulaSlideAnimation;

  @override
  void initState() {
    super.initState();

    _displayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _displayAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _displayController, curve: Curves.elasticOut),
    );

    _numberController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _numberAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _numberController, curve: Curves.elasticOut),
    );

    _formulaController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _formulaFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formulaController, curve: Curves.easeOut),
    );
    _formulaSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _formulaController,
            curve: Curves.easeOutBack,
          ),
        );
  }

  @override
  void dispose() {
    _displayController.dispose();
    _numberController.dispose();
    _formulaController.dispose();
    super.dispose();
  }

  void _animateDisplay() {
    _displayController.reset();
    _displayController.forward();
  }

  void _animateNumber() {
    _numberController.reset();
    _numberController.forward();
  }

  void _animateFormula() {
    _formulaController.reset();
    _formulaController.forward();
  }

  void _num(String v) {
    setState(() {
      if (_justCalculated) {
        _display = v == '.' ? '0.' : v;
        _fullFormula = _display;
        _justCalculated = false;
        _first = null;
        _op = null;
        _awaitingSecond = false;
      } else if (_awaitingSecond) {
        _display = v == '.' ? '0.' : v;
        _awaitingSecond = false;
        if (_fullFormula.isNotEmpty && !_fullFormula.endsWith(' ')) {
          _fullFormula += ' ';
        }
        _fullFormula += _display;
      } else {
        if (_display == '0' && v != '.') {
          _display = v;
          if (_fullFormula == '0') {
            _fullFormula = v;
          } else {
            // asegura actualización del último número
            if (_fullFormula.isEmpty) {
              _fullFormula = v;
            } else {
              _fullFormula += v;
            }
          }
        } else if (v == '.' && _display.contains('.')) {
          return;
        } else {
          _display += v;
          _fullFormula += v;
        }
      }
      _updateExpression();
    });
    _animateNumber();
    HapticFeedback.lightImpact();
  }

  void _operator(String op) {
    setState(() {
      final current = double.tryParse(_display) ?? 0.0;

      if (_first == null) {
        _first = current;
        _fullFormula = _display;
      } else if (!_awaitingSecond && _op != null) {
        _first = _calc(_first!, current, _op!);
        _display = _fmt(_first!);
        _fullFormula = _fmt(_first!); // colapsa a resultado intermedio
      }

      _op = op;
      _awaitingSecond = true;
      _justCalculated = false;

      _fullFormula += ' $op';
      _updateExpression();
    });
    _animateFormula();
    HapticFeedback.selectionClick();
  }

  void _equals() {
    setState(() {
      if (_first == null || _op == null) return;

      final b = double.tryParse(_display) ?? 0.0;
      final r = _calc(_first!, b, _op!);

      if (_awaitingSecond) {
        _fullFormula += ' ${_display}';
      }
      _display = _fmt(r);
      _expression = '$_fullFormula = $_display';

      _first = r; // permite encadenar
      _op = null;
      _awaitingSecond = false;
      _justCalculated = true;
    });
    _animateDisplay();
    HapticFeedback.mediumImpact();
  }

  void _clear() {
    setState(() {
      _display = '0';
      _expression = '';
      _fullFormula = '';
      _first = null;
      _op = null;
      _awaitingSecond = false;
      _justCalculated = false;
    });
    _animateDisplay();
    HapticFeedback.lightImpact();
  }

  void _back() {
    setState(() {
      if (_awaitingSecond || _justCalculated) return;

      if (_display.length <= 1) {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
        if (_display == '-' || _display == '-0') _display = '0';
      }

      if (_fullFormula.isNotEmpty) {
        _fullFormula = _fullFormula.substring(0, _fullFormula.length - 1);
        if (_fullFormula.isEmpty) _fullFormula = _display;
      }

      _updateExpression();
    });
    _animateNumber();
    HapticFeedback.lightImpact();
  }

  void _sign() {
    setState(() {
      if (_display == '0') return;
      _display = _display.startsWith('-')
          ? _display.substring(1)
          : '-$_display';

      final parts = _fullFormula.split(' ');
      if (parts.isNotEmpty) {
        parts[parts.length - 1] = _display;
        _fullFormula = parts.join(' ');
      }

      _updateExpression();
    });
    _animateNumber();
    HapticFeedback.lightImpact();
  }

  void _percent() {
    setState(() {
      final v = double.tryParse(_display) ?? 0.0;
      _display = _fmt(v / 100);

      final parts = _fullFormula.split(' ');
      if (parts.isNotEmpty) {
        parts[parts.length - 1] = _display;
        _fullFormula = parts.join(' ');
      }

      _updateExpression();
    });
    _animateNumber();
    HapticFeedback.lightImpact();
  }

  double _calc(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) return double.nan;
        return a / b;
      default:
        return b;
    }
  }

  String _fmt(double n) {
    if (n.isNaN || n.isInfinite) return 'Error';
    final s = n.toStringAsFixed(12);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _updateExpression() {
    if (_justCalculated) return;
    if (_fullFormula.isEmpty) {
      _expression = _display;
    } else {
      _expression = _fullFormula;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        final isXS = w < 360;
        final isSM = w >= 360 && w < 480;
        final isMD = w >= 480 && w < 768;
        final isLG = w >= 768;

        final maxContentWidth = isLG ? 520.0 : (isMD ? 480.0 : double.infinity);
        final horizontal = isLG ? 24.0 : (isMD ? 20.0 : 16.0);
        final vertical = isLG ? 20.0 : (isMD ? 18.0 : 14.0);
        final spacing = isXS ? 10.0 : 12.0;
        final keyAspect = isXS ? 1.05 : (isSM ? 1.1 : 1.15);
        final baseFont = isXS ? 48.0 : (isSM ? 56.0 : (isMD ? 64.0 : 72.0));

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: brightness == Brightness.dark
                  ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                  : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontal,
                    vertical: vertical,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header con toggle de tema
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calculate_outlined,
                              color: cs.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Calculadora',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: widget.isDark
                                  ? 'Tema claro'
                                  : 'Tema oscuro',
                              onPressed: widget.onToggleTheme,
                              icon: Icon(
                                widget.isDark
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: cs.primary,
                              ),
                            ),
                            if (_op != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _op!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onPrimaryContainer,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Área de pantalla (fórmula + resultado)
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: cs.outline.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Fórmula con fade/slide
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: FadeTransition(
                                    opacity: _formulaFadeAnimation,
                                    child: SlideTransition(
                                      position: _formulaSlideAnimation,
                                      child: Text(
                                        _expression,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: cs.onSurface.withOpacity(0.6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Resultado con scale elástico
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.bottomRight,
                                  child: AnimatedBuilder(
                                    animation: _displayAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _displayAnimation.value,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            _display,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: baseFont,
                                              fontWeight: FontWeight.w300,
                                              color: cs.onSurface,
                                              letterSpacing: -0.5,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Teclado
                      Expanded(
                        flex: 6,
                        child: _Keyboard(
                          spacing: spacing,
                          keyAspect: keyAspect,
                          onKey: _num,
                          onOp: _operator,
                          onEq: _equals,
                          onClear: _clear,
                          onBack: _back,
                          onSign: _sign,
                          onPercent: _percent,
                          colorScheme: cs,
                        ),
                      ),
                    ],
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

// ---- Tonos/roles de teclas (colores diferenciados) ----
enum KeyTone { normal, muted, op, primary, delete }

class _Keyboard extends StatelessWidget {
  final double spacing;
  final double keyAspect;
  final void Function(String) onKey;
  final void Function(String) onOp;
  final VoidCallback onEq;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final VoidCallback onSign;
  final VoidCallback onPercent;
  final ColorScheme colorScheme;

  const _Keyboard({
    required this.spacing,
    required this.keyAspect,
    required this.onKey,
    required this.onOp,
    required this.onEq,
    required this.onClear,
    required this.onBack,
    required this.onSign,
    required this.onPercent,
    required this.colorScheme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget gap() => SizedBox(width: spacing, height: spacing);

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _Key(
                label: 'C',
                tone: KeyTone.muted,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: onClear,
              ),
              gap(),
              _Key(
                label: '±',
                tone: KeyTone.muted,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: onSign,
              ),
              gap(),
              _Key(
                label: '%',
                tone: KeyTone.muted,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: onPercent,
              ),
              gap(),
              _Key(
                label: '÷',
                tone: KeyTone.op,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onOp('÷'),
              ),
            ],
          ),
        ),
        gap(),
        Expanded(
          child: Row(
            children: [
              _Key(
                label: '7',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('7'),
              ),
              gap(),
              _Key(
                label: '8',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('8'),
              ),
              gap(),
              _Key(
                label: '9',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('9'),
              ),
              gap(),
              _Key(
                label: '×',
                tone: KeyTone.op,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onOp('×'),
              ),
            ],
          ),
        ),
        gap(),
        Expanded(
          child: Row(
            children: [
              _Key(
                label: '4',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('4'),
              ),
              gap(),
              _Key(
                label: '5',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('5'),
              ),
              gap(),
              _Key(
                label: '6',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('6'),
              ),
              gap(),
              _Key(
                label: '-',
                tone: KeyTone.op,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onOp('-'),
              ),
            ],
          ),
        ),
        gap(),
        Expanded(
          child: Row(
            children: [
              _Key(
                label: '1',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('1'),
              ),
              gap(),
              _Key(
                label: '2',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('2'),
              ),
              gap(),
              _Key(
                label: '3',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('3'),
              ),
              gap(),
              _Key(
                label: '+',
                tone: KeyTone.op,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onOp('+'),
              ),
            ],
          ),
        ),
        gap(),
        Expanded(
          child: Row(
            children: [
              _Key(
                label: '0',
                tone: KeyTone.normal,
                aspect: keyAspect,
                flex: 2,
                colorScheme: colorScheme,
                onTap: () => onKey('0'),
              ),
              gap(),
              _Key(
                label: '.',
                tone: KeyTone.normal,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: () => onKey('.'),
              ),
              gap(),
              _KeyIcon(
                icon: Icons.backspace_outlined,
                tone: KeyTone.delete,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: onBack,
              ),
              gap(),
              _Key(
                label: '=',
                tone: KeyTone.primary,
                aspect: keyAspect,
                colorScheme: colorScheme,
                onTap: onEq,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Key extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final int flex;
  final KeyTone tone;
  final double aspect;
  final ColorScheme colorScheme;

  const _Key({
    required this.label,
    required this.onTap,
    this.flex = 1,
    this.tone = KeyTone.normal,
    required this.aspect,
    required this.colorScheme,
    super.key,
  });

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late Color shadowColor;
    final cs = widget.colorScheme;

    // Colores por rol:
    // - normal (números): secondaryContainer
    // - op (operaciones): tertiaryContainer
    // - primary (=): primary
    // - delete: errorContainer
    // - muted (C, ±, %): surfaceContainerHighest
    switch (widget.tone) {
      case KeyTone.muted:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface.withOpacity(0.85);
        shadowColor = cs.shadow.withOpacity(0.06);
        break;
      case KeyTone.op:
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        shadowColor = cs.tertiary.withOpacity(0.20);
        break;
      case KeyTone.primary:
        bg = cs.primary;
        fg = cs.onPrimary;
        shadowColor = cs.primary.withOpacity(0.30);
        break;
      case KeyTone.delete:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        shadowColor = cs.error.withOpacity(0.25);
        break;
      case KeyTone.normal:
      default:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        shadowColor = cs.secondary.withOpacity(0.18);
        break;
    }

    final button = AspectRatio(
      aspectRatio: widget.aspect,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isPressed ? bg.withOpacity(0.9) : bg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isPressed
                      ? []
                      : [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                  border: Border.all(
                    color: cs.outline.withOpacity(0.10),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return Expanded(flex: widget.flex, child: button);
  }
}

class _KeyIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final KeyTone tone;
  final double aspect;
  final ColorScheme colorScheme;

  const _KeyIcon({
    required this.icon,
    required this.onTap,
    this.tone = KeyTone.normal,
    required this.aspect,
    required this.colorScheme,
    super.key,
  });

  @override
  State<_KeyIcon> createState() => _KeyIconState();
}

class _KeyIconState extends State<_KeyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late Color shadowColor;
    final cs = widget.colorScheme;

    switch (widget.tone) {
      case KeyTone.muted:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface.withOpacity(0.85);
        shadowColor = cs.shadow.withOpacity(0.06);
        break;
      case KeyTone.op:
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        shadowColor = cs.tertiary.withOpacity(0.20);
        break;
      case KeyTone.primary:
        bg = cs.primary;
        fg = cs.onPrimary;
        shadowColor = cs.primary.withOpacity(0.30);
        break;
      case KeyTone.delete:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        shadowColor = cs.error.withOpacity(0.25);
        break;
      case KeyTone.normal:
      default:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        shadowColor = cs.secondary.withOpacity(0.18);
        break;
    }

    final button = AspectRatio(
      aspectRatio: widget.aspect,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isPressed ? bg.withOpacity(0.9) : bg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isPressed
                      ? []
                      : [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                  border: Border.all(
                    color: cs.outline.withOpacity(0.10),
                    width: 1,
                  ),
                ),
                child: Icon(widget.icon, color: fg, size: 22),
              ),
            ),
          );
        },
      ),
    );

    return Expanded(child: button);
  }
}
