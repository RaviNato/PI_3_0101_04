// Modelo que define cada Botão no jogo e seu design
class DialogChoice {
  final String text; // Texto do botão 
  final String feedback; // Resposta do NPC
  final bool isCorrect; // Se a resposta avança o jogo ou nãõ
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
    
    // --- BIOMA 01: FLORESTA (Sua responsabilidade) ---
    'bioma_01': NpcDialog(
      npcName: 'Anciã do Vilarejo',
      message: "Jovem, precisamos de sua ajuda para proteger nosso vilarejo. Nesses últimos dias, vivemos atormentados com os monstros da floresta...\n\n"
               "Primeiro, você deverá resolver uma charada: 'Não é deserto de areia, mas também é vazio e extremo. Durante meses só noite ou só dia, e o frio domina o terreno.' Onde é esse lugar?",
      choices: [
        DialogChoice(
          text: 'Região ártica',
          feedback: 'Anciã: Excelente!',
          isCorrect: true,
          conditionToUnlock: 'charada_ancia_respondida',
        ),
        DialogChoice(
          text: 'Deserto',
          feedback: 'Anciã: Resposta incorreta jovem, quer tentar novamente?',
          isCorrect: false,
        ),
      ],
    ),

    'bioma_02': NpcDialog(
      npcName: 'Guardião do Gelo',
      message: "Texto da charada da Geleira aqui...",
      choices: [
        DialogChoice(text: 'Resposta Certa', feedback: 'Muito bem!', isCorrect: true, conditionToUnlock: 'gelo_desbloqueado'),
        DialogChoice(text: 'Resposta Errada', feedback: 'Tente de novo...', isCorrect: false),
      ],
    ),

    // Adicione bioma_03 (Oceano) e bioma_04 (Deserto) seguindo o mesmo padrão...

    'bioma_05': NpcDialog(
      npcName: 'Ignis, o Espírito do Fogo',
      message: "Você chegou ao coração do Vulcão. Resolva o último enigma para obter a Chama: 'Sou o que resta quando o fogo se apaga, mas no escuro, sou o que guia os perdidos.'",
      choices: [
        DialogChoice(
          text: 'A Chama Mágica',
          feedback: 'Ignis: Você provou seu valor! A Chama é sua.',
          isCorrect: true,
          conditionToUnlock: 'chama_obtida',
        ),
        DialogChoice(text: 'Cinzas', feedback: 'Quase, mas não.', isCorrect: false),
      ],
    ),
  };
}