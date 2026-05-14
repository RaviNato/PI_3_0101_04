import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../location_service.dart';
import '../bioma.dart';
import '../bioma_data.dart';
import '../npc_data.dart';
import '../models/game_save.dart';
import '../services/save_service.dart';
import '../widgets/jorge_painter.dart';

class CharacterScreen extends StatefulWidget {
  /// Save recebido da HomeScreen após carregamento no Firebase.
  final GameSave initialSave;

  const CharacterScreen({super.key, required this.initialSave});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen>
    with TickerProviderStateMixin {
  // ── Serviços
  final LocationService _locationService = LocationService();
  final SaveService _saveService = SaveService();

  // ── Estado de localização
  Position? _posicaoAtual;
  Bioma? _biomaAtual;
  String _mensagemGps = 'Buscando sinal (GPS)...';

  // ── Estado de progresso
  late GameSave meuSave;
  int nivelProgresso = 0;

  // ── Controle de salvamento
  bool _salvando = false;

  // ─Animação idle do Jorge
  late AnimationController _idleController;
  late Animation<double> _idleBob;

  @override
  void initState() {
    super.initState();

    // Inicializa o estado local com o save carregado do Firebase.
    meuSave = widget.initialSave;
    nivelProgresso =
        (meuSave.biomasAbertos.length - 1).clamp(0, BiomaData.biomas.length - 1);
    _sincronizarBiomasComSave();

    // Animação de balanço do personagem (idle)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _idleBob = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    _iniciarRastreamento();
  }

  void _sincronizarBiomasComSave() {
    for (final bioma in BiomaData.biomas) {
      if (meuSave.biomasAbertos.contains(bioma.id)) {
        bioma.isUnlocked = true;
      }
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _locationService.stopTracking();
    super.dispose();
  }

  // GPS
  void _iniciarRastreamento() async {
    try {
      await _locationService.determinePosition();

      _locationService.startTracking((Position position) {
        setState(() {
          _posicaoAtual = position;

          final Bioma? biomaOndeEstou =
              _locationService.verificarAmbienteAtual(position);

          if (biomaOndeEstou != null) {
            final int indiceBioma =
                BiomaData.biomas.indexWhere((b) => b.id == biomaOndeEstou.id);

            if (indiceBioma <= nivelProgresso) {
              _biomaAtual = biomaOndeEstou;
              _mensagemGps = 'Explorando: ${_biomaAtual!.name}';
            } else {
              _biomaAtual = null;
              _mensagemGps =
                  'Caminho bloqueado! Complete a missão de '
                  '${BiomaData.biomas[nivelProgresso].name} primeiro.';
            }
          } else {
            _biomaAtual = null;
            _mensagemGps = 'Fora da área de jogo.';
          }
        });
      });
    } catch (e) {
      setState(() => _mensagemGps = 'Erro no Astrolábio: $e');
    }
  }

  // Persistência

  Future<void> _salvarProgresso({bool mostrarSnackbar = true}) async {
    if (_salvando) return;
    setState(() => _salvando = true);

    try {
      final GameSave saveAtualizado = GameSave(
        biomaAtual: _biomaAtual?.id ?? meuSave.biomaAtual,
        etapa: nivelProgresso,
        flags: Map<String, bool>.from(meuSave.flags),
        biomasAbertos: List<String>.from(meuSave.biomasAbertos),
      );

      await _saveService.atualizarSave(saveAtualizado);
      meuSave = saveAtualizado;

      if (mostrarSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progresso salvo com sucesso! 💾'),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // Diálogo NPC
  void _abrirDialogoNPC() {
    if (_biomaAtual == null) return;

    final dialogo = NpcData.dialogos[_biomaAtual!.id];

    if (dialogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O personagem deste local ainda está descansando...'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.brown.shade900,
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dialogo.npcName,
                  style: const TextStyle(color: Colors.amber, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              dialogo.message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowDirection: VerticalDirection.down,
          actions: dialogo.choices.map((escolha) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: escolha.isCorrect
                    ? Colors.blue.shade800
                    : Colors.orange.shade800,
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(escolha.feedback),
                    backgroundColor:
                        escolha.isCorrect ? Colors.green : Colors.red,
                  ),
                );
                if (escolha.isCorrect && escolha.conditionToUnlock != null) {
                  _tentarDesbloqueio(escolha.conditionToUnlock!);
                  finalizarCharada(escolha.conditionToUnlock ?? '');
                }
              },
              child: Text(
                escolha.text,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Desbloqueio
  void _tentarDesbloqueio(String condicaoAtendida) {
    setState(() {
      for (final bioma in BiomaData.biomas) {
        if (!bioma.isUnlocked) {
          final bool sucesso = bioma.unlockBiome(condicaoAtendida);
          if (sucesso) {
            nivelProgresso++;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Novo caminho revelado: ${bioma.name} desbloqueado!'),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
            // Auto-save após desbloqueio
            _salvarProgresso(mostrarSnackbar: false);
          }
          break;
        }
      }
    });
  }

  void finalizarCharada(String condicao) async {
    setState(() {
      switch (condicao) {
        case 'charada_ancia_respondida':
          if (meuSave.flags['falou_com_ancia'] == true) return;
          meuSave.flags['falou_com_ancia'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_02')) {
            meuSave.biomasAbertos.add('bioma_02');
          }
          break;
        case 'charada_geleira_resolvida':
          if (meuSave.flags['tem_remo'] == true) return;
          meuSave.flags['tem_remo'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_03')) {
            meuSave.biomasAbertos.add('bioma_03');
          }
          break;
        case 'conversa_pirata_concluida':
          if (meuSave.flags['falou_com_pirata'] == true) return;
          meuSave.flags['falou_com_pirata'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_04')) {
            meuSave.biomasAbertos.add('bioma_04');
          }
          break;
        case 'charada_mumia_resolvida':
          if (meuSave.flags['tem_reliquia_fogo'] == true) return;
          meuSave.flags['tem_reliquia_fogo'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_05')) {
            meuSave.biomasAbertos.add('bioma_05');
          }
          break;
        case 'charada_vulcao_resolvida':
          if (meuSave.flags['tem_chama_magica'] == true) return;
          meuSave.flags['tem_chama_magica'] = true;
          break;
        case 'torre_reascendida':
          meuSave.flags['venceu_jogo'] = true;
          break;
      }
    });

    await _saveService.atualizarSave(meuSave);
  }

  // Build
  @override
  Widget build(BuildContext context) {
    if (_biomaAtual == null) {
      return _buildTelaFora();
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _biomaAtual!.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
            shadows: [
              Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
              Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
              Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
              Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _salvando
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Salvar progresso',
                      icon: const Icon(Icons.save, color: Colors.white),
                      onPressed: () => _salvarProgresso(mostrarSnackbar: true),
                    ),
            ),
          ),
        ],
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fundo do bioma
          Image.asset(
            _biomaAtual!.assetImagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.blueGrey.shade900,
              child: const Center(
                child: Text('Imagem não encontrada',
                    style: TextStyle(color: Colors.white54)),
              ),
            ),
          ),

          // 2. Gradiente para legibilidade
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.4, 1.0],
              ),
            ),
          ),

          // 3. Jorge animado no centro da tela
          _buildJorge(size),

          // 4. Interface (header + HUD)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeroHeader(),
                  _buildBottomHUD(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJorge(Size size) {
    final double charWidth  = size.width * 0.18;
    final double charHeight = charWidth * 1.6;

    return Positioned(
      left: size.width / 2 - charWidth / 2,
      bottom: size.height * 0.28,
      child: AnimatedBuilder(
        animation: _idleBob,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _idleBob.value),
          child: SizedBox(
            width: charWidth,
            height: charHeight,
            child: const CustomPaint(
              painter: JorgePainter(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelaFora() {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 100, color: Colors.white24),
              const SizedBox(height: 24),
              Text(
                _mensagemGps,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              if (_posicaoAtual != null)
                Text(
                  'Lat: ${_posicaoAtual!.latitude.toStringAsFixed(4)}\n'
                  'Lng: ${_posicaoAtual!.longitude.toStringAsFixed(4)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.amber, fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Colors.black54,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Herói: Jorge',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                  Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                  Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                  Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                ],
              ),
            ),
            Text(
              'Nível 1',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(offset: Offset(-1.2, -1.2), color: Colors.black),
                  Shadow(offset: Offset(1.2, -1.2), color: Colors.black),
                  Shadow(offset: Offset(1.2, 1.2), color: Colors.black),
                  Shadow(offset: Offset(-1.2, 1.2), color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomHUD() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatBar(
                        label: 'HP',
                        value: 100,
                        maxValue: 100,
                        color: Colors.red),
                    SizedBox(height: 8),
                    StatBar(
                        label: 'SP',
                        value: 45,
                        maxValue: 100,
                        color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Icon(Icons.explore, color: Colors.amber, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      '${_posicaoAtual!.heading.toStringAsFixed(0)}°',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.search),
          label: const Text(
            'Explorar o Local',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _abrirDialogoNPC,
        ),
      ],
    );
  }
}

class StatBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value / maxValue,
            backgroundColor: Colors.black,
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}