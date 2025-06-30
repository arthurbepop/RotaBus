import 'package:flutter/material.dart';
import '../modelos/linha.dart';
import '../servicos/api_linhas.dart';

class TelaLinhasOnibus extends StatefulWidget {
  @override
  _TelaLinhasOnibusState createState() => _TelaLinhasOnibusState();
}

class _TelaLinhasOnibusState extends State<TelaLinhasOnibus> {
  late Future<List<Linha>> linhas;

  @override
  void initState() {
    super.initState();
    linhas = ApiLinhas().obterLinhas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Linhas de Ônibus'),
      ),
      body: FutureBuilder<List<Linha>>(
        future: linhas,
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selecionada: ${linha.nome}')),
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
// Quando uma linha é selecionada, exibe um SnackBar com o nome da linha selecionada.
// A lista de linhas é exibida em um ListView, onde cada item é um ListTile com um ícone de ônibus e o nome da linha.
// O código é organizado para ser fácil de entender e manter, seguindo boas práticas de desenvolvimento Flutter