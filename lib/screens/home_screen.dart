import 'package:flutter/material.dart';
import '../character_screen.dart';
import '../services/save_service.dart';
import '../models/game_save.dart';

/// HomeScreen — Tela inicial do Omnizona
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

  bool _carregando = false;
  
  // Variáveis para controlar a liberação do botão "Continuar"
  bool _temSave = false;
  GameSave? _saveCarregado;

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

    // Assim que a tela abre, verifica discretamente se já existe um jogo salvo no Firebase
    _verificarSaveExistente();
  }

  Future<void> _verificarSaveExistente() async {
    try {
      _saveCarregado = await SaveService().carregarOuCriarSave();
      
      if (mounted) {
        setState(() {
          // Se o jogador já destrancou biomas ou tem alguma flag salva, significa que o jogo está incompleto/em andamento
          if (_saveCarregado != null && 
             (_saveCarregado!.etapa > 0 || _saveCarregado!.biomasAbertos.length > 1 || _saveCarregado!.flags.isNotEmpty)) {
            _temSave = true; // Libera o botão "Continuar Jogo"
          }
        });
      }
    } catch (e) {
      // Falha silenciosa: se der erro na verificação, o botão de continuar apenas continua cinza
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Lógica de Novo Jogo
  Future<void> _iniciarNovoJogo() async {
    if (_carregando) return;

    // Se já existe um save em andamento, pede confirmação antes de apagar
    if (_temSave) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2E1A0E),
          title: const Text('Iniciar Nova Jornada?', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: const Text(
            'Isso apagará o seu progresso atual e você perderá todos os itens conquistados. Deseja mesmo começar do zero?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sim, apagar progresso', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmar != true) return; // Se o jogador cancelou, não faz nada
    }

    setState(() => _carregando = true);

    try {
      // Cria um save 100% zerado
      final GameSave saveZerado = GameSave(
        biomaAtual: 'bioma_01',
        etapa: 0,
        flags: {},
        biomasAbertos: ['bioma_01'],
      );

      // Sobrescreve o save antigo no Firebase
      await SaveService().atualizarSave(saveZerado);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => CharacterScreen(initialSave: saveZerado),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar novo jogo: $e'), backgroundColor: Colors.red.shade800),
      );
      setState(() => _carregando = false);
    }
  }

  // ── Lógica de Continuar Jogo
  Future<void> _continuarJogo() async {
    if (_carregando || _saveCarregado == null) return;
    setState(() => _carregando = true);

    // Navega diretamente enviando o save que já tínhamos carregado escondido na abertura da tela
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => CharacterScreen(initialSave: _saveCarregado!),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                      constraints: BoxConstraints(minHeight: size.height - 48),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 20 : 32,
                        ),
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

  Widget _buildBackground(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1008), Color(0xFF2E1A0E), Color(0xFF1C1008)],
        ),
      ),
      child: CustomPaint(painter: _WoodGrainPainter()),
    );
  }

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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
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
                offset: Offset(2, 2),
              ),
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
            offset: const Offset(0, 6),
          ),
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
            children:
                biomes
                    .map(
                      (b) => _BiomeChip(
                        icon: b['icon'] as IconData,
                        label: b['label'] as String,
                        color: b['color'] as Color,
                        small: isSmall,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  // ── Botões Modificados
  Widget _buildButtons(BuildContext context, bool isSmall) {
    return Column(
      children: [
        _MedievalButton(
          label: _carregando ? 'A CARREGAR...' : 'INICIAR NOVO JOGO',
          icon: _carregando ? Icons.hourglass_top : Icons.add_circle_outline,
          primary: true, // Botão primário (vermelho)
          isSmall: isSmall,
          onPressed: _carregando ? null : () => _iniciarNovoJogo(),
        ),
        const SizedBox(height: 14),
        _MedievalButton(
          label: 'CONTINUAR JOGO',
          icon: Icons.bookmark_rounded,
          primary: false, // Botão secundário (escuro)
          isSmall: isSmall,
          // Se tiver um save em andamento e não estiver carregando algo, o botão fica verde/ativo
          onPressed: (_temSave && !_carregando) ? () => _continuarJogo() : null, 
          tooltip: _temSave ? 'Retomar sua jornada de onde parou' : 'Nenhum jogo em andamento encontrado',
        ),
      ],
    );
  }
}

class _MedievalButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final bool isSmall;
  final VoidCallback? onPressed;
  final String? tooltip; 

  static const Color _goldWarm = Color(0xFFBF8A30);
  static const Color _goldLight = Color(0xFFE8C060);
  static const Color _redWax = Color(0xFF7A1C1C);
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

    Widget buttonContent = Container(
      width: double.infinity,
      height: isSmall ? 52 : 58,
      decoration: BoxDecoration(
        color:
            enabled
                ? (primary ? _redWax : const Color(0xFF2E1A0E))
                : const Color(0xFF2A1A0A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color:
              enabled
                  ? (primary ? _goldLight : _goldWarm.withOpacity(0.5))
                  : _goldWarm.withOpacity(0.2),
          width: primary ? 2 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    enabled
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
                  color:
                      enabled
                          ? (primary ? _parchment : _parchment.withOpacity(0.5))
                          : _parchment.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: buttonContent);
    }
    
    return buttonContent;
  }
}

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
            color: const Color(0xFF3D1F00).withOpacity(0.75),
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
    final paint =
        Paint()
          ..color = const Color(0xFFBF8A30).withOpacity(0.03)
          ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}