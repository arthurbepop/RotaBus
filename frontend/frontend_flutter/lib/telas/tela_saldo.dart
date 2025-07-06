import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../servicos/saldo_manager_corrigido.dart';

class TelaSaldo extends StatefulWidget {
  @override
  _TelaSaldoState createState() => _TelaSaldoState();
}

class _TelaSaldoState extends State<TelaSaldo> with TickerProviderStateMixin {
  late SaldoManagerCorrigido _saldoManager;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _saldoManager = SaldoManagerCorrigido();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Listener para atualizar a UI quando o saldo mudar
    _saldoManager.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSaldoVisibilidade() {
    _saldoManager.toggleSaldoVisibilidade();
    HapticFeedback.lightImpact();
  }

  void _mostrarDialogRecarga() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return _buildBottomSheetRecarga();
      },
    );
  }

  Widget _buildBottomSheetRecarga() {
    List<double> valoresRecarga = [10.00, 20.00, 50.00, 100.00];
    
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle do bottom sheet
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          
          // Título
          Text(
            'Recarregar Saldo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 24),
          
          // Valores pré-definidos
          Text(
            'Escolha um valor:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: valoresRecarga.length,
            itemBuilder: (context, index) {
              final valor = valoresRecarga[index];
              return _buildBotaoRecarga(valor);
            },
          ),
          
          SizedBox(height: 20),
          
          // Valor personalizado
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _mostrarDialogValorPersonalizado();
            },
            icon: Icon(Icons.edit),
            label: Text('Valor Personalizado'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBotaoRecarga(double valor) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        _processarRecarga(valor);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Text(
        'R\$ ${valor.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _mostrarDialogValorPersonalizado() {
    TextEditingController valorController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Valor Personalizado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Digite o valor que deseja recarregar:'),
              SizedBox(height: 16),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor (R\$)',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final valor = double.tryParse(valorController.text);
                if (valor != null && valor > 0) {
                  Navigator.pop(context);
                  _processarRecarga(valor);
                }
              },
              child: Text('Recarregar'),
            ),
          ],
        );
      },
    );
  }

  void _processarRecarga(double valor) {
    _saldoManager.adicionarRecarga(valor);
    
    // Animação de sucesso
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Feedback visual
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Recarga de R\$ ${valor.toStringAsFixed(2)} realizada!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meu Saldo'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[600]!,
                Colors.green[700]!,
                Colors.green[800]!,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Card do saldo
            Container(
              margin: EdgeInsets.all(16),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildCardSaldo(),
              ),
            ),
            
            // Ações rápidas
            _buildAcoesRapidas(),
            
            // Histórico de transações
            Expanded(
              child: _buildHistoricoTransacoes(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSaldo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[600]!,
            Colors.green[700]!,
            Colors.green[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Disponível',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: _toggleSaldoVisibilidade,
                icon: Icon(
                  _saldoManager.saldoVisivel ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _saldoManager.saldoVisivel 
                ? _saldoManager.saldoFormatado
                : 'R\$ ••••',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text(
                'Cartão Virtual RotaBus',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcoesRapidas() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildBotaoAcao(
              icon: Icons.add,
              label: 'Recarregar',
              color: Colors.green,
              onPressed: _mostrarDialogRecarga,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildBotaoAcao(
              icon: Icons.qr_code,
              label: 'QR Code',
              color: Colors.blue,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('QR Code para pagamento')),
                );
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildBotaoAcao(
              icon: Icons.share,
              label: 'Compartilhar',
              color: Colors.orange,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Compartilhar saldo')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoAcao({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoTransacoes() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico de Transações',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _saldoManager.transacoes.length,
              itemBuilder: (context, index) {
                final transacao = _saldoManager.transacoes[index];
                return _buildItemTransacao(transacao);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTransacao(Map<String, dynamic> transacao) {
    final isRecarga = transacao['tipo'] == 'recarga';
    final color = isRecarga ? Colors.green : Colors.red;
    final icon = isRecarga ? Icons.add_circle : Icons.remove_circle;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transacao['descricao'],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatarData(transacao['data']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isRecarga ? '+' : ''}R\$ ${transacao['valor'].toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Saldo: R\$ ${transacao['saldo_atual'].toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);
    
    if (diferenca.inDays == 0) {
      if (diferenca.inHours == 0) {
        return '${diferenca.inMinutes}min atrás';
      }
      return '${diferenca.inHours}h atrás';
    } else if (diferenca.inDays == 1) {
      return 'Ontem';
    } else {
      return '${diferenca.inDays} dias atrás';
    }
  }
}