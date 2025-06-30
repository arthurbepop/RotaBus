
import 'package:flutter/material.dart';
import 'telas/tela_inicial.dart';

void main() {
  runApp(AppOnibus());
}

class AppOnibus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linhas de Ônibus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TelaInicial(),
    );
  }
}
// Este é o ponto de entrada do aplicativo Flutter.
// Ele inicializa o aplicativo e define o tema e a tela inicial.