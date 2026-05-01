import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OmnizonaApp());
}

class OmnizonaApp extends StatelessWidget {
  const OmnizonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omnizona',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8B84B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        // '/game': (_) => const GameScreen(), <- deixa comentado por enquanto
        // seu colega vai criar a GameScreen
      },
    );
  }
}
