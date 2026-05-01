import 'package:flutter/material.dart';

// --- TELA DE INÍCIO ---
class TelaInicio extends StatelessWidget {
  const TelaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 1, 106, 51), Color.fromARGB(255, 46, 225, 67)], // Substitua por cores de sua preferência
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Omnizona',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                backgroundColor: const Color.fromARGB(255, 255, 77, 0),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaJogo()),
                );
              },
              child: const Text(
                'JOGAR',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TELA DO JOGO ---
class TelaJogo extends StatefulWidget {
  const TelaJogo({super.key});

  @override
  State<TelaJogo> createState() => _TelaJogoState();
}

class _TelaJogoState extends State<TelaJogo> {
  // Posição inicial do personagem (0.0 a 1.0 ou coordenadas fixas)
  double personagemX = 0;
  double personagemY = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo do Jogo
          Container(color: Colors.green[300]),

          // Personagem
          Align(
            alignment: Alignment(personagemX, personagemY), // Aqui vai o objeto Alignment
            child: const Personagem(),
          ),

          // Botão de Voltar (Opcional)
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Interface de Pontos (Exemplo)
          /*const Positioned(
            top: 50,
            right: 20,
            child: Text(
              'Score: 0',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),*/
        ],
      ),
    );
  }
}

// --- OBJETO DO PERSONAGEM ---
class Personagem extends StatelessWidget {
  const Personagem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: const Center(
        child: Icon(Icons.person, color: Colors.white, size: 40),
      ),
    );
  }
}

// Extensão simples para cores customizadas se necessário
extension on Colors {
  //static const Color darkBlueCustom = Color(0xFF0D47A1);
}