import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../modelos/linha.dart';
import '../servicos/api_linhas.dart';
import 'map_screen.dart';

class GrupoLinha {
  final String nome;
  final String codigo;
  final List<Linha> sentidos;
  bool isSelected;
  Map<String, List<dynamic>> paradasCarregadas;

  GrupoLinha({
    required this.nome,
    required this.codigo,
    required this.sentidos,
    this.isSelected = false,
  }) : paradasCarregadas = {};
}

class TelaLinhasOnibus extends StatefulWidget {
  @override
  _TelaLinhasOnibusState createState() => _TelaLinhasOnibusState();
}

class _TelaLinhasOnibusState extends State<TelaLinhasOnibus> with TickerProviderStateMixin {
  final ApiLinhas _apiLinhas = ApiLinhas();
  final TextEditingController _searchController = TextEditingController();
  List<Linha> _todasLinhas = [];
  List<GrupoLinha> _gruposLinhas = [];
  List<GrupoLinha> _gruposFiltrados = [];
  bool _isLoading = true;
  String _filtroSelecionado = 'Todas';
  late AnimationController _animationController;
  
  // Variáveis para controle da barra de pesquisa
  GrupoLinha? _linhaSelecionada;
  List<String> _sentidosRecomendados = [];
  bool _mostrandoRecomendacoes = false;
  
  // Novas variáveis para sugestões de pesquisa
  List<GrupoLinha> _sugestoesLinhas = [];
  bool _mostrandoSugestoes = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _carregarLinhas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarLinhas() async {
    setState(() => _isLoading = true);
    
    try {
      final linhas = await _apiLinhas.obterLinhas();
      setState(() {
        _todasLinhas = linhas;
        _gruposLinhas = _agruparLinhas(linhas);
        _gruposFiltrados = _gruposLinhas;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarSnackBar('Erro ao carregar linhas: $e', Colors.red);
    }
  }

  List<GrupoLinha> _agruparLinhas(List<Linha> linhas) {
    final Map<String, List<Linha>> grupos = {};
    
    for (var linha in linhas) {
      final nomeBase = linha.nome.replaceAll(RegExp(r'\s*-.*'), '').trim();
      if (!grupos.containsKey(nomeBase)) {
        grupos[nomeBase] = [];
      }
      grupos[nomeBase]!.add(linha);
    }
    
    return grupos.entries.map((entry) {
      final codigo = entry.value.first.id;
      return GrupoLinha(
        nome: entry.key,
        codigo: codigo,
        sentidos: entry.value,
      );
    }).toList();
  }

  void _filtrarLinhas(String busca) {
    setState(() {
      final buscaTrim = busca.trim().toLowerCase();
      if (buscaTrim.isEmpty) {
        _gruposFiltrados = _gruposLinhas;
        _mostrandoSugestoes = false;
        _sugestoesLinhas = [];
        _linhaSelecionada = null;
        _sentidosRecomendados = [];
        _mostrandoRecomendacoes = false;
        return;
      }
      final buscaNormalizada = buscaTrim.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
      final filtrados = _gruposLinhas.where((grupo) {
        final nomeNormalizado = grupo.nome.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');
        final codigoNormalizado = grupo.codigo.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');
        return nomeNormalizado.contains(buscaNormalizada) || codigoNormalizado.contains(buscaNormalizada);
      }).toList();
      _gruposFiltrados = filtrados;
      _mostrandoSugestoes = false;
      _sugestoesLinhas = [];
      _linhaSelecionada = null;
      _sentidosRecomendados = [];
      _mostrandoRecomendacoes = false;
    });
  }

  void _aplicarFiltroSentido(String filtro) {
    setState(() {
      _filtroSelecionado = filtro;
    });
    _filtrarLinhas(_searchController.text);
  }

  Future<void> _carregarParadas(GrupoLinha grupo, String sentido) async {
    if (grupo.paradasCarregadas.containsKey(sentido)) {
      return; // Já carregadas
    }

    try {
      final paradas = await _apiLinhas.obterParadas(grupo.codigo);
      setState(() {
        grupo.paradasCarregadas[sentido] = paradas;
      });
    } catch (e) {
      print('Erro ao carregar paradas: $e');
      setState(() {
        grupo.paradasCarregadas[sentido] = [];
      });
    }
  }

  void _navegarParaMapa(GrupoLinha grupo, String sentido) {
    HapticFeedback.mediumImpact();
    final paradas = grupo.paradasCarregadas[sentido] ?? [];
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          paradasDestacadas: paradas,
          tituloLinha: '${grupo.nome} - $sentido',
        ),
      ),
    );
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<String> _obterSentidosUnicos() {
    final sentidos = _todasLinhas.map((l) => l.sentido).where((s) => s.isNotEmpty).toSet().toList();
    sentidos.sort();
    return ['Todas', ...sentidos];
  }

  void _selecionarSentidoRecomendado(String sentido) async {
    if (_linhaSelecionada != null) {
      HapticFeedback.lightImpact();
      
      // Carregar paradas e navegar para o mapa
      await _carregarParadas(_linhaSelecionada!, sentido);
      _navegarParaMapa(_linhaSelecionada!, sentido);
      
      // Limpar busca e recomendações
      _searchController.clear();
      setState(() {
        _linhaSelecionada = null;
        _sentidosRecomendados = [];
        _mostrandoRecomendacoes = false;
      });
      _filtrarLinhas('');
    }
  }

