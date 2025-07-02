
import 'package:flutter/material.dart';
import 'package:frontend_flutter/telas/tela_inicial.dart';
import 'telas/map_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  //await dotenv.load(fileName: ".env");
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


// Tela do mapa movida para telas/map_screen.dart


// Removido: duplicidade da classe _MapScreenState