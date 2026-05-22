// Modelo que define cada Botão no jogo e seu design
class DialogChoice {
  final String text; // Texto do botão 
  final String feedback; // Resposta do NPC
  final bool isCorrect; // Se a resposta avança o jogo ou não
  final String? conditionToUnlock; // liberação para próxima etapa

  DialogChoice({
    required this.text,
    required this.feedback,
    required this.isCorrect,
    this.conditionToUnlock,
  });
}

// Modelo que define o NPC e sua pergunta
class NpcDialog {
  final String npcName;
  final String message;
  final List<DialogChoice> choices; // Lista de botões

  NpcDialog({required this.npcName, required this.message, required this.choices});
}

// O BANCO DE DADOS DA EQUIPE
class NpcData {
  NpcData._();

  // Um "Dicionário" onde a chave é o ID do bioma e o valor é o diálogo
  static Map<String, NpcDialog> dialogos = {
    
    // --- BIOMA 1: FLORESTA ---
    // A Floresta dá a chave para abrir a GELEIRA
    'bioma_01': NpcDialog(
      npcName: 'Anciã do Vilarejo',
      message: "Jovem, precisamos de sua ajuda para proteger nosso vilarejo. Nesses últimos dias, vivemos atormentados com os monstros da floresta...\n\n"
               "Primeiro, você deverá resolver uma charada: 'Não é deserto de areia, mas também é vazio e extremo. Durante meses só noite ou só dia, e o frio domina o terreno.' Onde é esse lugar?",
      choices: [
        DialogChoice(
          text: 'Região subártica', feedback: 'Resposta incorreta, quer tentar novamente?', isCorrect: false
        ),
        DialogChoice(
          text: 'Região ártica',
          feedback: 'Excelente!',
          isCorrect: true,
          conditionToUnlock: 'charada_ancia_respondida', // Abre a Geleira
          ),
      ],
    ),

    // --- BIOMA 2: GELEIRA ---
    // A Geleira dá a chave para abrir o OCEANO
    'bioma_02': NpcDialog(
      npcName: 'Guardião do Gelo',
      message: "Se deseja atravessar estas terras congeladas, responda:"
                "O que quanto mais se tira, maior fica'?",
      choices: [
        DialogChoice(
          text: 'Buraco', 
          feedback: 'Correto', 
          isCorrect: true, 
          conditionToUnlock: 'geleira_concluida', // Abre o Oceano
        ),
        DialogChoice(text: 'Gelo', feedback: 'Resposta incorreta...', isCorrect: false),
      ],
    ),

    // --- BIOMA 3: OCEANO ---
    // O Oceano dá a chave para abrir o DESERTO
    'bioma_03': NpcDialog(
      npcName: 'Esqueleto Pirata',
      message: "Olá, marinheiro. Vejo que andas por estas águas, o que lhe interessa?",
      choices: [
        DialogChoice(
          text: 'Por que eu deveria confiar em você?',
          feedback: 'Sou um antigo capitão, que após perder minha tripulação, fiquei aprisionado nesta ilha. Desde então sigo guiando viajantes ao longo dessas águas. \nEntão, novamente, o que lhe interessa?',
          isCorrect: false,
          
        ),
        DialogChoice(
          text: 'Buscar a chama mágica',
          feedback: 'Sei do que precisa. Sua chama está no vulcão, mas é cercado pela ardência do magma. \nEntretanto, há no deserto uma relíquia capaz de te proteger do fogo vulcânico. Ir para o deserto garantirá o sucesso da sua missão',
          isCorrect: true,
          conditionToUnlock: 'falou_com_pirata',
        ),
      ],
    ),

    // --- BIOMA 4: DESERTO ---
    'bioma_04': NpcDialog(
      npcName: 'Múmia Anciã',
      message: "Tu desejas a relíquia? Então decifre meus dois enigmas e tu a terás. Enigma 1: O que é, o que é:"
                "Não tem pernas, mas percorre o deserto inteiro; não tem boca, mas pode “engolir” tudo pelo caminho?",
      choices: [
        DialogChoice(text: 'Vento', feedback: 'quer retornar para sua origem ou quer tentar responder meus enigmas novamente?', isCorrect: false),
        DialogChoice(
          text: 'Tempestade de areia', 
          feedback: 'Correto!', 
          isCorrect: true, 
          conditionToUnlock: 'reliquia_coletada', // Abre o Vulcão
        ),
        DialogChoice(text: 'Sol', feedback: 'Quer retornar para sua origem ou quer tentar responder meus enigmas novamente?', isCorrect: false),
        DialogChoice(text: 'Rio', feedback: 'Quer retornar para sua origem ou quer tentar responder meus enigmas novamente?', isCorrect: false),
      ],
    ),

    // --- BIOMA 5: VULCÃO ---
    // O Vulcão encerra a jornada
    'bioma_05': NpcDialog(
      npcName: 'Ignis, o Espírito do Fogo',
      message: "Você chegou ao coração do Vulcão. Resolva o último enigma para obter a Chama: 'Sou o que resta quando o fogo se apaga, mas no escuro, sou o que guia os perdidos.'",
      choices: [
        DialogChoice(
          text: 'A Chama Mágica',
          feedback: 'Você provou seu valor! A Chama é sua.',
          isCorrect: true,
          conditionToUnlock: 'chama_obtida', // Aciona o final do jogo
        ),
        DialogChoice(text: 'Cinzas', feedback: 'Quase, mas não.', isCorrect: false),
      ],
    ),
  };
}