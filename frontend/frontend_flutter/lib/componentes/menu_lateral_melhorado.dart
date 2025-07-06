import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../telas/tela_saldo.dart';
import '../telas/linhas_onibus.dart';
import '../servicos/saldo_manager_corrigido.dart';

class MenuLateralMelhorado extends StatelessWidget {
  final VoidCallback? onParadasProximas;
  MenuLateralMelhorado({this.onParadasProximas});

  @override
  Widget build(BuildContext context) {
    final saldoManager = SaldoManagerCorrigido();
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header do menu
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[600]!,
                  Colors.blue[700]!,
                  Colors.blue[800]!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Ícone do app
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Rota',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Bus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2.0,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Transporte Público - Santa Cruz do Sul',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // SEÇÃO: TRANSPORTE
          _buildSectionHeader('TRANSPORTE'),
          
          // Linhas de Ônibus (Funcional)
          _buildMenuItem(
            context: context,
            icon: Icons.directions_bus,
            iconColor: Colors.blue,
            title: 'Linhas de Ônibus',
            isActive: true,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (context) => TelaLinhasOnibus()));
            },
          ),
          
          // Paradas Próximas (Funcional)
          _buildMenuItem(
            context: context,
            icon: Icons.location_on,
            iconColor: Colors.green,
            title: 'Paradas Próximas',
            isActive: true,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              if (onParadasProximas != null) {
                onParadasProximas!();
              }
            },
          ),
          
          // Horários (Em desenvolvimento)
          _buildMenuItem(
            context: context,
            icon: Icons.schedule,
            iconColor: Colors.orange,
            title: 'Horários',
            isActive: false,
            badge: 'BREVE',
            badgeColor: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              _showDevelopmentSnackBar(context, 'Visualização de horários em desenvolvimento');
            },
          ),
          
          // Rotas Favoritas (Nova funcionalidade)
          _buildMenuItem(
            context: context,
            icon: Icons.favorite,
            iconColor: Colors.red,
            title: 'Rotas Favoritas',
            isActive: false,
            badge: 'NOVO',
            badgeColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              _showDevelopmentSnackBar(context, 'Salve suas rotas favoritas');
            },
          ),
          
          // Divisor entre seções
          _buildDivider(),
          
          // SEÇÃO: CONTA
          _buildSectionHeader('CONTA'),
          
          // Saldo
          _buildMenuItem(
            context: context,
            icon: Icons.account_balance_wallet,
            iconColor: Colors.grey[600]!,
            title: 'Saldo',
            isActive: true,
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                saldoManager.saldoFormatado,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TelaSaldo()),
              );
            },
          ),
          
          // Histórico de Viagens
          _buildMenuItem(
            context: context,
            icon: Icons.history,
            iconColor: Colors.grey[600]!,
            title: 'Histórico',
            isActive: false,
            badge: 'BREVE',
            badgeColor: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              _showDevelopmentSnackBar(context, 'Histórico de viagens em desenvolvimento');
            },
          ),
          
          // Divisor entre seções
          _buildDivider(),
          
          // SEÇÃO: CONFIGURAÇÕES
          _buildSectionHeader('CONFIGURAÇÕES'),
          
          // Configurações
          _buildMenuItem(
            context: context,
            icon: Icons.settings,
            iconColor: Colors.grey[600]!,
            title: 'Configurações',
            isActive: true,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              _showSnackBar(context, 'Configurações do aplicativo', Colors.grey[600]!);
            },
          ),
          
          // Sobre
          _buildMenuItem(
            context: context,
            icon: Icons.info,
            iconColor: Colors.grey[600]!,
            title: 'Sobre',
            isActive: true,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              _showAboutDialog(context);
            },
          ),
          
          // Espaço extra no final
          SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
  
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? iconColor.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            color: isActive ? iconColor : Colors.grey[500], 
            size: 20
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? Colors.orange).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (badgeColor ?? Colors.orange).withOpacity(0.4), 
                    width: 1
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? Colors.orange[800],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: trailing ?? (isActive 
          ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400])
          : Icon(Icons.construction, size: 16, color: Colors.orange[400])
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Divider(color: Colors.grey[300], thickness: 1),
    );
  }
  
  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _showDevelopmentSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.construction, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'RotaBus',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(Icons.directions_bus, color: Colors.white, size: 30),
      ),
      children: [
        SizedBox(height: 16),
        Text('Aplicativo de transporte público para Santa Cruz do Sul.'),
        SizedBox(height: 8),
        Text('Desenvolvido para facilitar o acesso às informações de ônibus da cidade.'),
      ],
    );
  }
}