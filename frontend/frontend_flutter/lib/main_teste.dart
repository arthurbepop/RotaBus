// ARQUIVO TESTE PARA VERIFICAR O MAIN.DART
// Este arquivo sobrescreve o main.dart para testar

import 'package:flutter/material.dart';
import 'telas/map_screen.dart';

void main() {
  runApp(AppOnibus());
}

class AppOnibus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RotaBus - TESTE MAIN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TesteScreen(), // CHAMANDO TELA DE TESTE
      debugShowCheckedModeBanner: false,
    );
  }
}

class TesteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TESTE - SE VOCÊ VÊ ISSO, O PROBLEMA FOI RESOLVIDO'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'AGORA ESTAMOS EDITANDO O ARQUIVO CORRETO!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                );
              },
              child: Text('IR PARA O MAPA COM BARRA DE PESQUISA'),
            ),
          ],
        ),
      ),
    );
  }
}