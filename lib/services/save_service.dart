import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_save.dart';

class SaveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Função que você chamará na HomeScreen ao clicar em "Jogar"
  Future<GameSave> carregarOuCriarSave() async {
    UserCredential user = await _auth.signInAnonymously();
    DocumentSnapshot doc = await _db.collection('jogadores').doc(user.user!.uid).get();

    print("Logado como: ${user.user!.uid}");

    if (doc.exists) {
      return GameSave.fromFirestore(doc.data() as Map<String, dynamic>);
    } else {
      // Save inicial (Floresta)
      GameSave novoSave = GameSave(
        biomaAtual: 'bioma_01',
        etapa: 0,
        flags: {'falou_com_ancia': false},
        biomasAbertos: ['bioma_01'],
      );
      await _db.collection('jogadores').doc(user.user!.uid).set(novoSave.toMap());
      return novoSave;
    }
    
  }
  // Função para salvar o progresso a cada charada
  Future<void> atualizarSave(GameSave save) async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('jogadores').doc(uid).update(save.toMap());
  }
  
}