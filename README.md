# Omnizona

Este repositório contém o código-fonte do Omnizona, um jogo mobile baseado em localização desenvolvido como Projeto Integrador do terceiro semestre do curso de Sistemas de Informação na Pontifícia Universidade Católica de Campinas (PUC-Campinas).

O objetivo do projeto foi integrar conceitos de geolocalização em tempo real, persistência de dados em nuvem, arquitetura orientada a objetos e gerenciamento de estado em dispositivos móveis, utilizando o campus da universidade como o cenário do jogo.

## Mecânicas e Funcionalidades

* **Geofencing e Geolocalização:** O aplicativo monitora continuamente as coordenadas geográficas do usuário (latitude e longitude) através do GPS do aparelho. O sistema calcula a distância em linha reta até cinco pontos de interesse fixos no Campus I da PUC-Campinas (Prédio H15, Centro de Tecnologia, Praça de Alimentação, Administrativo I e Administrativo II). Se o usuário estiver dentro de um raio de 50 metros de um ponto desbloqueado, o ambiente interativo é ativado.
* **Progressão Narrativa Baseada em Estados:** O progresso do jogador é controlado por chaves estruturadas (etapas e flags de conclusão). NPCs específicos apresentam diálogos e validação de respostas apenas se o jogador cumprir os pré-requisitos lógicos e geográficos da etapa atual.
* **Sincronização de Áudio Dinâmica:** O sistema gerencia instâncias de reprodução de áudio nativo em segundo plano. Ao mudar de bioma através do deslocamento físico, o aplicativo realiza a interrupção da faixa anterior e inicia a nova trilha sonora correspondente ao ambiente atual.

## Arquitetura e Tecnologias

* **Framework:** Flutter (linguagem Dart), configurado e travado nativamente na orientação horizontal (Landscape).
* **Persistência em Nuvem (Backend):** Firebase Cloud Firestore para o armazenamento do progresso do usuário sob uma estrutura de documentos NoSQL.
* **Autenticação:** Firebase Authentication configurado com login anônimo (Sign-in Anonymously). Isso vincula um identificador único seguro (UID) ao dispositivo do usuário, eliminando a necessidade de formulários de cadastro e garantindo a retenção do progresso.
* **Persistência Local:** SharedPreferences para gravação de dados leves de sessão no próprio aparelho, como o nome definido pelo usuário.
* **Consumo de Dados de Sensores:** Pacote `geolocator` configurado para atualizações contínuas de hardware baseadas em filtros de distância mínima de movimentação.

## Estrutura de Código Relevante

* `location_service.dart`: Responsável por checar permissões de hardware, calibrar configurações de precisão de sensores e abrir um canal contínuo de dados (Stream) com o GPS do dispositivo.
* `save_service.dart`: Centraliza a comunicação com as APIs do Firebase. Realiza requisições assíncronas pontuais (Futures) para download e upload do estado do jogo, otimizando o tráfego de rede e o consumo de bateria.
* `game_save.dart`: Modelo de dados que atua na serialização e desserialização dos dados do jogador, traduzindo mapas vindos do Firestore em objetos Dart manipuláveis.
* `character_screen.dart`: Tela principal e controladora do ciclo de vida do jogo. Gerencia o estado das interfaces, escuta as atualizações de localização e despacha comandos para a troca de mídias sonoras.
* `bioma_data.dart` e `npc_data.dart`: Repositórios de dados estáticos que contêm as coordenadas geográficas reais do campus, caminhos de assets de imagem e matrizes de árvores de diálogos.

## Como Testar o Jogo

O projeto pode ser validado de duas formas distintas:

### 1. Instalação Direta via APK (Dispositivo Android)
Para testar o jogo finalizado sem a necessidade de configurar um ambiente de desenvolvimento ou SDK do Flutter:
1. Localize o arquivo APK pré-compilado presente na pasta de distribuição do projeto (geralmente estruturado em `build/app/outputs/flutter-apk/app-release.apk` ou disponibilizado na aba de Releases do repositório).
2. Transfira o arquivo para um dispositivo Android.
3. Ative a permissão para instalação de fontes desconhecidas nas configurações do sistema operacional e execute o arquivo para instalar o aplicativo.
4. Ao abrir, conceda a permissão de acesso à localização quando solicitada.

### 2. Emulação / Validação de Código (Modo de Desenvolvimento)
Caso precise testar as interfaces, lógica de saves e progressão sem estar fisicamente presente nas coordenadas da PUC-Campinas:
1. Abra o arquivo `lib/location_service.dart`.
2. Altere a constante estática `isDevMode` de `false` para `true`.
3. Essa flag faz com que o sistema ignore os dados de hardware do GPS e passe a injetar posições simuladas (Mock Positions) referentes aos biomas cadastrados, permitindo testar o fluxo completo do software diretamente de um emulador ou fora do campus.
4. Certifique-se de retornar a flag para `false` antes de realizar builds destinadas ao uso real em campo.
