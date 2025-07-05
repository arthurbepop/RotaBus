import 'package:flutter/material.dart';
import 'telas/map_screen.dart';

void main() {
  runApp(AppOnibus());
}

class AppOnibus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RotaBus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapScreen(), // CHAMANDO DIRETAMENTE O MAP_SCREEN
      debugShowCheckedModeBanner: false,
    );
  }
}