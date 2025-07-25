import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:async';
import 'dart:math' as math;
import 'detalhes_linha.dart';
import '../servicos/api_service.dart';
import '../componentes/menu_lateral_melhorado.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../modelos/linha.dart';

class MapScreen extends StatefulWidget {
  final List<dynamic>? paradasDestacadas;
  final String? tituloLinha;
  
  const MapScreen({
    Key? key,
    this.paradasDestacadas,
    this.tituloLinha,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  String? _erroLocalizacao;
  TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Linha> _linhasDisponiveis = [];
  Set<Marker> _paradaMarkers = {};
  Set<Marker> _todasParadasMarkers = {}; // Guarda todos os marcadores
  Marker? _selectedMarker;
  List<dynamic> _proximasPartidas = [];
  
  // Variáveis para lógica avançada de busca (copiadas da tela linhas de ônibus)
  Linha? _linhaSelecionada;
  List<String> _sentidosRecomendados = [];
  bool _mostrandoRecomendacoes = false;
  List<Linha> _sugestoesLinhas = [];
  bool _mostrandoSugestoes = false;

  String _mapStyle = '''[
  {
    "featureType": "poi",
    "elementType": "all",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.bus_station",
    "elementType": "all",
    "stylers": [
      { "visibility": "on" }
    ]
  }
]''';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _carregarLinhas();
  }

  Future<void> _carregarLinhas() async {
    try {
      final linhas = await _apiService.buscarLinhas();
      setState(() {
        _linhasDisponiveis = linhas.map((json) => Linha.fromJson(json)).toList();
      });
    } catch (e) {
      setState(() {
        _linhasDisponiveis = [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarLinhas(String busca) {
    setState(() {
      final buscaTrim = busca.trim().toLowerCase();
      if (buscaTrim.isEmpty) {
        _mostrandoSugestoes = false;
        _sugestoesLinhas = [];
        _linhaSelecionada = null;
        _sentidosRecomendados = [];
        _mostrandoRecomendacoes = false;
        return;
      }
      
      final buscaNormalizada = buscaTrim.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
      final filtradas = _linhasDisponiveis.where((linha) {
        final nomeNormalizado = linha.nome.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');
        final idNormalizado = linha.id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');
        return nomeNormalizado.contains(buscaNormalizada) || idNormalizado.contains(buscaNormalizada);
      }).toList();
      
      _sugestoesLinhas = filtradas.take(5).toList(); // Máximo 5 sugestões
      _mostrandoSugestoes = _sugestoesLinhas.isNotEmpty;
      _linhaSelecionada = null;
      _sentidosRecomendados = [];
      _mostrandoRecomendacoes = false;
    });
  }

  void _selecionarLinhaSugerida(Linha linha, {String? sentido}) async {
    setState(() {
      _searchController.text = linha.nome;
      _linhaSelecionada = linha;
      _sentidosRecomendados = [linha.sentido]; // Para uma linha específica
      _mostrandoRecomendacoes = linha.sentido.isNotEmpty;
      _sugestoesLinhas = [];
      _mostrandoSugestoes = false;
    });
    
    if (sentido != null) {
      try {
        // Carregar paradas da linha antes de navegar
        await _carregarEDestacarParadasDaLinha(linha.id, sentido);
        
        // Navegar diretamente para detalhes da linha
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelaDetalhesLinha(linha: linha),
          ),
        );
      } catch (e) {
        // Em caso de erro, apenas navegar para os detalhes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelaDetalhesLinha(linha: linha),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar paradas: $e')),
        );
      }
    }
  }

  void _selecionarSentidoRecomendado(String sentido) async {
    final linhaSelecionada = _linhaSelecionada;
    if (linhaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: Nenhuma linha selecionada.')),
      );
      return;
    }
    HapticFeedback.lightImpact();
    try {
      await _carregarEDestacarParadasDaLinha(
        linhaSelecionada.id,
        sentido,
        nomeLinha: linhaSelecionada.nome,
      );
      // Removido: não navega mais para a tela de detalhes da linha
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar paradas: $e')),
      );
    }
    _searchController.clear();
    setState(() {
      _linhaSelecionada = null;
      _sentidosRecomendados = [];
      _mostrandoRecomendacoes = false;
    });
    _filtrarLinhas('');
  }

  // Nova função para carregar e destacar paradas de uma linha específica
  Future<void> _carregarEDestacarParadasDaLinha(String codigoLinha, String sentido, {String? nomeLinha}) async {
    try {
      final url = Uri.parse('http://192.168.0.10:5000/linhas/$codigoLinha/paradas');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> paradas = json.decode(response.body);
        List<dynamic> paradasFiltradas = paradas.where((parada) {
          if (parada['sentido'] != null) {
            return parada['sentido'].toString().toLowerCase().contains(sentido.toLowerCase());
          }
          return true;
        }).toList();
        Set<Marker> markers = {};
        List<LatLng> positions = [];
        for (var parada in paradasFiltradas) {
          double? lat, lng;
          String nome = '';
          if (parada['lat'] != null && parada['lng'] != null) {
            lat = parada['lat'] is String ? double.tryParse(parada['lat']) : parada['lat']?.toDouble();
            lng = parada['lng'] is String ? double.tryParse(parada['lng']) : parada['lng']?.toDouble();
            nome = parada['nome'] ?? parada['estacao'] ?? parada['endereco'] ?? '';
          } else if (parada['latitude'] != null && parada['longitude'] != null) {
            lat = parada['latitude'] is String ? double.tryParse(parada['latitude']) : parada['latitude']?.toDouble();
            lng = parada['longitude'] is String ? double.tryParse(parada['longitude']) : parada['longitude']?.toDouble();
            nome = parada['nome'] ?? parada['estacao'] ?? parada['endereco'] ?? '';
          }
          if (lat != null && lng != null && nome.isNotEmpty) {
            final markerId = MarkerId('linha_${codigoLinha}_$nome');
            final position = LatLng(lat, lng);
            positions.add(position);
            final marker = Marker(
              markerId: markerId,
              position: position,
              infoWindow: InfoWindow(
                title: nome,
                snippet: 'Linha:  ${nomeLinha ?? codigoLinha} - Sentido: $sentido',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              onTap: () {
                final clickedMarker = Marker(
                  markerId: markerId,
                  position: position,
                  infoWindow: InfoWindow(
                    title: nome,
                    snippet: 'Linha:  ${nomeLinha ?? codigoLinha} - Sentido: $sentido',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                );
                setState(() {
                  _selectedMarker = clickedMarker;
                  _paradaMarkers = markers.map((m) => m.markerId == markerId ? clickedMarker : m).toSet();
                });
                _mostrarBottomSheetProximasPartidas(nome);
              },
            );
            markers.add(marker);
          }
        }
        setState(() {
          _paradaMarkers = markers;
          _selectedMarker = null;
        });
        if (markers.isNotEmpty && _mapController != null) {
          _ajustarZoomParaParadas(markers);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${markers.length} paradas encontradas para o sentido "$sentido"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Erro ao carregar paradas da linha: $e');
      rethrow;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _erroLocalizacao = null;
      });
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentPosition!),
        );
      }
    } catch (e) {
      setState(() {
        _currentPosition = null;
        _erroLocalizacao = 'Não foi possível obter sua localização. Verifique as permissões do app.';
      });
    }
  }

  // Carrega e mostra as paradas próximas
  Future<void> _mostrarParadasProximas() async {
    final url = Uri.parse('http://192.168.0.10:5000/paradas');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> paradas = json.decode(response.body);
      Set<Marker> markers = {};
      for (var parada in paradas) {
        if (parada['lat'] != null && parada['lng'] != null) {
          markers.add(
            Marker(
              markerId: MarkerId(parada['estacao'] ?? parada['nome'] ?? ''),
              position: LatLng(parada['lat'], parada['lng']),
              infoWindow: InfoWindow(title: parada['estacao'] ?? parada['nome'] ?? ''),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              onTap: () {
                setState(() {
                  _selectedMarker = Marker(
                    markerId: MarkerId(parada['estacao'] ?? parada['nome'] ?? ''),
                    position: LatLng(parada['lat'], parada['lng']),
                    infoWindow: InfoWindow(title: parada['estacao'] ?? parada['nome'] ?? ''),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  );
                  _paradaMarkers = {_selectedMarker!};
                });
                _mostrarBottomSheetProximasPartidas(
                  parada['estacao'] ?? parada['nome'] ?? '',
                );
              },
            ),
          );
        }
      }
      setState(() {
        _paradaMarkers = markers;
        _todasParadasMarkers = markers;
        _selectedMarker = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar paradas do servidor')),
      );
    }
  }

  void _restaurarTodasParadas() {
    setState(() {
      _paradaMarkers = _todasParadasMarkers;
      _selectedMarker = null;
    });
  }

  // Mostra paradas específicas destacadas no mapa
  void _mostrarParadasDestacadas() {
    if (widget.paradasDestacadas == null) return;
    
    Set<Marker> markers = {};
    for (var parada in widget.paradasDestacadas!) {
      // Verificar diferentes possíveis formatos de coordenadas
      double? lat, lng;
      String nome = '';
      
      if (parada['lat'] != null && parada['lng'] != null) {
        lat = parada['lat'] is String ? double.tryParse(parada['lat']) : parada['lat']?.toDouble();
        lng = parada['lng'] is String ? double.tryParse(parada['lng']) : parada['lng']?.toDouble();
        nome = parada['nome'] ?? parada['estacao'] ?? parada['endereco'] ?? '';
      } else if (parada['latitude'] != null && parada['longitude'] != null) {
        lat = parada['latitude'] is String ? double.tryParse(parada['latitude']) : parada['latitude']?.toDouble();
        lng = parada['longitude'] is String ? double.tryParse(parada['longitude']) : parada['longitude']?.toDouble();
        nome = parada['nome'] ?? parada['estacao'] ?? parada['endereco'] ?? '';
      }
      
      if (lat != null && lng != null && nome.isNotEmpty) {
        final markerId = MarkerId('destaque_$nome');
        final position = LatLng(lat, lng);
        final marker = Marker(
          markerId: markerId,
          position: position,
          infoWindow: InfoWindow(
            title: nome,
            snippet: widget.tituloLinha ?? 'Parada da linha',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Azul para destacar
          onTap: () {
            final clickedMarker = Marker(
              markerId: markerId,
              position: position,
              infoWindow: InfoWindow(
                title: nome,
                snippet: widget.tituloLinha ?? 'Parada da linha',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Vermelho quando selecionado
            );
            setState(() {
              _selectedMarker = clickedMarker;
              _paradaMarkers = {clickedMarker};
            });
            
            // Opcional: Mostrar próximas partidas se disponível
            _mostrarBottomSheetProximasPartidas(nome);
          },
        );
        markers.add(marker);
      }
    }
    
    setState(() {
      _paradaMarkers = markers;
      _todasParadasMarkers = markers;
      _selectedMarker = null;
    });
    
    // Ajustar zoom para mostrar todas as paradas destacadas
    if (markers.isNotEmpty && _mapController != null) {
      _ajustarZoomParaParadas(markers);
    }
  }

  // Ajusta o zoom do mapa para mostrar todas as paradas
  void _ajustarZoomParaParadas(Set<Marker> markers) {
    if (markers.isEmpty) return;
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (var marker in markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  // Busca as próximas partidas para a parada e horário atual
  Future<void> _buscarProximasPartidas(String estacao) async {
    final agora = DateFormat('HH:mm').format(DateTime.now());
    final url = Uri.parse('http://192.168.0.10:5000/paradas/' + Uri.encodeComponent(estacao) + '/proximas_partidas?hora=$agora');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        _proximasPartidas = json.decode(response.body);
      });
    } else {
      setState(() {
        _proximasPartidas = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar próximas partidas')),
      );
    }
  }

  // Mostra o bottom sheet com as próximas partidas
  void _mostrarBottomSheetProximasPartidas(String nomeParada) async {
    await _buscarProximasPartidas(nomeParada);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              child: _proximasPartidas.isEmpty
                  ? Center(child: Text('Nenhuma partida futura para esta parada.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _proximasPartidas.length,
                      itemBuilder: (context, index) {
                        final partida = _proximasPartidas[index];
                        return ListTile(
                          leading: Icon(Icons.directions_bus, color: Colors.blue),
                          title: Text('Linha ${partida['linha']}'),
                          subtitle: Text('Sentido: ${partida['sentido']}\nHorário: ${partida['horario']}'),
                        );
                      },
                    ),
            );
          },
        );
      },
    ).whenComplete(() {
      _restaurarTodasParadas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.tituloLinha != null 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Rota',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Bus',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.tituloLinha!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              )
            : RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Rota',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'Bus',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3.0,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        backgroundColor: Colors.transparent, // Transparente para mostrar gradiente
        foregroundColor: Colors.white,
        elevation: 0, // Remove sombra padrão
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[600]!,
                Colors.blue[700]!,
                Colors.blue[800]!,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 26,
        ),
        toolbarHeight: 65, // Altura maior para visual mais moderno
        actions: [
          // Botão para mostrar todas as paradas
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: _mostrarParadasProximas,
            tooltip: 'Mostrar todas as paradas',
          ),
          // Botão para limpar paradas destacadas
          if (_paradaMarkers.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  _paradaMarkers.clear();
                  _selectedMarker = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Paradas destacadas removidas'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              tooltip: 'Limpar paradas destacadas',
            ),
        ],
      ),
      drawer: MenuLateralMelhorado(
        onParadasProximas: _mostrarParadasProximas,
      ),
      body: _erroLocalizacao != null
          ? Center(child: Text(_erroLocalizacao!, style: TextStyle(color: Colors.red, fontSize: 18)))
          : _currentPosition == null
              ? Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 18, // Zoom maior para mais detalhes
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _mapController?.setMapStyle(_mapStyle);
                        
                        // Se há paradas destacadas, mostra-las quando o mapa estiver pronto
                        if (widget.paradasDestacadas != null && widget.paradasDestacadas!.isNotEmpty) {
                          Future.delayed(Duration(milliseconds: 500), () {
                            _mostrarParadasDestacadas();
                          });
                        }
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: _paradaMarkers,
                    ),
                    // BARRA DE PESQUISA
                    Positioned(
                      top: 10, // Mais próximo da AppBar
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          // Campo de busca
                          Container(
                            height: 60, // Altura fixa maior
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3), // Sombra mais forte
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Digite a linha: (ex: linha 01)',
                                hintStyle: TextStyle(color: Colors.grey),
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
                              onChanged: (value) {
                                _filtrarLinhas(value);
                              },
                            ),
                          ),

                          // Recomendações de sentidos (aparecem quando uma linha é selecionada)
                          if (_mostrandoRecomendacoes && _sentidosRecomendados.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(top: 8),
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

                          // Lista de sugestões melhorada
                          if (_mostrandoSugestoes && _sugestoesLinhas.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _sugestoesLinhas.length,
                                itemBuilder: (context, index) {
                                  final linha = _sugestoesLinhas[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: index < _sugestoesLinhas.length - 1
                                          ? Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1))
                                          : null,
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      leading: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.directions_bus, color: Colors.blue[700], size: 20),
                                      ),
                                      title: Text(
                                        linha.nome,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: linha.sentido.isNotEmpty
                                          ? Text(
                                              'Sentido: ${linha.sentido}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                                      onTap: () => _selecionarLinhaSugerida(linha),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
