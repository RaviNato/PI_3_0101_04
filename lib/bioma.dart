/// Modelo que representa um bioma/ambiente do jogo Omnizona.
/// Cada bioma corresponde a um local físico do Campus I 
/// e possui um raio de proximidade, imagem visual e condição narrativa
/// de desbloqueio conforme o roteiro do jogo.
class Bioma {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  bool isUnlocked;
  final String assetImagePath;


  final String unlockCondition;

  Bioma({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusInMeters = 50.0,
    required this.isUnlocked,
    required this.assetImagePath,
    required this.unlockCondition,
  });

  /// Tenta desbloquear o bioma com a condição narrativa fornecida.
  bool unlockBiome(String conditionMet) {
    if (!isUnlocked && conditionMet == unlockCondition) {
      isUnlocked = true;
      return true;
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────
  // Utilitários

  /// Cria uma cópia do bioma com campos opcionalmente substituídos.
  Bioma copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusInMeters,
    bool? isUnlocked,
    String? assetImagePath,
    String? unlockCondition,
  }) {
    return Bioma(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      unlockCondition: unlockCondition ?? this.unlockCondition,
    );
  }

  @override
  String toString() =>
      'Bioma(id: $id, name: $name, local: ($latitude,$longitude), '
      'raio: ${radiusInMeters}m, desbloqueado: $isUnlocked)';
}
