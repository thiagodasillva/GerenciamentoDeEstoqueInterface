import 'package:flutter/material.dart';
import 'busca_screen.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Estoque',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BuscaEstoqueScreen(), // Chama a tela que criamos
    );
  }
}