import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'bioma.dart';     
import 'bioma_data.dart';

// Nota: Certifique-se de importar o arquivo onde você criou a classe Bioma e a lista ambientesPuc.
// Se você colocou a lista no próprio location_service.dart, não precisa desse import extra abaixo.
// import 'bioma_model.dart'; 

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

  @override
  Widget build(BuildContext context) {
    // =========================================================================
    // TELA 1: JOGADOR FORA DO BIOMA OU BLOQUEADO(TELA CINZA)
    // =========================================================================
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
                const SizedBox(height: 16),
                const Text(
                  "Siga para o próximo marcador de missão no mapa para continuar sua jornada.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
                const SizedBox(height: 32),
                // Mostra as coordenadas atuais mesmo bloqueado, para ajudar você a debugar
                if (_posicaoAtual != null)
                  Text(
                    "Sua posição atual:\nLat: ${_posicaoAtual!.latitude.toStringAsFixed(4)}\nLng: ${_posicaoAtual!.longitude.toStringAsFixed(4)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.amber, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // =========================================================================
    // TELA 2: JOGADOR DENTRO DO BIOMA LIBERADO (TELA PRINCIPAL DO RPG)
    // =========================================================================
    return Scaffold(
      backgroundColor: Colors.black,
        appBar: AppBar(
        title: Text(_biomaAtual!.name), // Era _biomaAtual!.nome
        backgroundColor: Colors.brown.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Card 1: Avatar do Aventureiro ---
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.brown.shade900,
                      child: const Icon(Icons.person, size: 60, color: Colors.white70), 
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Herói Desconhecido',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text('Classe: Explorador', style: TextStyle(color: Colors.white70)),
                        Text('Nível: 1', style: TextStyle(color: Colors.amber)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Card 2: Status Base ---
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Text('Atributos Físicos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Divider(color: Colors.white24),
                    StatBar(label: 'HP', value: 100, maxValue: 100, color: Colors.red),
                    StatBar(label: 'Vigor', value: 45, maxValue: 100, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Card 3: O Radar Mágico (GPS) ---
            Card(
              color: Colors.green.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                      children: const [
                        Icon(Icons.explore, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('Bússola Mágica', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: Colors.white24),
                    Text(
                      'Condição para avançar: ${_biomaAtual!.unlockCondition}', // Nova propriedade que a equipe criou
                      style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    Text('Rosa dos Ventos: ${_posicaoAtual!.heading.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.amber)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Botão para Completar a Missão (Apenas para Teste da Sprint 1) ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              onPressed: () {
                setState(() {
                  nivelProgresso++; // Aumenta o progresso para liberar o próximo bioma
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Missão Completa! Dirija-se ao próximo Bioma.")),
                );
              },
              child: const Text("Completar Missão Deste Bioma", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Barra de Status do aventureiro
// =========================================================================
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / maxValue,
              backgroundColor: Colors.black,
              color: color,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}