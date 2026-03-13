import 'package:flutter/material.dart';

import 'screens/game/math_game_screen.dart';
import 'models/math_mode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MathGameScreen(
        mode: MathMode.plus,
      ),
    );

  }

}