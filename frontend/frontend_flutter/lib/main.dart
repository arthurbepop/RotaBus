import 'package:flutter/material.dart';
import 'telas/splash_screen.dart';

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
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(), // INICIA COM SPLASH SCREEN ANIMADA
      debugShowCheckedModeBanner: false,
    );
  }
}