import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// HomeScreen — Tela inicial do Omnizona
///
/// Requisitos cobertos:
///  • Interface navegável sem treinamento prévio
///  • Som passivo (comentado — adicionar audioplayers quando assets estiverem prontos)
///  • Responsividade de telas
///  • Integração do BD (Firebase) no botão "Jogar"
///  • Elementos visuais (texto + imagens/ícones temáticos)
///  • Botões "Jogar" e "Continuar Jogo"

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _titleScale;

  bool _isLoading = false;
  bool _hasSavedGame = false;

  // ─── Cores temáticas RPG ─────────────────────────────────────────────────
  static const Color _bgDark = Color(0xFF0B0C10);
  static const Color _bgMid = Color(0xFF1A1A2E);
  static const Color _accent = Color(0xFFE8B84B); // dourado
  static const Color _accentGlow = Color(0xFFFFD166);
  static const Color _textLight = Color(0xFFF0E6CC);
  static const Color _textMuted = Color(0xFF8D8D8D);
  static const Color _btnPrimary = Color(0xFF4A1942);
  static const Color _btnSecondary = Color(0xFF1B2A4A);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _titleScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animController.forward();
    _checkSavedGame();

    // ── Som ambiente ──────────────────────────────────────────────────────
    // Para ativar o som, adicione ao pubspec.yaml:
    //   audioplayers: ^6.0.0
    // Coloque o arquivo em: assets/audio/ambient_rpg.mp3
    // Depois descomente o bloco abaixo:
    //
    // _player = AudioPlayer();
    // _player.setReleaseMode(ReleaseMode.loop);
    // await _player.play(AssetSource('audio/ambient_rpg.mp3'), volume: 0.3);
  }

  @override
  void dispose() {
    _animController.dispose();
    // _player.dispose(); // descomente se usar audioplayers
    super.dispose();
  }

  // ─── Verifica se o usuário tem progresso salvo no Firestore ──────────────
  Future<void> _checkSavedGame() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('players')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _hasSavedGame = doc.exists && (doc.data()?['progress'] != null);
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar jogo salvo: $e');
    }
  }

  // ─── Botão "Jogar" — cria novo jogo no Firebase ──────────────────────────
  Future<void> _onPlayPressed() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;

      // Login anônimo caso não haja sessão
      if (user == null) {
        final credential = await FirebaseAuth.instance.signInAnonymously();
        user = credential.user;
      }

      if (user == null) throw Exception('Falha na autenticação.');

      // Cria / sobrescreve documento de progresso inicial
      await FirebaseFirestore.instance
          .collection('players')
          .doc(user.uid)
          .set({
        'progress': {
          'currentZone': 'forest',
          'unlockedZones': ['forest'],
          'inventory': [],
          'dialogFlags': {},
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/game');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Não foi possível iniciar o jogo. Tente novamente.');
      }
      debugPrint('Erro ao iniciar jogo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Botão "Continuar Jogo" ───────────────────────────────────────────────
  Future<void> _onContinuePressed() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');

      // Confirma que o progresso existe antes de navegar
      final doc = await FirebaseFirestore.instance
          .collection('players')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        throw Exception('Nenhum jogo salvo encontrado.');
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/game');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Não foi possível carregar o jogo salvo.');
      }
      debugPrint('Erro ao continuar jogo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 380;

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Fundo gradiente
          _buildBackground(size),

          // Partículas decorativas (círculos difusos)
          _buildDecoParticles(size),

          // Conteúdo principal
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - 80),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 20.0 : 32.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: size.height * 0.06),
                        _buildLogo(isSmall),
                        SizedBox(height: size.height * 0.04),
                        _buildTitle(isSmall),
                        const SizedBox(height: 12),
                        _buildSubtitle(isSmall),
                        SizedBox(height: size.height * 0.07),
                        _buildBiomesRow(isSmall),
                        SizedBox(height: size.height * 0.07),
                        _buildButtons(isSmall),
                        SizedBox(height: size.height * 0.06),
                        _buildFooter(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Overlay de carregamento
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ─── Widgets internos ─────────────────────────────────────────────────────

  Widget _buildBackground(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.4),
          radius: 1.2,
          colors: [
            Color(0xFF1C0F2E),
            Color(0xFF0B0C10),
          ],
        ),
      ),
    );
  }

  Widget _buildDecoParticles(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _StarfieldPainter(),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isSmall) {
    return ScaleTransition(
      scale: _titleScale,
      child: Container(
        width: isSmall ? 80 : 100,
        height: isSmall ? 80 : 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _btnPrimary,
          border: Border.all(color: _accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: _accentGlow.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        // Substitua pelo asset real quando disponível:
        // child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        child: Icon(
          Icons.explore,
          size: isSmall ? 42 : 52,
          color: _accentGlow,
        ),
      ),
    );
  }

  Widget _buildTitle(bool isSmall) {
    return ScaleTransition(
      scale: _titleScale,
      child: Column(
        children: [
          Text(
            'OMNIZONA',
            style: TextStyle(
              fontSize: isSmall ? 36 : 46,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: _accentGlow,
              shadows: [
                Shadow(
                  color: _accent.withOpacity(0.7),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: isSmall ? 160 : 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _accent,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(bool isSmall) {
    return Text(
      'Ressignifique sua vivência acadêmica',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isSmall ? 13 : 15,
        color: _textMuted,
        letterSpacing: 1.2,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildBiomesRow(bool isSmall) {
    const biomes = [
      {'icon': Icons.forest, 'label': 'Floresta', 'color': Color(0xFF2D6A4F)},
      {'icon': Icons.ac_unit, 'label': 'Geleira', 'color': Color(0xFF48CAE4)},
      {'icon': Icons.waves, 'label': 'Oceano', 'color': Color(0xFF0077B6)},
      {'icon': Icons.wb_sunny, 'label': 'Deserto', 'color': Color(0xFFE9C46A)},
      {'icon': Icons.local_fire_department, 'label': 'Vulcão', 'color': Color(0xFFE76F51)},
    ];

    return Column(
      children: [
        Text(
          '— OS CINCO BIOMAS —',
          style: TextStyle(
            fontSize: isSmall ? 10 : 11,
            color: _textMuted,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: biomes.map((b) {
            return _BiomeChip(
              icon: b['icon'] as IconData,
              label: b['label'] as String,
              color: b['color'] as Color,
              small: isSmall,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildButtons(bool isSmall) {
    return Column(
      children: [
        // ── Jogar ──
        _OmniButton(
          label: 'JOGAR',
          icon: Icons.play_arrow_rounded,
          color: _btnPrimary,
          glowColor: _accent,
          textColor: _accentGlow,
          onPressed: _isLoading ? null : _onPlayPressed,
          isSmall: isSmall,
        ),
        const SizedBox(height: 16),

        // ── Continuar Jogo ──
        _OmniButton(
          label: 'CONTINUAR JOGO',
          icon: Icons.bookmark_rounded,
          color: _hasSavedGame ? _btnSecondary : _bgMid,
          glowColor: _hasSavedGame ? Colors.blueAccent : Colors.transparent,
          textColor: _hasSavedGame ? Colors.lightBlueAccent : _textMuted,
          onPressed: (_isLoading || !_hasSavedGame) ? null : _onContinuePressed,
          isSmall: isSmall,
          outlined: true,
          tooltip: _hasSavedGame ? null : 'Nenhum jogo salvo encontrado',
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      'PUC-Campinas · Projeto Integrador III · 2026',
      style: TextStyle(
        fontSize: 11,
        color: _textMuted.withOpacity(0.5),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(
          color: _accentGlow,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

// ─── Chip de bioma ────────────────────────────────────────────────────────────

class _BiomeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool small;

  const _BiomeChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.small,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: small ? 40 : 48,
          height: small ? 40 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: small ? 20 : 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: small ? 9 : 10,
            color: color.withOpacity(0.85),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Botão temático ───────────────────────────────────────────────────────────

class _OmniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color glowColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isSmall;
  final bool outlined;
  final String? tooltip;

  const _OmniButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.glowColor,
    required this.textColor,
    required this.onPressed,
    required this.isSmall,
    this.outlined = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: isSmall ? 52 : 60,
      decoration: BoxDecoration(
        color: onPressed != null ? color : color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: outlined
            ? Border.all(color: glowColor.withOpacity(0.5), width: 1.5)
            : null,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: onPressed != null ? textColor : textColor.withOpacity(0.4), size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                  color: onPressed != null ? textColor : textColor.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

// ─── Painter para estrelas de fundo ──────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.15);
    final stars = [
      Offset(size.width * 0.1, size.height * 0.08),
      Offset(size.width * 0.25, size.height * 0.15),
      Offset(size.width * 0.6, size.height * 0.05),
      Offset(size.width * 0.8, size.height * 0.12),
      Offset(size.width * 0.45, size.height * 0.22),
      Offset(size.width * 0.9, size.height * 0.3),
      Offset(size.width * 0.05, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.55),
      Offset(size.width * 0.15, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.85),
      Offset(size.width * 0.85, size.height * 0.75),
      Offset(size.width * 0.35, size.height * 0.95),
    ];
    for (final s in stars) {
      canvas.drawCircle(s, 1.5, paint);
    }

    // Círculos difusos decorativos
    final glowPaint = Paint()
      ..color = const Color(0xFFE8B84B).withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.1), 120, glowPaint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), 100, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
