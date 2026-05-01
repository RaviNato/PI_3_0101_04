import 'package:flutter/material.dart';
// Importe o arquivo correto da nova tela da equipe
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omnizona',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown, // Mudamos para a paleta rústica
        useMaterial3: true,
      ),
      // Substituímos a TelaInicio pela HomeScreen
      home: const HomeScreen(), 
    );
  }
}