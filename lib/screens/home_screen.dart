import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'character_screen.dart';
import '../services/save_service.dart';
import '../models/game_save.dart';

// Definindo os estados possíveis do jogo
enum GameStatus { none, playing, finished }

/// HomeScreen — Tela inicial do Omnizona
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  bool _carregando = false;
  
  GameStatus _statusJogo = GameStatus.none;
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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeIn = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.7, curve: Curves.easeIn));
    _slideUp = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _animController.forward();

    _verificarSaveExistente();
  }

  Future<void> _verificarSaveExistente() async {
    try {
      _saveCarregado = await SaveService().carregarOuCriarSave();
      
      if (mounted && _saveCarregado != null) {
        setState(() {
          // 1. O Jogo já foi zerado?
          if (_saveCarregado!.flags['venceu_jogo'] == true) {
            _statusJogo = GameStatus.finished;
          } 
          // 2. O Jogo começou e está em andamento?
          else if (_saveCarregado!.etapa > 0 || _saveCarregado!.biomasAbertos.length > 1 || _saveCarregado!.flags.isNotEmpty) {
            _statusJogo = GameStatus.playing;
          } 
          // 3. Save virgem (ainda não fez nada)
          else {
            _statusJogo = GameStatus.none;
          }
        });
      }
    } catch (e) {
      // Se der erro, continua como nulo
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // --- POP-UP ESTILIZADO PARA PEDIR O NOME ---
  Future<String?> _pedirNomeJogador() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.brown.shade900,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: Colors.amber),
              SizedBox(width: 10),
              Text("Novo Herói", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Como você deseja ser chamado nesta jornada?", style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                cursorColor: Colors.amber,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black45,
                  hintText: "Digite seu nome...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text("Iniciar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  // ── Lógica de Novo Jogo Otimizada
  Future<void> _iniciarNovoJogo() async {
    if (_carregando) return;

    // AVISOS ANTES DE APAGAR O JOGO
    if (_statusJogo == GameStatus.playing) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2E1A0E),
          title: const Text('Iniciar Nova Jornada?', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: const Text('Isso apagará o seu progresso atual e você perderá todos os itens conquistados. Deseja mesmo começar do zero?', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800), onPressed: () => Navigator.pop(context, true), child: const Text('Sim, apagar progresso', style: TextStyle(color: Colors.white))),
          ],
        ),
      );
      if (confirmar != true) return; 
    } else if (_statusJogo == GameStatus.finished) {
       final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2E1A0E),
          title: const Text('Jogar Novamente?', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: const Text('Você já salvou o vilarejo! Deseja apagar o histórico de vitória e vivenciar a jornada desde o início?', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800), onPressed: () => Navigator.pop(context, true), child: const Text('Sim, recomeçar!', style: TextStyle(color: Colors.white))),
          ],
        ),
      );
      if (confirmar != true) return; 
    }

    // PEDE O NOME DO JOGADOR
    String? nomeJogador = await _pedirNomeJogador();
    if (nomeJogador == null || nomeJogador.isEmpty) return; // Se cancelou ou não digitou, não faz nada

    setState(() => _carregando = true);

    try {
      // Salva o nome na memória do celular usando o novo pacote
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nome_aventureiro', nomeJogador);

      // Cria um save 100% zerado
      final GameSave saveZerado = GameSave(
        biomaAtual: 'bioma_01',
        etapa: 0,
        flags: {},
        biomasAbertos: ['bioma_01'],
      );

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar novo jogo: $e'), backgroundColor: Colors.red.shade800));
      setState(() => _carregando = false);
    }
  }

  // ── Lógica de Continuar Jogo
  Future<void> _continuarJogo() async {
    if (_carregando || _saveCarregado == null) return;
    setState(() => _carregando = true);

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
                        padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 32),
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
      width: size.width, height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C1008), Color(0xFF2E1A0E), Color(0xFF1C1008)]),
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
    return Container(width: 50, height: 1.5, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _goldWarm, Colors.transparent])));
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _goldWarm.withOpacity(0.6)])))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.circle, color: _goldWarm, size: 6)),
        Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [_goldWarm.withOpacity(0.6), Colors.transparent])))),
      ],
    );
  }

  Widget _buildBottomOrnament() {
    return Column(
      children: [
        _buildDivider(),
        const SizedBox(height: 10),
        Text('PUC-Campinas · Projeto Integrador III · 2026', style: TextStyle(fontSize: 10, color: _parchmentDark.withOpacity(0.4), letterSpacing: 1)),
      ],
    );
  }

  Widget _buildTitle(bool isSmall) {
    return Column(
      children: [
        Text(
          'OMNIZONA',
          style: TextStyle(
            fontSize: isSmall ? 38 : 50, fontWeight: FontWeight.w900, letterSpacing: 8, color: _parchment,
            shadows: [Shadow(color: _goldWarm.withOpacity(0.8), blurRadius: 12), const Shadow(color: _inkBrown, blurRadius: 2, offset: Offset(2, 2))],
          ),
        ),
        const SizedBox(height: 4),
        const Text('— JOGO DE RPG —', style: TextStyle(fontSize: 13, letterSpacing: 5, color: _goldWarm, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSubtitle(bool isSmall) {
    return Text(
      '"Ressignifique sua vivência acadêmica\natravés de uma jornada épica"',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: isSmall ? 13 : 14, color: _parchmentDark.withOpacity(0.8), fontStyle: FontStyle.italic, height: 1.6, letterSpacing: 0.5),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text('OS CINCO BIOMAS', style: TextStyle(fontSize: 12, letterSpacing: 4, color: _inkBrown.withOpacity(0.7), fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Divider(color: _inkBrown.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: biomes.map((b) => _BiomeChip(icon: b['icon'] as IconData, label: b['label'] as String, color: b['color'] as Color, small: isSmall)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, bool isSmall) {
    return Column(
      children: [
        _MedievalButton(
          label: _carregando ? 'A CARREGAR...' : 'INICIAR NOVO JOGO',
          icon: _carregando ? Icons.hourglass_top : Icons.add_circle_outline,
          primary: true, 
          isSmall: isSmall,
          onPressed: _carregando ? null : () => _iniciarNovoJogo(),
        ),
        const SizedBox(height: 14),
        _MedievalButton(
          label: 'CONTINUAR JOGO',
          icon: Icons.bookmark_rounded,
          primary: false, 
          isSmall: isSmall,
          // Agora o botão fica clicável sempre, mas só avança se tiver jogo salvo.
          // Se não tiver, ele exibe um aviso claro para o jogador!
          onPressed: _carregando ? null : () {
            if (_statusJogo == GameStatus.none) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Você ainda não começou uma jornada!"), backgroundColor: Colors.orange));
            } else if (_statusJogo == GameStatus.finished) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jornada finalizada! Inicie um Novo Jogo para recomeçar."), backgroundColor: Colors.blue));
            } else {
              _continuarJogo();
            }
          }, 
          tooltip: 'Retomar sua jornada de onde parou',
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

  const _MedievalButton({required this.label, required this.icon, required this.primary, required this.isSmall, required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    Widget buttonContent = Container(
      width: double.infinity, height: isSmall ? 52 : 58,
      decoration: BoxDecoration(
        color: enabled ? (primary ? _redWax : const Color(0xFF2E1A0E)) : const Color(0xFF2A1A0A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: enabled ? (primary ? _goldLight : _goldWarm.withOpacity(0.5)) : _goldWarm.withOpacity(0.2), width: primary ? 2 : 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: enabled ? (primary ? _goldLight : _goldWarm.withOpacity(0.6)) : _goldWarm.withOpacity(0.2)),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: isSmall ? 13 : 15, fontWeight: FontWeight.bold, letterSpacing: 3, color: enabled ? (primary ? _parchment : _parchment.withOpacity(0.5)) : _parchment.withOpacity(0.2))),
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

  const _BiomeChip({required this.icon, required this.label, required this.color, required this.small});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: small ? 38 : 44, height: small ? 38 : 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15), border: Border.all(color: color.withOpacity(0.7), width: 1.5)),
          child: Icon(icon, color: color, size: small ? 18 : 22),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: small ? 9 : 10, color: const Color(0xFF3D1F00).withOpacity(0.75), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFBF8A30).withOpacity(0.03)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 4), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}