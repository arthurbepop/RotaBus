import 'package:flutter/material.dart';
import '../modelos/linha.dart';
import '../servicos/api_linhas.dart';
import 'detalhes_linha.dart';

class TelaLinhasOnibus extends StatefulWidget {
  @override
  _TelaLinhasOnibusState createState() => _TelaLinhasOnibusState();
}

class _TelaLinhasOnibusState extends State<TelaLinhasOnibus> {
  final ApiLinhas _apiLinhas = ApiLinhas();

  Future<List<Linha>> _carregarLinhas() async {
    try {
      return await _apiLinhas.obterLinhas();
    } catch (e) {
      print('Erro ao carregar linhas: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Linhas de Ônibus'),
      ),
      body: FutureBuilder<List<Linha>>(
        future: _carregarLinhas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar linhas'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhuma linha encontrada'));
          }

          final listaLinhas = snapshot.data!;
          return ListView.builder(
            itemCount: listaLinhas.length,
            itemBuilder: (context, index) {
              final linha = listaLinhas[index];
              return ListTile(
                leading: Icon(Icons.directions_bus),
                title: Text(linha.nome),
                subtitle: Text('Sentido: ${linha.sentido}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaDetalhesLinha(linha: linha),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
// Esta tela exibe uma lista de linhas de ônibus.
// Ela utiliza o FutureBuilder para lidar com a chamada assíncrona da API.
// Quando os dados estão sendo carregados, exibe um CircularProgressIndicator.
// Se ocorrer um erro, exibe uma mensagem de erro.
// Se não houver dados, exibe uma mensagem informando que nenhuma linha foi encontrada.
// A lista de linhas é exibida em um ListView, onde cada item é um ListTile com um ícone de ônibus e o nome da linha.
// O código é organizado para ser fácil de entender e manter, seguindo boas práticas de desenvolvimento Flutter.
// A tela foi atualizada para exibir o sentido da linha e navegar para uma tela de detalhes ao selecionar uma linha.