  void _selecionarLinhaSugerida(GrupoLinha grupo, {String? sentido}) {
    setState(() {
      _searchController.text = grupo.nome;
      _linhaSelecionada = grupo;
      _sentidosRecomendados = grupo.sentidos.map((s) => s.sentido).toList();
      _mostrandoRecomendacoes = true;
      _sugestoesLinhas = [];
      _mostrandoSugestoes = false;
    });
    if (sentido != null) {
      // Garante que as paradas estejam carregadas antes de navegar
      _carregarParadas(grupo, sentido).then((_) {
        _navegarParaMapa(grupo, sentido);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Linhas de Ônibus'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[600]!, Colors.blue[700]!, Colors.blue[800]!],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarLinhas,
            tooltip: 'Atualizar linhas',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho com busca, filtros, sugestões, recomendações
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Campo de busca
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Digite a linha: (ex: linha 01)',
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filtrarLinhas('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onChanged: _filtrarLinhas,
                    ),
                  ),

                  // Recomendações de sentidos (aparecem quando uma linha é selecionada)
                  if (_mostrandoRecomendacoes && _sentidosRecomendados.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.directions_bus, color: Colors.blue[600], size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Sentidos da ${_linhaSelecionada?.nome}:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _sentidosRecomendados.map((sentido) {
                              return GestureDetector(
                                onTap: () => _selecionarSentidoRecomendado(sentido),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[600],
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        sentido,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Lista de linhas (expandida)
            Expanded(
              child: _buildCorpoLista(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorpoLista() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    // Se está mostrando sugestões ou recomendações, não mostrar a lista de grupos
    if (_mostrandoSugestoes || _mostrandoRecomendacoes) {
      return SizedBox.shrink(); // Simplesmente não mostra nada
    }

    if (_gruposFiltrados.isEmpty) {
      return Center(child: Text('Nenhuma linha encontrada.', style: TextStyle(color: Colors.grey)));
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: _gruposFiltrados.length,
          itemBuilder: (context, index) {
            final grupo = _gruposFiltrados[index];
            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.1,
                  1.0,
                  curve: Curves.easeOutBack,
                ),
              ),
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: _buildCardGrupoLinha(grupo, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardGrupoLinha(GrupoLinha grupo, int index) {
    final cores = [
      [Colors.blue, Colors.blue[700]!],
      [Colors.green, Colors.green[700]!], 
      [Colors.orange, Colors.orange[700]!],
      [Colors.purple, Colors.purple[700]!],
      [Colors.teal, Colors.teal[700]!],
    ];
    final corIndex = index % cores.length;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: grupo.isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: grupo.isSelected ? Colors.blue[50] : Colors.white,
        child: Column(
          children: [
            // Header da linha principal
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    // Se a linha já está selecionada, deseleciona
                    if (_linhaSelecionada == grupo) {
                      _linhaSelecionada = null;
                      grupo.isSelected = false;
                    } else {
                      // Deseleciona a linha anterior
                      if (_linhaSelecionada != null) {
                        _linhaSelecionada!.isSelected = false;
                      }
                      // Seleciona a nova linha
                      _linhaSelecionada = grupo;
                      grupo.isSelected = true;
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Ícone colorido
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: cores[corIndex],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: cores[corIndex][0].withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      
                      SizedBox(width: 16),
                      
                      // Informações da linha
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              grupo.nome,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${grupo.sentidos.length} sentido(s) disponível(is)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Código: ${grupo.codigo}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Ícone indicativo
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: grupo.isSelected
                            ? Icon(
                                Icons.touch_app,
                                color: Colors.blue[600],
                                size: 24,
                                key: ValueKey('selected'),
                              )
                            : Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[600],
                                size: 18,
                                key: ValueKey('unselected'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Recomendações de sentidos (mostrado quando selecionado)
            AnimatedCrossFade(
              firstChild: Container(),
              secondChild: _buildRecomendacoesSentidos(grupo, cores[corIndex]),
              crossFadeState: grupo.isSelected 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecomendacoesSentidos(GrupoLinha grupo, List<Color> cores) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divisor
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Título das recomendações
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: Colors.blue[600],
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Escolha um sentido:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Lista de sentidos como recomendações
          ...grupo.sentidos.map((linha) {
            final sentido = linha.sentido;
            
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    
                    // Carregar paradas e navegar para o mapa
                    await _carregarParadas(grupo, sentido);
                    _navegarParaMapa(grupo, sentido);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[25],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Indicador de sentido
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cores[1],
                            shape: BoxShape.circle,
                          ),
                        ),
                        
                        SizedBox(width: 12),
                        
                        // Nome do sentido
                        Expanded(
                          child: Text(
                            sentido.isNotEmpty ? sentido : 'Sentido não informado',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        
                        // Botão do mapa
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.map,
                            color: Colors.blue[700],
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Nenhuma linha encontrada'
                : 'Nenhuma linha disponível',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Tente alterar os termos de busca'
                : 'Verifique sua conexão e tente novamente',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _carregarLinhas,
            icon: Icon(Icons.refresh),
            label: Text('Tentar Novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}