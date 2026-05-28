import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'bioma.dart';
import 'bioma_data.dart';
import 'npc_data.dart';
import 'models/game_save.dart';
import 'services/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart'; // Usado para voltar à Home
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

class CharacterScreen extends StatefulWidget {
  final GameSave initialSave;

  const CharacterScreen({super.key, required this.initialSave});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final SaveService _saveService = SaveService();
  bool _exibirAnimacaoChama = false;

  Position? _posicaoAtual;
  Bioma? _biomaAtual;
  String _mensagemGps = 'Buscando sinal (GPS)...';

  late GameSave meuSave;
  int nivelProgresso = 0;
  bool _salvando = false;
  bool _chamaColocadaNaTorre = false;
  String _nomeJogador = "";

  // --- VARIÁVEIS DO SISTEMA LIGHT NOVEL PAGINADO ---
  bool _exibindoDialogo = false;
  NpcDialog? _dialogoAtualObjeto;

  List<String> _paginasDialogo = [];
  int _paginaAtualDialogo = 0;

  bool _mostrarOpcoes = false;
  bool _aguardandoFeedback = false;
  bool _respostaCorretaSelecionada = false;
  String? _condicaoDesbloqueioPendente;

  late AnimationController _idleController;
  late Animation<double> _idleBob;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _idBiomaDaMusicaAtual;

  @override
  void initState() {
    super.initState();
    _carregarNome();
    meuSave = widget.initialSave;

    // Lógica para garantir o nível
    nivelProgresso = (meuSave.biomasAbertos.length - 1).clamp(0, BiomaData.biomas.length);
    if (meuSave.flags['tem_chama_magica'] == true) {
      nivelProgresso = 5;
    }

    _sincronizarBiomasComSave();

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _idleBob = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    _iniciarRastreamento();
  }

