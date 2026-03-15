import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';

void main() => runApp(const MathApp());

class MathApp extends StatelessWidget {
  const MathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'さんすうアプリ',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        fontFamily: 'Hiragino Sans',
      ),
      home: const MenuScreen(),
    );
  }
}
