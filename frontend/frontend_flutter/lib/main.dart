

import 'package:flutter/material.dart';

import 'telas/map_screen.dart';

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
      home: MapScreen(),
    );
  }
}


// Tela do mapa movida para telas/map_screen.dart


// Removido: duplicidade da classe _MapScreenState