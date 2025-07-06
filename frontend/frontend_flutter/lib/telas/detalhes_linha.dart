import 'package:flutter/material.dart';
import '../modelos/linha.dart';
import '../servicos/api_linhas.dart';

class TelaDetalhesLinha extends StatefulWidget {
  final Linha linha;
  const TelaDetalhesLinha({Key? key, required this.linha}) : super(key: key);

  @override
  _TelaDetalhesLinhaState createState() => _TelaDetalhesLinhaState();
}

class _TelaDetalhesLinhaState extends State<TelaDetalhesLinha> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<dynamic> _paradas = [];
  List<dynamic> _horarios = [];
  bool _loading = true;
  final ApiLinhas _apiLinhas = ApiLinhas();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() { _loading = true; });
    final paradas = await _apiLinhas.obterParadas(widget.linha.id);
    final horarios = await _apiLinhas.obterHorarios(widget.linha.id);
    setState(() {
      _paradas = paradas;
      _horarios = horarios;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.linha.nome),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Paradas'),
            Tab(text: 'Horários'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Paradas
                ListView.builder(
                  itemCount: _paradas.length,
                  itemBuilder: (context, index) {
                    final parada = _paradas[index];
                    return ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text(parada['nome'] ?? ''),
                    );
                  },
                ),
                // Horários
                ListView.builder(
                  itemCount: _horarios.length,
                  itemBuilder: (context, index) {
                    final horario = _horarios[index];
                    return ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('Sentido: ${horario['sentido'] ?? ''}'),
                      subtitle: Text(horario.toString()),
                    );
                  },
                ),
              ],
            ),
    );
  }
}