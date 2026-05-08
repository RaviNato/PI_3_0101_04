class GameSave {
  final String biomaAtual;
  final int etapa;
  final Map<String, bool> flags;
  final List<String> biomasAbertos;

  GameSave({
    required this.biomaAtual,
    required this.etapa,
    required this.flags,
    required this.biomasAbertos,
  });

  // Converte do Firestore para o Objeto
  factory GameSave.fromFirestore(Map<String, dynamic> data) {
    return GameSave(
      biomaAtual: data['bioma_atual'] ?? 'bioma_01',
      etapa: data['etapa_narrativa'] ?? 0,
      flags: Map<String, bool>.from(data['flags'] ?? {}),
      biomasAbertos: List<String>.from(data['biomas_desbloqueados'] ?? ['bioma_01']),
    );
  }

  // Converte do Objeto para o Firestore
  Map<String, dynamic> toMap() {
    return {
      'bioma_atual': biomaAtual,
      'etapa_narrativa': etapa,
      'flags': flags,
      'biomas_desbloqueados': biomasAbertos,
    };
  }
}