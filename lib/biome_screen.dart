import 'package:flutter/material.dart';
import 'bioma.dart';     
import 'bioma_data.dart';

class BiomeScreen extends StatefulWidget {
  const BiomeScreen({super.key});

  @override
  State<BiomeScreen> createState() => _BiomeScreenState();
}

class _BiomeScreenState extends State<BiomeScreen> {
  // Lista mutável para que setState funcione ao desbloquear biomas
  late List<Bioma> _biomas;

  @override
  void initState() {
    super.initState();
    // Cria cópia da lista estática para manipulação de estado
    _biomas = List<Bioma>.from(BiomaData.biomas);
  }


  /// Tenta desbloquear o bioma [biomaId] usando a condição [conditionMet].
  /// Exibe SnackBar de feedback quando bem-sucedido.
  void tryUnlock(String biomaId, String conditionMet) {
    setState(() {
      final bioma = _biomas.firstWhere((b) => b.id == biomaId);
      final unlocked = bioma.unlockBiome(conditionMet);

      if (unlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌍 ${bioma.name} desbloqueado!'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  //   isUnlocked = true  → Image.asset() com o visual do bioma
  //   isUnlocked = false → Container de névoa cinza (sprite oculto)

  Widget _buildScenario(Bioma bioma) {
    if (bioma.isUnlocked) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          bioma.assetImagePath,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          // Fallback durante desenvolvimento (assets ainda não adicionados)
          errorBuilder: (_, __, ___) => _devPlaceholder(bioma),
        ),
      );
    }

    // RF08: Cenário OCULTO — névoa de bloqueio
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white38, size: 40),
            const SizedBox(height: 8),
            const Text(
              'Ambiente bloqueado',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Condição: ${bioma.unlockCondition}',
              style: const TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _devPlaceholder(Bioma bioma) {
    const palette = {
      'bioma_01': Color(0xFF1B5E20), // Floresta   – verde escuro
      'bioma_02': Color(0xFF01579B), // Geleira    – azul gelo
      'bioma_03': Color(0xFF006064), // Oceano     – azul-esverdeado
      'bioma_04': Color(0xFFE65100), // Deserto    – laranja escaldante
      'bioma_05': Color(0xFFB71C1C), // Vulcão     – vermelho lava
    };

    return Container(
      width: double.infinity,
      height: 160,
      color: palette[bioma.id] ?? Colors.blueGrey.shade900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              bioma.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '[DEV] asset não encontrado',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build principal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          'Omnizona',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
        actions: [
          // Contador de biomas desbloqueados
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: Colors.white54, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_biomas.where((b) => b.isUnlocked).length}/${_biomas.length} desbloqueados',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _biomas.length,
        itemBuilder: (context, index) {
          final bioma = _biomas[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: bioma.isUnlocked
                    ? Colors.greenAccent.withOpacity(0.5)
                    : Colors.white12,
                width: bioma.isUnlocked ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RF08 · Imagem condicional do cenário
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildScenario(bioma),
                ),

                // Nome + badge de status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          bioma.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bioma.isUnlocked
                              ? Colors.green.shade900
                              : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bioma.isUnlocked ? '✓ Desbloqueado' : '🔒 Bloqueado',
                          style: TextStyle(
                            color: bioma.isUnlocked
                                ? Colors.greenAccent
                                : Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Localização física no campus
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_campusLocation(bioma.id)} — raio: ${bioma.radiusInMeters.toInt()}m',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),

                // RF03 · Botão de simulação para testes
                if (!bioma.isUnlocked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          side: const BorderSide(color: Colors.amber),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.lock_open, size: 16),
                        label: const Text(
                          'Simular desbloqueio (dev)',
                          style: TextStyle(fontSize: 13),
                        ),
                        onPressed: () =>
                            tryUnlock(bioma.id, bioma.unlockCondition),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Retorna o nome do local físico no campus para exibição.
  String _campusLocation(String biomaId) {
    const locations = {
      'bioma_01': 'Prédio H15',
      'bioma_02': 'CT (Centro de Tecnologia)',
      'bioma_03': 'Praça de Alimentação',
      'bioma_04': 'Administrativo I',
      'bioma_05': 'Administrativo II',
    };
    return locations[biomaId] ?? 'Campus PUC-Campinas';
  }
}
