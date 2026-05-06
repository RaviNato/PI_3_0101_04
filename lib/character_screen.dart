import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'bioma.dart';     
import 'bioma_data.dart';
import 'npc_data.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  // 1. Variáveis de Serviço e Estado
  final LocationService _locationService = LocationService();
  Position? _posicaoAtual;
  Bioma? _biomaAtual;
  String _mensagemGps = "Buscando sinal das estrelas (GPS)...";
  
  // Controle de progressão do jogador (0 = Início, 1 = Passou do 1º bioma, etc.)
  int nivelProgresso = 0; 

  @override
  void initState() {
    super.initState();
    // Inicia a escuta do GPS assim que a tela abre
    _iniciarRastreamento();
  }

  void _iniciarRastreamento() async {
    try {
      // Pede permissão e liga o GPS
      await _locationService.determinePosition();
      
      // Começa a receber a posição a cada passo do jogador
      _locationService.startTracking((Position position) {
        setState(() {
          _posicaoAtual = position;
          
          // Verifica em qual área do Campus o jogador pisou
          Bioma? biomaOndeEstou = _locationService.verificarAmbienteAtual(position);
          
          if (biomaOndeEstou != null) {
            // Buscamos o índice usando o ID único do bioma
            int indiceBioma = BiomaData.biomas.indexWhere((b) => b.id == biomaOndeEstou.id);
            
            if (indiceBioma <= nivelProgresso) {
              _biomaAtual = biomaOndeEstou;
              _mensagemGps = "Explorando: ${_biomaAtual!.name}"; // Era .nome
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

  @override
  void dispose() {
    // Desliga o GPS para poupar bateria ao fechar o app
    _locationService.stopTracking();
    super.dispose();
  }

  void _abrirDialogoNPC() {
    // o molde confirma quais botões serão necessários para cada ambiente
    final dialogo = NpcData.dialogos[_biomaAtual!.id];

    // Se o colega ainda não programou o NPC desse bioma, avisa que está em construção
    if (dialogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O personagem deste local ainda está descansando... "), backgroundColor: Colors.grey),
      );
      return;
    }

    // O molde desenha a tela de acordo com os botões descritos
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
          // 3. O molde cria um botão para cada escolha que o colega cadastrou na lista
          actions: dialogo.choices.map((escolha) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Se for a resposta certa, pinta de azul. Se for errada, laranja.
                backgroundColor: escolha.isCorrect ? Colors.blue.shade800 : Colors.orange.shade800,
                minimumSize: const Size(double.infinity, 40), 
              ),
              onPressed: () {
                Navigator.pop(context); // Fecha o balão de diálogo
                
                // Mostra o feedback do NPC
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(escolha.feedback), 
                    backgroundColor: escolha.isCorrect ? Colors.green : Colors.red
                  ),
                );

                // Se o jogador acertou e tem algo para desbloquear, chama a sua função de desbloqueio
                if (escolha.isCorrect && escolha.conditionToUnlock != null) {
                  _tentarDesbloqueio(escolha.conditionToUnlock!);
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
      // Procura o próximo bioma que ainda está bloqueado
      for (var bioma in BiomaData.biomas) {
        if (!bioma.isUnlocked) {
          //vinculação de sucesso à mudança de estado
          bool sucesso = bioma.unlockBiome(condicaoAtendida);
          
          if (sucesso) {
            nivelProgresso++; // Mantém o GPS sincronizado com o progresso
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Novo caminho revelado: ${bioma.name} desbloqueado!"), 
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          break; // Só tenta desbloquear o próximo bioma
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_biomaAtual == null) {
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
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                if (_posicaoAtual != null)
                  Text(
                    "Lat: ${_posicaoAtual!.latitude.toStringAsFixed(4)}\nLng: ${_posicaoAtual!.longitude.toStringAsFixed(4)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.amber, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // TELA PRINCIPAL COM A IMAGEM DE FUNDO
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(
          _biomaAtual!.name, 
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            letterSpacing: 2, 
            color: Colors.white,
            //adicionando sombras para as letras se destacarem na tela
            shadows: [
              Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
              Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
              Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
              Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
            ],
          )
        ),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. O Fundo do Bioma (Sua imagem png)
          Image.asset(
            _biomaAtual!.assetImagePath,
            fit: BoxFit.cover, 
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.blueGrey.shade900,
              child: const Center(child: Text("Imagem não encontrada", style: TextStyle(color: Colors.white54))),
            ),
          ),

          // 2. Escurecimento para leitura
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.5, 1.0], 
              ),
            ),
          ),

          // 3. A Interface Discreta
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Herói: Jorge', 
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              // Contorno
                              shadows: [
                                Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                                Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                                Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                                Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                              ],
                            )
                          ),
                          Text(
                            'Nível 1', 
                            style: TextStyle(
                              color: Colors.amber, 
                              fontSize: 12,
                              fontWeight: FontWeight.bold, // Deixei em negrito pra ajudar
                              // Contorno
                              shadows: [
                                Shadow(offset: Offset(-1.2, -1.2), color: Colors.black),
                                Shadow(offset: Offset(1.2, -1.2), color: Colors.black),
                                Shadow(offset: Offset(1.2, 1.2), color: Colors.black),
                                Shadow(offset: Offset(-1.2, 1.2), color: Colors.black),
                              ],
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  StatBar(label: 'HP', value: 100, maxValue: 100, color: Colors.red),
                                  SizedBox(height: 8),
                                  StatBar(label: 'SP', value: 45, maxValue: 100, color: Colors.green),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  const Icon(Icons.explore, color: Colors.amber, size: 28),
                                  const SizedBox(height: 4),
                                  Text('${_posicaoAtual!.heading.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        icon: const Icon(Icons.search),
                        label: const Text("Explorar o Local", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _abrirDialogoNPC, 
                      )
                    ],
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

class StatBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const StatBar({super.key, required this.label, required this.value, required this.maxValue, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 24, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
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