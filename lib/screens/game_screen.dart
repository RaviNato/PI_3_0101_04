import 'package:flutter/material.dart';

/// GameScreen — Tela básica do jogo Omnizona
/// Sprint 1: personagem (Jorge), fundo de floresta, HUD básico
/// Será expandida nos próximos sprints com geolocalização, diálogos e biomas

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late Animation<double> _idleBob;
  late AnimationController _fadeController;

  // ── Paleta da floresta / jogo ────────────────────────────────────────────
  static const Color _skyTop    = Color(0xFF0D1B2A);
  static const Color _skyBottom = Color(0xFF1A3A2A);
  static const Color _groundTop = Color(0xFF2D4A1E);
  static const Color _groundBot = Color(0xFF1A2E10);
  static const Color _hudBg     = Color(0xCC1C1008);
  static const Color _hudBorder = Color(0xFFBF8A30);
  static const Color _parchment = Color(0xFFF2E0B6);
  static const Color _goldWarm  = Color(0xFFBF8A30);
  static const Color _hpRed     = Color(0xFFB22222);
  static const Color _xpBlue    = Color(0xFF2255AA);

  // Estado básico do personagem
  String _zona = 'Floresta';
  int _hp = 100;
  int _xp = 0;

  @override
  void initState() {
    super.initState();

    // Animação idle do personagem (leve balanço)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _idleBob = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // Fade de entrada
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _idleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 380;

    return Scaffold(
      backgroundColor: _skyTop,
      body: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          children: [
            // 1. Fundo (céu + chão)
            _buildBackground(size),

            // 2. Árvores decorativas
            _buildTrees(size),

            // 3. Personagem (Jorge)
            _buildCharacter(size, isSmall),

            // 4. HUD superior (zona + stats)
            _buildHUD(size, isSmall),

            // 5. Caixa de texto narrativa
            _buildNarrativeBox(size, isSmall),

            // 6. Botão voltar
            _buildBackButton(context),
          ],
        ),
      ),
    );
  }

  // ── Fundo ────────────────────────────────────────────────────────────────

  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        // Céu
        Container(
          width: size.width,
          height: size.height * 0.55,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_skyTop, _skyBottom],
            ),
          ),
        ),
        // Lua / astro
        Positioned(
          top: size.height * 0.06,
          right: size.width * 0.12,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5E6C8).withOpacity(0.85),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5E6C8).withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
        // Chão
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: size.height * 0.48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_groundTop, _groundBot],
              ),
            ),
          ),
        ),
        // Linha do horizonte
        Positioned(
          top: size.height * 0.52,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            color: const Color(0xFF4A7C59).withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  // ── Árvores ───────────────────────────────────────────────────────────────

  Widget _buildTrees(Size size) {
    return Positioned(
      top: size.height * 0.28,
      left: 0,
      right: 0,
      child: CustomPaint(
        size: Size(size.width, size.height * 0.28),
        painter: _TreesPainter(),
      ),
    );
  }

  // ── Personagem ────────────────────────────────────────────────────────────

  Widget _buildCharacter(Size size, bool isSmall) {
    final charSize = isSmall ? 90.0 : 110.0;

    return Positioned(
      bottom: size.height * 0.22,
      left: size.width / 2 - charSize / 2,
      child: AnimatedBuilder(
        animation: _idleBob,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _idleBob.value),
          child: SizedBox(
            width: charSize,
            height: charSize * 1.6,
            child: CustomPaint(
              painter: _JorgePainter(),
            ),
          ),
        ),
      ),
    );
  }

  // ── HUD superior ──────────────────────────────────────────────────────────

  Widget _buildHUD(Size size, bool isSmall) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _hudBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _hudBorder.withOpacity(0.6), width: 1.5),
        ),
        child: Row(
          children: [
            // Zona atual
            Icon(Icons.forest, color: _goldWarm, size: 16),
            const SizedBox(width: 6),
            Text(
              _zona,
              style: TextStyle(
                color: _parchment,
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            // HP
            Icon(Icons.favorite, color: _hpRed, size: 14),
            const SizedBox(width: 4),
            _statBar(_hp / 100, _hpRed, isSmall),
            const SizedBox(width: 10),
            // XP
            Icon(Icons.star, color: _xpBlue, size: 14),
            const SizedBox(width: 4),
            _statBar(_xp / 100, _xpBlue, isSmall),
          ],
        ),
      ),
    );
  }

  Widget _statBar(double value, Color color, bool isSmall) {
    return Container(
      width: isSmall ? 44 : 56,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // ── Caixa narrativa ───────────────────────────────────────────────────────

  Widget _buildNarrativeBox(Size size, bool isSmall) {
    return Positioned(
      bottom: 24,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xF0F5E6C8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _hudBorder.withOpacity(0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: const Color(0xFF3D1F00), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Jorge',
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3D1F00),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '"A floresta ao redor do H15 parece diferente hoje... algo me chama para explorar."',
              style: TextStyle(
                fontSize: isSmall ? 12 : 13,
                color: const Color(0xFF3D1F00).withOpacity(0.85),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Toque para continuar ▶',
                style: TextStyle(
                  fontSize: 10,
                  color: _goldWarm.withOpacity(0.8),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Botão voltar ──────────────────────────────────────────────────────────

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const _HomeBackPlaceholder(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        ),
      ),
    );
    // O botão de voltar está implícito no HUD; AppBar não usada para manter imersão.
    // Se quiser botão explícito, descomente abaixo:
    //
    // return Positioned(
    //   top: MediaQuery.of(context).padding.top + 8,
    //   left: 12,
    //   child: GestureDetector(
    //     onTap: () => Navigator.pop(context),
    //     child: Container(
    //       padding: const EdgeInsets.all(8),
    //       decoration: BoxDecoration(
    //         color: _hudBg,
    //         shape: BoxShape.circle,
    //         border: Border.all(color: _hudBorder, width: 1.5),
    //       ),
    //       child: const Icon(Icons.arrow_back, color: _parchment, size: 18),
    //     ),
    //   ),
    // );
  }
}

// ─── Placeholder para navegar de volta à home ─────────────────────────────────
// Remove isso quando o main.dart tiver as rotas configuradas

class _HomeBackPlaceholder extends StatelessWidget {
  const _HomeBackPlaceholder();
  @override
  Widget build(BuildContext context) {
    // Importa e usa HomeScreen normalmente quando estiver no projeto real
    return const Scaffold(
      backgroundColor: Color(0xFF1C1008),
      body: Center(
        child: Text('← Voltar para Home', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─── Painter do personagem Jorge ─────────────────────────────────────────────

class _JorgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sombra no chão
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.95), width: w * 0.6, height: h * 0.06),
      shadowPaint,
    );

    // Pernas (calça marrom escura)
    final pantsPaint = Paint()..color = const Color(0xFF3D2B1A);
    // perna esquerda
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.62, w * 0.16, h * 0.32),
        const Radius.circular(4),
      ),
      pantsPaint,
    );
    // perna direita
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.54, h * 0.62, w * 0.16, h * 0.32),
        const Radius.circular(4),
      ),
      pantsPaint,
    );

    // Botas
    final bootPaint = Paint()..color = const Color(0xFF1A0F05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.27, h * 0.88, w * 0.20, h * 0.08),
        const Radius.circular(3),
      ),
      bootPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.53, h * 0.88, w * 0.20, h * 0.08),
        const Radius.circular(3),
      ),
      bootPaint,
    );

    // Corpo (casaco de couro)
    final bodyPaint = Paint()..color = const Color(0xFF6B3A1F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.56, h * 0.30),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Detalhe cinto
    final beltPaint = Paint()..color = const Color(0xFF2A1505);
    canvas.drawRect(Rect.fromLTWH(w * 0.22, h * 0.60, w * 0.56, h * 0.04), beltPaint);
    // fivela
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, h * 0.595, w * 0.10, h * 0.05),
      Paint()..color = const Color(0xFFBF8A30),
    );

    // Braços
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.34, w * 0.18, h * 0.26),
        const Radius.circular(5),
      ),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.76, h * 0.34, w * 0.18, h * 0.26),
        const Radius.circular(5),
      ),
      bodyPaint,
    );

    // Pescoço
    final skinPaint = Paint()..color = const Color(0xFFD4956A);
    canvas.drawRect(Rect.fromLTWH(w * 0.42, h * 0.22, w * 0.16, h * 0.14), skinPaint);

    // Cabeça
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.06, w * 0.44, h * 0.22),
        const Radius.circular(8),
      ),
      skinPaint,
    );

    // Olhos
    final eyePaint = Paint()..color = const Color(0xFF1A0A00);
    canvas.drawOval(Rect.fromLTWH(w * 0.36, h * 0.11, w * 0.08, h * 0.05), eyePaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.56, h * 0.11, w * 0.08, h * 0.05), eyePaint);

    // Chapéu de arqueólogo
    final hatPaint = Paint()..color = const Color(0xFF4A2800);
    // aba
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.065, w * 0.68, h * 0.06),
        const Radius.circular(3),
      ),
      hatPaint,
    );
    // copa
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * -0.01, w * 0.40, h * 0.09),
        const Radius.circular(4),
      ),
      hatPaint,
    );
    // fita do chapéu
    canvas.drawRect(
      Rect.fromLTWH(w * 0.30, h * 0.065, w * 0.40, h * 0.015),
      Paint()..color = const Color(0xFFBF8A30),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Painter das árvores de fundo ─────────────────────────────────────────────

class _TreesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final trunkPaint = Paint()..color = const Color(0xFF2A1A08);
    final leafPaint   = Paint()..color = const Color(0xFF1E4020);
    final leafPaint2  = Paint()..color = const Color(0xFF2D5A2A);

    void drawTree(double x, double groundY, double scale) {
      // Tronco
      canvas.drawRect(
        Rect.fromLTWH(x - 6 * scale, groundY - 60 * scale, 12 * scale, 60 * scale),
        trunkPaint,
      );
      // Copa (3 triângulos sobrepostos)
      for (int i = 0; i < 3; i++) {
        final p = Paint()..color = i.isEven ? leafPaint.color : leafPaint2.color;
        final path = Path();
        final yBase = groundY - 50 * scale - i * 22 * scale;
        path.moveTo(x, yBase - 55 * scale);
        path.lineTo(x - 38 * scale + i * 6 * scale, yBase);
        path.lineTo(x + 38 * scale - i * 6 * scale, yBase);
        path.close();
        canvas.drawPath(path, p);
      }
    }

    // Árvores atrás (menores, mais escuras)
    leafPaint.color = const Color(0xFF162E18);
    leafPaint2.color = const Color(0xFF1E3A1C);
    drawTree(size.width * 0.05, size.height * 0.85, 0.7);
    drawTree(size.width * 0.18, size.height * 0.90, 0.85);
    drawTree(size.width * 0.82, size.height * 0.90, 0.85);
    drawTree(size.width * 0.95, size.height * 0.85, 0.75);

    // Árvores laterais (maiores, mais à frente)
    leafPaint.color = const Color(0xFF1E4020);
    leafPaint2.color = const Color(0xFF2D5A2A);
    drawTree(size.width * 0.00, size.height * 1.0, 1.1);
    drawTree(size.width * 1.0,  size.height * 1.0, 1.1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
