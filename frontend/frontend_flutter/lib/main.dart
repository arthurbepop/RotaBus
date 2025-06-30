import 'package:flutter/material.dart';
import 'telas/linhas_onibus.dart';

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
      home: TelaLinhasOnibus(),
    );
  }
}
// Este é o ponto de entrada do aplicativo Flutter.
// Ele inicializa o aplicativo e define o tema e a tela inicial.