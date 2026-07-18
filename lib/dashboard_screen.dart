// lib/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'busca_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();

  void _mudarAba(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _paginas = [
      DashboardPainel(onNavigate: _mudarAba, apiService: _apiService),
      ProdutosPage(apiService: _apiService),
      HistoricoMovimentacoesPage(apiService: _apiService),
      ContarVendasPage(apiService: _apiService),
      MenuOpcoesPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _currentIndex,
        children: _paginas,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, 'HOME'),
                _buildNavItem(1, Icons.inventory_2_outlined, 'PRODUTOS'),
                _buildNavItem(2, Icons.history_outlined, 'HIST.'),
                _buildNavItem(3, Icons.assignment_outlined, 'CONTAR'),
                _buildNavItem(4, Icons.menu, 'MENU'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _mudarAba(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFE6F7ED), 
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00A859) : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF00A859) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPainel extends StatelessWidget {
  final Function(int) onNavigate;
  final ApiService apiService;

  const DashboardPainel({Key? key, required this.onNavigate, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: apiService.obterDadosDashboard(),
          builder: (context, snapshot) {
            final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
            final dados = snapshot.data ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bom dia",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Resumo rápido do estoque de hoje",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.settings_outlined, color: Colors.grey.shade700, size: 22),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFE6F7ED),
                            child: Text("A", style: TextStyle(color: Color(0xFF00A859), fontWeight: FontWeight.bold, fontSize: 16)),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: [
                      _buildDashboardCard(
                        title: "Produtos",
                        value: isLoading ? "Carregando..." : "${dados['total_produtos'] ?? 0} itens",
                        isLoading: isLoading,
                        icon: Icons.layers_outlined,
                        iconColor: const Color(0xFF00A859),
                        iconBgColor: const Color(0xFFE6F7ED),
                        textColor: const Color(0xFF00A859),
                        onTap: () => onNavigate(1),
                      ),
                      _buildDashboardCard(
                        title: "Valor Total",
                        value: isLoading ? "Carregando..." : "R\$ ${(dados['valor_vendas_mes'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                        isLoading: isLoading,
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        iconBgColor: const Color(0xFFF3E8FF),
                        textColor: const Color(0xFF7C3AED),
                        onTap: () {
                          if (!isLoading) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => UltimasMovimentacoesPage(apiService: apiService)
                            ));
                          }
                        },
                      ),
                      _buildDashboardCard(
                        title: "Baixo estoque",
                        value: isLoading ? "Carregando..." : "${dados['baixo_estoque_count'] ?? 0} alertas",
                        isLoading: isLoading,
                        icon: Icons.warning_amber_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBgColor: const Color(0xFFFEF3C7),
                        textColor: const Color(0xFFD97706),
                        onTap: () {
                          if (!isLoading) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => BaixoEstoquePage(apiService: apiService)
                            ));
                          }
                        },
                      ),
                      _buildDashboardCard(
                        title: "Movimentações",
                        value: isLoading ? "Carregando..." : "${dados['movimentacoes_count'] ?? 0} ações",
                        isLoading: isLoading,
                        icon: Icons.swap_horiz_rounded,
                        iconColor: const Color(0xFF2563EB),
                        iconBgColor: const Color(0xFFDBEAFE),
                        textColor: const Color(0xFF2563EB),
                        onTap: () {
                          if (!isLoading) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => MovimentacoesTempoPage(apiService: apiService)
                            ));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BuscaEstoqueScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.4), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          _buildRobotIcon(),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Text(
                              "Tem dúvidas sobre as mercadorias?\nClique aqui e me pergunte.",
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w500, 
                                color: Color(0xFF1E293B),
                                height: 1.4,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required bool isLoading,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade100, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title, 
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade400)
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 18, color: iconColor),
                  )
                ],
              ),
              const Spacer(),
              Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLoading ? Colors.grey.shade400 : textColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: isLoading ? 14 : 16,
                    fontStyle: isLoading ? FontStyle.italic : FontStyle.normal,
                    height: 1.3,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRobotIcon() {
    return Container(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 2,
            child: Container(width: 3, height: 10, color: const Color(0xFF1E3A8A)),
          ),
          Positioned(
            top: 0,
            child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle)),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: 54,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E3A8A), width: 2.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle)),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle)),
                ],
              ),
            ),
          ),
          Positioned(left: 2, child: Container(width: 5, height: 10, decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(2)))),
          Positioned(right: 2, child: Container(width: 5, height: 10, decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(2)))),
          Positioned(
            top: 6,
            right: 0,
            child: Icon(Icons.chat_bubble_outline_rounded, size: 22, color: const Color(0xFF1E3A8A).withOpacity(0.8)),
          )
        ],
      ),
    );
  }
}

class ProdutosPage extends StatelessWidget {
  final ApiService apiService;
  const ProdutosPage({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Lista de Produtos"), backgroundColor: Colors.white, elevation: 0),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.obterProdutos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final produtos = snapshot.data!;
          return ListView.builder(
            itemCount: produtos.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.shopping_bag, color: Color(0xFF00A859)),
                title: Text(produtos[i]['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Disponível: ${produtos[i]['quantidade'] ?? 0} un"),
                trailing: Text("R\$ ${(produtos[i]['preco'] as num?)?.toStringAsFixed(2) ?? '0.00'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class UltimasMovimentacoesPage extends StatelessWidget {
  final ApiService apiService;
  const UltimasMovimentacoesPage({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Últimas Movimentações"), backgroundColor: Colors.white, elevation: 0),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.obterUltimasMovimentacoes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snapshot.data!;
          return ListView.builder(
            itemCount: lista.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.history_toggle_off, color: Color(0xFF7C3AED)),
              title: Text("Operação: ${lista[i]['tipo'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Produto: ${lista[i]['produto']}"),
              trailing: Text("${lista[i]['quantidade']} un", style: const TextStyle(color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }
}

class BaixoEstoquePage extends StatelessWidget {
  final ApiService apiService;
  const BaixoEstoquePage({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Produtos Críticos"), backgroundColor: Colors.white, elevation: 0),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.obterProdutosBaixoEstoque(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snapshot.data!;
          return ListView.builder(
            itemCount: lista.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.warning_rounded, color: Color(0xFFD97706)),
              title: Text(lista[i]['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Alerta: Apenas ${lista[i]['quantidade']} unidades em estoque."),
            ),
          );
        },
      ),
    );
  }
}

class MovimentacoesTempoPage extends StatelessWidget {
  final ApiService apiService;
  const MovimentacoesTempoPage({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Duração das Ações"), backgroundColor: Colors.white, elevation: 0),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.obterMovimentacoesComTempo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snapshot.data!;
          return ListView.builder(
            itemCount: lista.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.timer_outlined, color: Color(0xFF2563EB)),
              title: Text("${lista[i]['descricao'] ?? ''}"),
              trailing: Text("${lista[i]['tempo_duracao'] ?? '0'} min", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            ),
          );
        },
      ),
    );
  }
}

class HistoricoMovimentacoesPage extends StatelessWidget {
  final ApiService apiService;
  const HistoricoMovimentacoesPage({Key? key, required this.apiService}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Aba de Histórico Geral")));
}

class ContarVendasPage extends StatelessWidget {
  final ApiService apiService;
  const ContarVendasPage({Key? key, required this.apiService}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Aba de Contagem Financeira")));
}

class MenuOpcoesPage extends StatelessWidget {
  const MenuOpcoesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Aba de Menus Administrativos")));
}