  void _carregarNome() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nomeJogador = prefs.getString('nome_aventureiro') ?? "Herói";
    });
  }

  void _sincronizarBiomasComSave() {
    for (final bioma in BiomaData.biomas) {
      bioma.isUnlocked = meuSave.biomasAbertos.contains(bioma.id);
    }
  }

  void _gerenciarMusicaDoBioma(Bioma? biomaOndeEstou) async {
    if (biomaOndeEstou == null || !biomaOndeEstou.isUnlocked) return;

    // Se o jogador continua no mesmo bioma, não faz nada (evita reiniciar a música do zero)
    if (_idBiomaDaMusicaAtual == biomaOndeEstou.id) return;

    // Se chegou aqui, significa que o jogador mudou de bioma!
    _idBiomaDaMusicaAtual = biomaOndeEstou.id;

    await _audioPlayer.setVolume(0.0);
    await _audioPlayer.stop(); // Para a música do bioma anterior
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Configura o loop infinito

    // Toca a música correspondente (Ex: audio/musica_bioma_01.mp3)
    String nomeDoArquivo = 'sounds/musica_${biomaOndeEstou.id}.ogg';
    await _audioPlayer.play(AssetSource(nomeDoArquivo));
    await _audioPlayer.setVolume(0.2); // Volume em 60% (escala de 0.0 a 1.0)
  }

  @override
  void dispose() {
    _idleController.dispose();
    _locationService.stopTracking();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _iniciarRastreamento() async {
    try {
      await _locationService.determinePosition();

      _locationService.startTracking((Position position) {
        Bioma? biomaOndeEstou = _locationService.verificarAmbienteAtual(position);
        Bioma? biomaValido;
        String mensagem;

        if (biomaOndeEstou != null) {
          int indiceBioma = BiomaData.biomas.indexWhere((b) => b.id == biomaOndeEstou.id);
          if (indiceBioma <= nivelProgresso) {
            biomaValido = biomaOndeEstou;
            mensagem = "Explorando: ${biomaValido.name}";
          } else {
            biomaValido = null;
            mensagem = "Caminho bloqueado! Complete a missão de ${BiomaData.biomas[nivelProgresso].name} primeiro.";
          }
        } else {
          biomaValido = null;
          mensagem = "Fora da área de jogo.";
        }

        _gerenciarMusicaDoBioma(biomaValido);

        if (!mounted) return;
        setState(() {
          _posicaoAtual = position;
          _biomaAtual = biomaValido;
          _mensagemGps = mensagem;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagemGps = "Erro no Astrolábio: $e";
      });
    }
  }

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

  // --- CONTROLE DE CONCLUSÃO DE DIÁLOGOS ---
  bool _dialogoJaConcluido(String biomaId) {
    switch (biomaId) {
      case 'bioma_01':
        return meuSave.flags['falou_com_ancia'] == true;
      case 'bioma_02':
        return meuSave.flags['tem_remo'] == true;
      case 'bioma_03':
        return meuSave.flags['falou_com_pirata'] == true;
      case 'bioma_04':
        return meuSave.flags['tem_reliquia_fogo'] == true;
      case 'bioma_05':
        return meuSave.flags['tem_chama_magica'] == true;
      default:
        return false;
    }
  }

  // --- MOTOR DE PAGINAÇÃO DE TEXTO ---
  List<String> _dividirTexto(String text, int maxLength) {
    if (text.isEmpty) return [''];
    List<String> chunks = [];
    
    // Respeita quebras de linha duplas feitas no npc_data.dart
    List<String> blocos = text.split('\n\n');

    for (String bloco in blocos) {
      String cleanBloco = bloco.replaceAll('\n', ' ').trim();
      List<String> words = cleanBloco.split(' ');
      String currentChunk = '';

      for (String word in words) {
        if ((currentChunk.length + word.length + 1) > maxLength) {
          if (currentChunk.isNotEmpty) {
            chunks.add(currentChunk.trim());
            currentChunk = '';
          }
        }
        currentChunk += '$word ';
      }
      if (currentChunk.isNotEmpty) {
        chunks.add(currentChunk.trim());
      }
    }
    return chunks.isEmpty ? [text] : chunks;
  }

  void _abrirDialogoNPC() {
    if (_biomaAtual == null) return;

    if (_dialogoJaConcluido(_biomaAtual!.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Você já completou o desafio deste local e obteve o necessário!"),
          backgroundColor: Colors.blueGrey,
        ),
      );
      return;
    }

    final dialogo = NpcData.dialogos[_biomaAtual!.id];
    if (dialogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O personagem deste local ainda está descansando... "), backgroundColor: Colors.grey),
      );
      return;
    }

    setState(() {
      _dialogoAtualObjeto = dialogo;
      _paginasDialogo = _dividirTexto(dialogo.message, 100); // Divide a mensagem inicial
      _paginaAtualDialogo = 0;

      _exibindoDialogo = true;
      _mostrarOpcoes = false; // Começa escondido até o fim do texto
      _aguardandoFeedback = false;
      _respostaCorretaSelecionada = false;
      _condicaoDesbloqueioPendente = null;
    });
  }

  void _avancarCaixaDialogo() {
    if (_mostrarOpcoes) return; // Se está aguardando o clique nos botões, não faz nada.
    setState(() {
      if (_paginaAtualDialogo < _paginasDialogo.length - 1) {
        // Vai para a próxima página de texto
        _paginaAtualDialogo++;
      } else {
        // Acabou o texto da página atual
        if (!_aguardandoFeedback) {
          // Terminou de ler a pergunta/história -> Mostra opções
          _mostrarOpcoes = true;
        } else {
          // Terminou de ler o feedback da resposta
          if (_respostaCorretaSelecionada) {
            _exibindoDialogo = false; // Fecha a janela
            if (_condicaoDesbloqueioPendente != null) {
              _tentarDesbloqueio(_condicaoDesbloqueioPendente!);
              finalizarCharada(_condicaoDesbloqueioPendente!);
            }
          } else {
            // Se errou a charada, recarrega a pergunta inicial
            _paginasDialogo = _dividirTexto(_dialogoAtualObjeto!.message, 150);
            _paginaAtualDialogo = 0;
            _aguardandoFeedback = false;
          }
        }
      }
    });
  }

  void _tentarDesbloqueio(String condicaoAtendida) {
    setState(() {
      if (condicaoAtendida == 'chama_obtida') {
        nivelProgresso = 5;
        _exibirAnimacaoChama = true; // Ativa o ícone de chama
        return;
      }

      // Lógica normal para os biomas
      for (var bioma in BiomaData.biomas) {
        if (!bioma.isUnlocked) {
          if (bioma.unlockBiome(condicaoAtendida)) {
            nivelProgresso++;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Novo caminho revelado: ${bioma.name}"), backgroundColor: Colors.green.shade700),
            );
          }
          break;
        }
      }
    });
  }

  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.brown.shade900,
        title: const Text("MISSÃO CUMPRIDA!", style: TextStyle(color: Colors.amber)),
        content: const Text(
          "Parabéns, você conseguiu seu item valioso!\n\nAgora leve a Chama Mágica até a Floresta e restaure a paz do vilarejo!",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Voltar ao Bioma", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void finalizarCharada(String condicao) async {
    setState(() {
      switch (condicao) {
        case 'charada_ancia_respondida':
          if (meuSave.flags['falou_com_ancia'] == true) return;
          meuSave.flags['falou_com_ancia'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_02')) meuSave.biomasAbertos.add('bioma_02');
          break;

        case 'geleira_concluida':
          if (meuSave.flags['tem_remo'] == true) return;
          meuSave.flags['tem_remo'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_03')) meuSave.biomasAbertos.add('bioma_03');
          break;

        case 'falou_com_pirata':
          if (meuSave.flags['falou_com_pirata'] == true) return;
          meuSave.flags['falou_com_pirata'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_04')) meuSave.biomasAbertos.add('bioma_04');
          break;

        case 'reliquia_coletada':
          if (meuSave.flags['tem_reliquia_fogo'] == true) return;
          meuSave.flags['tem_reliquia_fogo'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_05')) meuSave.biomasAbertos.add('bioma_05');
          break;

        case 'chama_obtida':
          if (meuSave.flags['tem_chama_magica'] == true) return;
          meuSave.flags['tem_chama_magica'] = true;
          break;
      }
    });

    await _saveService.atualizarSave(meuSave);
  }

  void _voltarParaHome() async {
    await _audioPlayer.stop();
    _salvarProgresso(mostrarSnackbar: false);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  // --- RENDERIZA O SPRITE DO NPC ---
  Widget _buildNpcSpriteStyleLightNovel() {
    if (!_exibindoDialogo || _biomaAtual == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 60, // AJUSTE: Desceu para colar na caixa de diálogo
      right: -10,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.52,
        constraints: const BoxConstraints(maxWidth: 280),
        child: Opacity(
          opacity: 0.95,
          child: Image.asset(
            'assets/images/npc_${_biomaAtual!.id}.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Container(
                  width: 200,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade800.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.amber, size: 100),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- RENDERIZA A CAIXA DE DIÁLOGO E PAGINAÇÃO ---
  Widget _buildCaixaDialogoLightNovel() {
    if (_dialogoAtualObjeto == null || _paginasDialogo.isEmpty) return const SizedBox.shrink();

    bool temMaisTexto = _paginaAtualDialogo < _paginasDialogo.length - 1;
    String textoExibido = _paginasDialogo[_paginaAtualDialogo];

    return GestureDetector(
      onTap: _avancarCaixaDialogo, // Avança a página ou fecha o diálogo
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade700.withOpacity(0.7), width: 2),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _dialogoAtualObjeto!.npcName,
              style: const TextStyle(color: Colors.amber, fontSize: 17, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
            ),
            
            // Controle de Exibição
            if (_mostrarOpcoes) ...[
              // AJUSTE: Removeu o texto em cima quando mostra opções
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.38, // Ocupa no máximo 38% da altura da tela
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: _dialogoAtualObjeto!.choices.map((choice) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade900.withOpacity(0.9),
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.amber.shade700, width: 1.5),
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            // Ao clicar na opção, o feedback vira a nova sequência de páginas
                            setState(() {
                              _mostrarOpcoes = false;
                              _aguardandoFeedback = true;
                              _respostaCorretaSelecionada = choice.isCorrect;
                              _condicaoDesbloqueioPendente = choice.conditionToUnlock;

                              _paginasDialogo = _dividirTexto(choice.feedback, 150);
                              _paginaAtualDialogo = 0;
                            });
                          },
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(choice.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              // Texto fracionado
              Text(
                textoExibido,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: temMaisTexto
                    ? const Icon(Icons.arrow_drop_down, color: Colors.amber, size: 24) // Indicador de "tem mais texto"
                    : Text(
                        _aguardandoFeedback
                            ? (_respostaCorretaSelecionada ? "Toque para continuar ▶" : "Toque para tentar novamente ↩")
                            : "Toque para ver opções ▶",
                        style: TextStyle(
                            color: _aguardandoFeedback
                                ? (_respostaCorretaSelecionada ? Colors.green.shade300 : Colors.orange.shade300)
                                : Colors.white54,
                            fontSize: 11,
                            fontStyle: FontStyle.italic),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Bioma? biomaAlvo;
    String nomeDestino = 'Destino';
    if (nivelProgresso < BiomaData.biomas.length) {
      biomaAlvo = BiomaData.biomas[nivelProgresso];
      nomeDestino = biomaAlvo.name;
    } else {
      biomaAlvo = BiomaData.biomas[0];
      nomeDestino = "Retorno a Floresta";
    }

    double distanciaAlvo = 0;
    double anguloSetinha = 0;

    if (_posicaoAtual != null && biomaAlvo != null) {
      distanciaAlvo = Geolocator.distanceBetween(
        _posicaoAtual!.latitude,
        _posicaoAtual!.longitude,
        biomaAlvo.latitude,
        biomaAlvo.longitude,
      );

      double bearing = Geolocator.bearingBetween(
        _posicaoAtual!.latitude,
        _posicaoAtual!.longitude,
        biomaAlvo.latitude,
        biomaAlvo.longitude,
      );

      double heading = _posicaoAtual!.heading;
      anguloSetinha = (bearing - heading) * (math.pi / 180);
    }

    if (_biomaAtual == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade900,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.exit_to_app, color: Colors.white70),
              label: const Text("Sair", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              onPressed: _voltarParaHome,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (biomaAlvo != null) ...[
                  Text(
                    "Siga para: $nomeDestino",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                  ),
                  const SizedBox(height: 32),
                  Transform.rotate(angle: anguloSetinha, child: const Icon(Icons.navigation, size: 120, color: Colors.blueAccent)),
                  const SizedBox(height: 24),
                  Text("${distanciaAlvo.toInt()} metros", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Caminhe na direção da seta para entrar no bioma", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14)),
                ] else ...[
                  const Icon(Icons.location_off, size: 100, color: Colors.white24),
                  const SizedBox(height: 24),
                  Text(_mensagemGps, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        ),
      );
    }

    String imagemFundo = _biomaAtual!.assetImagePath;
    if (_biomaAtual!.id == 'bioma_01' && meuSave.flags['tem_chama_magica'] == true) {
      if (_chamaColocadaNaTorre) {
        imagemFundo = 'assets/images/floresta_revitalizada.jpg';
      } else {
        imagemFundo = 'assets/images/floresta_ruim.jpg';
      }
    }

    int totalBiomas = BiomaData.biomas.length;
    int biomasExplorados = (nivelProgresso + 1).clamp(1, totalBiomas);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_biomaAtual!.name, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white, shadows: [Shadow(offset: Offset(-1.5, -1.5), color: Colors.black), Shadow(offset: Offset(1.5, 1.5), color: Colors.black)])),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.exit_to_app, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
            label: const Text("Sair", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
            onPressed: _voltarParaHome,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagemFundo,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.blueGrey.shade900, child: const Center(child: Text("Imagem não encontrada", style: TextStyle(color: Colors.white54)))),
          ),
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87], stops: [0.4, 1.0]))),
          
          if (_exibindoDialogo)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                      Colors.black87,
                      Colors.black,
                    ],
                    stops: [0.5, 0.65, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            
          _buildNpcSpriteStyleLightNovel(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- TOPO DA TELA (Informações do Herói e Radar) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Ícone do Herói
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                              border: Border.all(color: Colors.amber.shade600, width: 1.5),
                            ),
                            child: const Icon(Icons.shield, color: Colors.amberAccent, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aventureiro(a): $_nomeJogador', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, shadows: [Shadow(offset: Offset(1.2, 1.2), color: Colors.black)])),
                              Text('Nível $biomasExplorados', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, shadows: [Shadow(offset: Offset(1.0, 1.0), color: Colors.black)])),
                            ],
                          ),
                        ],
                      ),
                      
                      // Bússola
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(nomeDestino, style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Transform.rotate(
                                angle: anguloSetinha,
                                child: const Icon(Icons.navigation, color: Colors.amberAccent, size: 32, shadows: [Shadow(blurRadius: 6, color: Colors.black)])),
                            const SizedBox(height: 4),
                            Text('${distanciaAlvo.toInt()}m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // --- PARTE INFERIOR DA TELA (Explorar vs Dialogando) ---
                  // Uso do Flexible para que a caixa de diálogo ou os botões se adaptem ao celular
                  Flexible(
                    child: _exibindoDialogo
                        ? _buildCaixaDialogoLightNovel()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Barra de Objetivo / Progresso
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Objetivo", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                        Text("$biomasExplorados/$totalBiomas Biomas", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(value: biomasExplorados / totalBiomas, backgroundColor: Colors.white12, color: Colors.amber.shade600, minHeight: 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Botão de Ação (Explorar / Depositar Chama)
                              SizedBox(
                                height: 40,
                                child: (nivelProgresso >= 5 && _biomaAtual!.id == 'bioma_01')
                                    ? ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        icon: const Icon(Icons.auto_awesome, size: 18),
                                        label: const Text("Colocar chama mágica na torre", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          setState(() {
                                            _chamaColocadaNaTorre = true;
                                          });

                                          await Future.delayed(const Duration(milliseconds: 600));

                                          if (!context.mounted) return;
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: Colors.brown.shade900,
                                              title: const Text("MISSÃO CUMPRIDA!", style: TextStyle(color: Colors.amber)),
                                              content: const Text(
                                                "Uma onda de luz se espalha! O Vilarejo e a Floresta foram salvos dos monstros. A paz finalmente retornou!",
                                                style: TextStyle(color: Colors.white),
                                              ),
                                              actions: [
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                  onPressed: () {
                                                    setState(() => meuSave.flags['venceu_jogo'] = true);
                                                    _voltarParaHome();
                                                  },
                                                  child: const Text("FINALIZAR JORNADA", style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber.shade700,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        icon: const Icon(Icons.search, size: 18),
                                        label: const Text("Explorar o Local", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        onPressed: _abrirDialogoNPC,
                                      ),
                              )
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // Animação de Coleta da Chama Mágica
          if (_exibirAnimacaoChama)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orangeAccent,
                      size: 120,
                      shadows: [Shadow(blurRadius: 50, color: Colors.red), Shadow(blurRadius: 100, color: Colors.orange)],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "A CHAMA MÁGICA REVELADA!",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _exibirAnimacaoChama = false;
                          meuSave.flags['chama_coletada'] = true;
                        });
                        _salvarProgresso(mostrarSnackbar: false);
                        _mostrarDialogoFinal();
                      },
                      child: const Text("COLETAR CHAMA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}