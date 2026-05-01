import 'package:flutter/material.dart';
import 'telas.dart'; // Importa o arquivo onde criamos as telas

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Jogo Flutter',
      debugShowCheckedModeBanner: false, // Remove a faixa de "Debug"
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Define a tela inicial do jogo
      home: const TelaInicio(), 
    );
  }
}