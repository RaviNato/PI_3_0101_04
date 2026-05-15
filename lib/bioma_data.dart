
import 'bioma.dart'; 

/// Repositório estático dos 5 biomas. 

///   assets:
///     - assets/images/floresta.png
///     - assets/images/geleira.png
///     - assets/images/oceano.png
///     - assets/images/deserto.png
///     - assets/images/vulcao.png

class BiomaData {
  BiomaData._(); // previne instanciação acidental

  static List<Bioma> get biomas => [
   
        Bioma(
          id: 'bioma_01',
          name: 'Floresta',
          latitude: -22.834115,   // Entorno do Prédio H15 — PUC-Campinas
          longitude: -47.052605,
          radiusInMeters: 50.0,
          isUnlocked: true,     // Bioma inicial — sempre aberto
          assetImagePath: 'assets/images/floresta.jpg',
          unlockCondition: 'start',
        ),

        Bioma(
          id: 'bioma_02',
          name: 'Geleira',
          latitude: -22.832475,   // Entorno do CT — PUC-Campinas
          longitude: -47.052738,  
          radiusInMeters: 50.0,
          isUnlocked: false,
          assetImagePath: 'assets/images/geleira.jpg',
          unlockCondition: 'charada_ancia_respondida',
        ),

        Bioma(
          id: 'bioma_03',
          name: 'Oceano',
          latitude: -22.833065,   // Entorno da Praça de Alimentação — PUC-Campinas
          longitude: -47.052013,
          radiusInMeters: 50.0,
          isUnlocked: false,
          assetImagePath: 'assets/images/oceano.jpg',
          unlockCondition: 'geleira_concluida',
        ),

        Bioma(
          id: 'bioma_04',
          name: 'Deserto',
          latitude: -22.833992,   // Entorno do Administrativo I — PUC-Campinas
          longitude: -47.050558,  
          radiusInMeters: 50.0,
          isUnlocked: false,
          assetImagePath: 'assets/images/deserto.jpg',
          unlockCondition: 'dica_pirata_recebida',
        ),

        Bioma(
          id: 'bioma_05',
          name: 'Vulcão',
          latitude: -22.831766,   // Entorno do Administrativo II — PUC-Campinas
          longitude: -47.050741,  
          radiusInMeters: 50.0,
          isUnlocked: false,
          assetImagePath: 'assets/images/vulcao.jpg',
          unlockCondition: 'reliquia_coletada',
        ),
      ];
}
