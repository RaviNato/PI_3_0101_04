import 'package:flutter/material.dart';
import 'character_screen.dart';
import '../services/save_service.dart';
import '../models/game_save.dart';

/// O botão "JOGAR" carrega o save do Firebase antes de navegar,
/// garantindo que a CharacterScreen sempre inicie com o estado persistido.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  // Indica que o carregamento do save está em andamento
  bool _carregando = false;

  static const Color _bgDeep        = Color(0xFF1C1008);
  static const Color _bgMid         = Color(0xFF2E1A0E);
  static const Color _parchment     = Color(0xFFF2E0B6);
  static const Color _parchmentDark = Color(0xFFD4B483);
  static const Color _inkBrown      = Color(0xFF3D1F00);
  static const Color _goldWarm      = Color(0xFFBF8A30);
  static const Color _goldLight     = Color(0xFFE8C060);
  static const Color _redWax        = Color(0xFF7A1C1C);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Carregamento do save e navegação
  Future<void> _iniciarJogo(BuildContext context) async {
    if (_carregando) return;
    setState(() => _carregando = true);

    try {
      // Autentica anonimamente e carrega (ou cria) o documento do jogador.
      final GameSave saveCarregado =
          await SaveService().carregarOuCriarSave();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) =>
              CharacterScreen(initialSave: saveCarregado),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar o jogo: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      setState(() => _carregando = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final isSmall = size.width < 380;

    return Scaffold(
      backgroundColor: _bgDeep,
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (_, __) => FadeTransition(
                opacity: _fadeIn,
                child: Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: size.height - 48),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 20 : 32),
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.05),
                            _buildTopOrnament(),
                            SizedBox(height: size.height * 0.03),
                            _buildTitle(isSmall),
                            const SizedBox(height: 8),
                            _buildDivider(),
                            const SizedBox(height: 12),
                            _buildSubtitle(isSmall),
                            SizedBox(height: size.height * 0.05),
                            _buildParchmentCard(isSmall),
                            SizedBox(height: size.height * 0.05),
                            _buildButtons(context, isSmall),
                            SizedBox(height: size.height * 0.04),
                            _buildBottomOrnament(),
                            const SizedBox(height: 24),
                          ],
                        ),
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

  // ── Fundo

  Widget _buildBackground(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1C1008),
            Color(0xFF2E1A0E),
            Color(0xFF1C1008),
          ],
        ),
      ),
      child: CustomPaint(painter: _WoodGrainPainter()),
    );
  }

  // ── Ornamentos

  Widget _buildTopOrnament() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ornamentLine(),
        const SizedBox(width: 12),
        const Icon(Icons.auto_awesome, color: _goldWarm, size: 22),
        const SizedBox(width: 8),
        const Icon(Icons.shield, color: _goldWarm, size: 28),
        const SizedBox(width: 8),
        const Icon(Icons.auto_awesome, color: _goldWarm, size: 22),
        const SizedBox(width: 12),
        _ornamentLine(),
      ],
    );
  }

  Widget _ornamentLine() {
    return Container(
      width: 50,
      height: 1.5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _goldWarm, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _goldWarm.withOpacity(0.6)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.circle, color: _goldWarm, size: 6),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_goldWarm.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomOrnament() {
    return Column(
      children: [
        _buildDivider(),
        const SizedBox(height: 10),
        Text(
          'PUC-Campinas · Projeto Integrador III · 2026',
          style: TextStyle(
            fontSize: 10,
            color: _parchmentDark.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ── Título

  Widget _buildTitle(bool isSmall) {
    return Column(
      children: [
        Text(
          'OMNIZONA',
          style: TextStyle(
            fontSize: isSmall ? 38 : 50,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            color: _parchment,
            shadows: [
              Shadow(color: _goldWarm.withOpacity(0.8), blurRadius: 12),
              const Shadow(
                  color: _inkBrown,
                  blurRadius: 2,
                  offset: Offset(2, 2)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '— JOGO DE RPG —',
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 5,
            color: _goldWarm,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(bool isSmall) {
    return Text(
      '"Ressignifique sua vivência acadêmica\natravés de uma jornada épica"',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isSmall ? 13 : 14,
        color: _parchmentDark.withOpacity(0.8),
        fontStyle: FontStyle.italic,
        height: 1.6,
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Card de pergaminho com biomas

  Widget _buildParchmentCard(bool isSmall) {
    const biomes = [
      {'icon': Icons.forest,                'label': 'Floresta', 'color': Color(0xFF4A7C59)},
      {'icon': Icons.ac_unit,               'label': 'Geleira',  'color': Color(0xFF7EC8E3)},
      {'icon': Icons.waves,                 'label': 'Oceano',   'color': Color(0xFF3A7BD5)},
      {'icon': Icons.wb_sunny,              'label': 'Deserto',  'color': Color(0xFFD4A017)},
      {'icon': Icons.local_fire_department, 'label': 'Vulcão',   'color': Color(0xFFCC4400)},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6C8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _goldWarm.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6)),
          BoxShadow(
              color: _goldWarm.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text(
            'OS CINCO BIOMAS',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 4,
              color: _inkBrown.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: _inkBrown.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: biomes
                .map((b) => _BiomeChip(
                      icon: b['icon'] as IconData,
                      label: b['label'] as String,
                      color: b['color'] as Color,
                      small: isSmall,
                      onDark: false,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Explore o Campus I da PUC-Campinas\ne descubra cada bioma mapeado no espaço real.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              color: _inkBrown.withOpacity(0.65),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Botões

  Widget _buildButtons(BuildContext context, bool isSmall) {
    return Column(
      children: [
        // Botão JOGAR: async, carrega save, navega para CharacterScreen
        _MedievalButton(
          label: _carregando ? 'CARREGANDO...' : 'JOGAR',
          icon: _carregando ? Icons.hourglass_top : Icons.play_arrow_rounded,
          primary: true,
          isSmall: isSmall,
          onPressed: _carregando ? null : () => _iniciarJogo(context),
        ),
        const SizedBox(height: 14),
        _MedievalButton(
          label: 'CONTINUAR JOGO',
          icon: Icons.bookmark_rounded,
          primary: false,
          isSmall: isSmall,
          onPressed: null, // Habilitado via botão JOGAR (carrega save automaticamente)
          tooltip: 'Use "JOGAR" — o progresso é carregado automaticamente',
        ),
      ],
    );
  }
}

// ─── Botão medieval

class _MedievalButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final bool isSmall;
  final VoidCallback? onPressed;
  final String? tooltip;

  static const Color _goldWarm  = Color(0xFFBF8A30);
  static const Color _goldLight = Color(0xFFE8C060);
  static const Color _inkBrown  = Color(0xFF3D1F00);
  static const Color _redWax    = Color(0xFF7A1C1C);
  static const Color _parchment = Color(0xFFF2E0B6);

  const _MedievalButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.isSmall,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    Widget btn = Container(
      width: double.infinity,
      height: isSmall ? 52 : 58,
      decoration: BoxDecoration(
        color: enabled
            ? (primary ? _redWax : const Color(0xFF2E1A0E))
            : const Color(0xFF2A1A0A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: enabled
              ? (primary ? _goldLight : _goldWarm.withOpacity(0.5))
              : _goldWarm.withOpacity(0.2),
          width: primary ? 2 : 1.5,
        ),
        boxShadow: enabled && primary
            ? [
                BoxShadow(
                    color: _redWax.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
                BoxShadow(
                    color: _goldWarm.withOpacity(0.2), blurRadius: 6),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          splashColor: _goldWarm.withOpacity(0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled
                    ? (primary ? _goldLight : _goldWarm.withOpacity(0.6))
                    : _goldWarm.withOpacity(0.2),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: enabled
                      ? (primary ? _parchment : _parchment.withOpacity(0.5))
                      : _parchment.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

// ─── Chip de bioma

class _BiomeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool small;
  final bool onDark;

  const _BiomeChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.small,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: small ? 38 : 44,
          height: small ? 38 : 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.7), width: 1.5),
          ),
          child: Icon(icon, color: color, size: small ? 18 : 22),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: small ? 9 : 10,
            color: onDark
                ? color.withOpacity(0.85)
                : const Color(0xFF3D1F00).withOpacity(0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBF8A30).withOpacity(0.03)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 18) {
      paint.color = const Color(0xFFBF8A30)
          .withOpacity(0.02 + (y % 54 == 0 ? 0.02 : 0));
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 4), paint);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.8,
          colors: [
            const Color(0xFFBF8A30).withOpacity(0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
