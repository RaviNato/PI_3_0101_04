import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'bioma.dart';
import 'bioma_data.dart';
import 'npc_data.dart';
import 'models/game_save.dart';
import 'services/save_service.dart';
import 'screens/home_screen.dart'; // Usado para voltar à Home
import 'dart:math' as math;

class CharacterScreen extends StatefulWidget {
  final GameSave initialSave;

  const CharacterScreen({super.key, required this.initialSave});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen>
    with TickerProviderStateMixin {
  
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

  late AnimationController _idleController;
  late Animation<double> _idleBob;

  @override
  void initState() {
    super.initState();

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

  void _iniciarRastreamento() async {
    try {
      await _locationService.determinePosition();
      
      _locationService.startTracking((Position position) {
        setState(() {
          _posicaoAtual = position;
          Bioma? biomaOndeEstou = _locationService.verificarAmbienteAtual(position);
          
          if (biomaOndeEstou != null) {
            int indiceBioma = BiomaData.biomas.indexWhere((b) => b.id == biomaOndeEstou.id);
            if (indiceBioma <= nivelProgresso) {
              _biomaAtual = biomaOndeEstou;
              _mensagemGps = "Explorando: ${_biomaAtual!.name}";
            } else {
              _biomaAtual = null; 
              _mensagemGps = "Caminho bloqueado! Complete a missão de ${BiomaData.biomas[nivelProgresso].name} primeiro."; 
            }
          } else {
            _biomaAtual = null; 
            _mensagemGps = "Fora da área de jogo.";
          }
        });
      });
    } catch (e) {
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

  void _abrirDialogoNPC() {
    if (_biomaAtual == null) return;
    final dialogo = NpcData.dialogos[_biomaAtual!.id];

    if (dialogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O personagem deste local ainda está descansando... "), backgroundColor: Colors.grey),
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
              Expanded(child: Text(dialogo.npcName, style: const TextStyle(color: Colors.amber, fontSize: 18))),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(dialogo.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowDirection: VerticalDirection.down,
          actions: dialogo.choices.map((escolha) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: escolha.isCorrect ? Colors.blue.shade800 : Colors.orange.shade800,
                minimumSize: const Size(double.infinity, 40), 
              ),
              onPressed: () {
                Navigator.pop(context); 
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(escolha.feedback), 
                    backgroundColor: escolha.isCorrect ? Colors.green : Colors.red
                  ),
                );

                if (escolha.isCorrect && escolha.conditionToUnlock != null) {
                  _tentarDesbloqueio(escolha.conditionToUnlock!);
                  finalizarCharada(escolha.conditionToUnlock!); 
                }
              },
              child: Text(escolha.text, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );
      }
    );
  }

  void _tentarDesbloqueio(String condicaoAtendida) {
    setState(() {
      if (condicaoAtendida == 'chama_obtida') {
        nivelProgresso = 5;
        _exibirAnimacaoChama = true; // Ativa o ícone de chama
        return;
      }

      // --- Lógica normal para os biomas (1 ao 4) ---
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
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tem certeza? O vilarejo ainda corre perigo!")),
              );
            },
            child: const Text("Permanecer", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

void finalizarCharada(String condicao) async {
    setState(() {
      switch (condicao) {
        case 'charada_ancia_respondida': // Abre a Geleira
          if (meuSave.flags['falou_com_ancia'] == true) return;
          meuSave.flags['falou_com_ancia'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_02')) meuSave.biomasAbertos.add('bioma_02');
          break;
          
        case 'geleira_concluida': // Abre o Oceano
          if (meuSave.flags['tem_remo'] == true) return;
          meuSave.flags['tem_remo'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_03')) meuSave.biomasAbertos.add('bioma_03');
          break;
          
        case 'dica_pirata_recebida': // Abre o Deserto 
          if (meuSave.flags['falou_com_pirata'] == true) return;
          meuSave.flags['falou_com_pirata'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_04')) meuSave.biomasAbertos.add('bioma_04');
          break;
          
        case 'reliquia_coletada': // Abre o Vulcão 
          if (meuSave.flags['tem_reliquia_fogo'] == true) return;
          meuSave.flags['tem_reliquia_fogo'] = true;
          if (!meuSave.biomasAbertos.contains('bioma_05')) meuSave.biomasAbertos.add('bioma_05');
          break;
          
        case 'chama_obtida': // Aciona o final do jogo
          if (meuSave.flags['tem_chama_magica'] == true) return;
          meuSave.flags['tem_chama_magica'] = true;
          break;
      }
    });

    await _saveService.atualizarSave(meuSave);
  }

  // --- NOVA FUNÇÃO DE VOLTAR E SALVAR ---
  void _voltarParaHome() {
    // Salva o progresso atual antes de voltar
    _salvarProgresso(mostrarSnackbar: false);
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
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
    } else if (nivelProgresso >= BiomaData.biomas.length) {
      biomaAlvo = BiomaData.biomas[0]; 
      nomeDestino = "Retorno a Floresta";
    }

    double distanciaAlvo = 0;
    double anguloSetinha = 0;

    if (_posicaoAtual != null && biomaAlvo != null) {
      distanciaAlvo = Geolocator.distanceBetween(
        _posicaoAtual!.latitude, _posicaoAtual!.longitude,
        biomaAlvo.latitude, biomaAlvo.longitude,
      );

      double bearing = Geolocator.bearingBetween(
        _posicaoAtual!.latitude, _posicaoAtual!.longitude,
        biomaAlvo.latitude, biomaAlvo.longitude,
      );

      double heading = _posicaoAtual!.heading;
      anguloSetinha = (bearing - heading) * (math.pi / 180);
    }

    if (_biomaAtual == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade900,
        extendBodyBehindAppBar: true, 
        // --- BOTÃO DE SAIR NO RADAR ---
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
        // Setinha com distância + Nome do próximo bioma
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
    // A imagem só muda se a chave for ligada pelo botão
    if (_biomaAtual!.id == 'bioma_01' && _chamaColocadaNaTorre) {
      imagemFundo = 'assets/images/floresta_revitalizada.jpg'; 
    }

    int totalBiomas = BiomaData.biomas.length;
    int biomasExplorados = (nivelProgresso + 1).clamp(1, totalBiomas);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      // --- BOTÃO DE SAIR NO TOPO DIREITO DO BIOMA ---
      appBar: AppBar(
        automaticallyImplyLeading: false, // Esconde a setinha padrão se houver
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
            imagemFundo, fit: BoxFit.cover, 
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.blueGrey.shade900, child: const Center(child: Text("Imagem não encontrada", style: TextStyle(color: Colors.white54)))),
          ),
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87], stops: [0.4, 1.0]))),
          
          // Wigdets de Nome e Nível do jogador
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 24, backgroundColor: Colors.black54, child: Icon(Icons.person, color: Colors.white)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Herói: Jorge', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(offset: Offset(1.2, 1.2), color: Colors.black)])),
                              Text('Nível $biomasExplorados', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, shadows: [Shadow(offset: Offset(1.0, 1.0), color: Colors.black)])),
                            ],
                          ),
                        ],
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(nomeDestino, style: const TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Transform.rotate(
                              angle: anguloSetinha, 
                              child: const Icon(
                                Icons.navigation, 
                                color: Colors.amberAccent, 
                                size: 42, 
                                shadows: [
                                  Shadow(blurRadius: 8, color: Colors.black),
                                  Shadow(blurRadius: 12, color: Colors.amber),
                                ]
                              )
                            ),
                            const SizedBox(height: 6),
                            Text('${distanciaAlvo.toInt()}m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Barra de progresso
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Sincronização com a Chama", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text("$biomasExplorados/$totalBiomas Biomas", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: biomasExplorados / totalBiomas, 
                                backgroundColor: Colors.white12, 
                                color: Colors.amber.shade600, 
                                minHeight: 5 
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Finalização do jogo - Coloca a Chama Mágica na torre
                      SizedBox(
                        height: 45,
                        child: (nivelProgresso >= 5 && _biomaAtual!.id == 'bioma_01')
                            ? ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text("Colocar chama mágica na torre", style: TextStyle(fontWeight: FontWeight.bold)),

                                onPressed: () async {
                                // Muda a imagem de fundo para a revitalizada
                                setState(() {
                                  _chamaColocadaNaTorre = true;
                                });

                                // Dá um pequeno delay para o jogador ver a floresta mudando
                                await Future.delayed(const Duration(milliseconds: 600));

                                // Mostra o pop-up de vitória
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
                                          // Marca a vitória no Firebase e chama a função de navegação
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
                                icon: const Icon(Icons.search, size: 20),
                                label: const Text("Explorar o Local", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                onPressed: _abrirDialogoNPC, 
                              ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Aparecimento da chama mágica para coleta
          if (_exibirAnimacaoChama)
            Container(
              color: Colors.black87, // Escurece o fundo para dar destaque
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícone da Chama com Brilho
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orangeAccent,
                      size: 150,
                      shadows: [
                        Shadow(blurRadius: 50, color: Colors.red),
                        Shadow(blurRadius: 100, color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "A CHAMA MÁGICA REVELADA!",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      onPressed: () {
                        setState(() {
                          _exibirAnimacaoChama = false; // Esconde a chama
                          meuSave.flags['chama_coletada'] = true; // Registra no save
                        });
                        _salvarProgresso(mostrarSnackbar: false);
                        _mostrarDialogoFinal(); // Chama o diálogo de voltar para a floresta
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