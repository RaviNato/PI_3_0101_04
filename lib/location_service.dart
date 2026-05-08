import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'bioma.dart';     
import 'bioma_data.dart';

class LocationService {
  // 1. Flag de desenvolvedor. Mude para 'false' quando for testar andando pelo campus.
  static const bool isDevMode = false;

  // Função para verificar permissões e pegar a localização atual
  StreamSubscription<Position>? positionStream;

  Position get _mockPosition => Position(
    latitude: -22.834115, 
    longitude: -47.052605,
    timestamp: DateTime.now(),
    accuracy: 5.0,
    altitude: 0.0,
    heading: 90.0,
    speed: 1.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );

  Future<Position?> determinePosition() async {
    if (isDevMode) return _mockPosition;
  
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Testa se o GPS do celular está ligado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Se estiver desligado, você pode mostrar um aviso no app
      return Future.error('Os serviços de localização estão desativados.');
    }

    // 2. Verifica o status da permissão atual
    permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // 3. Se foi negada antes, pede a permissão para o usuário
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada pelo jogador.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissões negadas permanentemente, não podemos solicitar.');
    } 

    // 4. Se chegou aqui, temos permissão! Pega a Latitude e Longitude.
    return await Geolocator.getCurrentPosition();
  }



// Coordenadas aproximadas do Campus I (Você precisará pegar a exata no Google Maps depois)
  final double campusLatitude = -22.8335; 
  final double campusLongitude = -47.0504;
  final double raioPermitidoEmMetros = 500.0; // Exemplo: 500 metros

  // Esta função retorna o Bioma onde o jogador está, precisa colocar classe bioma e variavel ambientesPuc
  Bioma? verificarAmbienteAtual(Position playerPosition) {
    // Usando a lista oficial da equipe agora: BiomaData.biomas
    for (var bioma in BiomaData.biomas) {
      double distanceInMeters = Geolocator.distanceBetween(
        playerPosition.latitude,
        playerPosition.longitude,
        bioma.latitude, // Era bioma.lat
        bioma.longitude, // Era bioma.lng
      );

      if (distanceInMeters <= bioma.radiusInMeters) { // Era bioma.raio
        return bioma; 
      }
    }
    return null; 
  }

  // Inicia o rastreamento contínuo do jogador
  void startTracking(Function(Position) onLocationUpdate) {
    if (isDevMode) {
      // Simula o GPS atualizando a posição a cada 2 segundos no PC
      Stream.periodic(const Duration(seconds: 2)).listen((_) {
        onLocationUpdate(_mockPosition);
      });
      return;
    }
    
    // 1. Calibrando a infraestrutura de geolocalização (Resolve a Etapa 5)
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best, // Exige a maior precisão possível
      distanceFilter: 2, // Só atualiza o jogo se o jogador se mover pelo menos 2 metros
    );

    // 2. Implementando a captura contínua (Resolve a Etapa 2)
    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      
      // Validação extra de precisão: position.accuracy é a margem de erro em metros.
      // Se for maior que 20 ou 30 metros, o GPS está "confuso" (ex: dentro de um prédio).
      if (position.accuracy > 30.0) {
        print("Aviso: Sinal de GPS fraco. A precisão está comprometida.");
        // Dependendo do jogo, você pode ignorar esse dado (return;) ou mostrar um ícone na tela.
      }

      // 3. A Rosa dos Ventos (Resolve a Etapa 4)
      // Direção do movimento em graus (0 = Norte, 90 = Leste, etc).
      double direcao = position.heading;
      print("Jogador está se movendo na direção: $direcao graus");

      // Envia a nova posição e direção de volta para o seu jogo atualizar a tela
      onLocationUpdate(position);
    });
  }

  // É CRÍTICO parar de escutar o GPS quando o jogador sair do jogo ou da tela de exploração
  void stopTracking() {
    positionStream?.cancel();
    positionStream = null;
  }
}