import 'package:flutter/material.dart';
import 'api_service.dart';
import 'busca_screen.dart';

class MainNavigationScreen extends StatefulWidget {
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
      body: IndexedStack(
        index: _currentIndex,
        children: _paginas,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BuscaEstoqueScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.psychology, size: 28, color: Colors.white),
        label: const Text("Pesquisa IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      // Posicionado no canto inferior direito para não sobrepor o menu de 5 botões
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _mudarAba,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Produtos'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'Contar'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }
}

class DashboardPainel extends StatelessWidget {
  final Function(int) onNavigate;
  final ApiService apiService;

  const DashboardPainel({required this.onNavigate, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Estoque', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade50,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: apiService.obterDadosDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final dados = snapshot.data ?? {};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  title: "Produtos",
                  value: "${dados['total_produtos'] ?? 0} itens",
                  icon: Icons.inventory_2,
                  color: Colors.blue.shade400,
                  onTap: () => onNavigate(1),
                ),
                _buildDashboardCard(
                  title: "Valor Total",
                  value: "R\$ ${(dados['valor_vendas_mes'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                  icon: Icons.attach_money,
                  color: Colors.green.shade400,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => UltimasMovimentacoesPage(apiService: apiService)
                    ));
                  },
                ),
                _buildDashboardCard(
                  title: "Baixo Estoque",
                  value: "${dados['baixo_estoque_count'] ?? 0} alertas",
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange.shade400,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => BaixoEstoquePage(apiService: apiService)
                    ));
                  },
                ),
                _buildDashboardCard(
                  title: "Movimentações",
                  value: "${dados['movimentacoes_count'] ?? 0} ações",
                  icon: Icons.swap_horiz,
                  color: Colors.purple.shade400,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => MovimentacoesTempoPage(apiService: apiService)
                    ));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SUBPÁGINAS DO APP ---

class ProdutosPage extends StatelessWidget {
  final ApiService apiService;
  const ProdutosPage({required this.apiService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Produtos")),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.obterProdutos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final produtos = snapshot.data!;
          if (produtos.isEmpty) return const Center(child: Text("Nenhum produto cadastrado"));
          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.blue),
              title: Text(produtos[i]['nome'] ?? 'Sem nome'),
              subtitle: Text("Qtd: ${produtos[i]['quantidade'] ?? 0} | Preço: R\$ ${(produtos[i]['preco'] as num?)?.toStringAsFixed(2) ?? '0.00'}"),
            ),
          );
        },
      ),
    );
  }
}

class UltimasMovimentacoesPage extends StatelessWidget {
  final ApiService apiService;
  const UltimasMovimentacoesPage({required this.apiService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Últimas Movimentações")),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.obterUltimasMovimentacoes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snapshot.data!;
          if (lista.isEmpty) return const Center(child: Text("Nenhuma movimentação recente"));
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.history_toggle_off, color: Colors.green),
              title: Text("Operação: ${lista[i]['tipo'] ?? ''}"),
              subtitle: Text("Produto: ${lista[i]['produto']} | Quantidade: ${lista[i]['quantidade']}"),
            ),
          );
        },
      ),
    );
  }
}

class BaixoEstoquePage extends StatelessWidget {
  final ApiService apiService;
  const BaixoEstoquePage({required this.apiService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Produtos Alerta de Estoque"), backgroundColor: Colors.orange.shade100),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.obterProdutosBaixoEstoque(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snapshot.data!;
          if (lista.isEmpty) return const Center(child: Text("Todos os produtos com estoque saudável!"));
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(lista[i]['nome'] ?? ''),
              subtitle: Text("Quantidade Crítica: ${lista[i]['quantidade']} restantes"),
            ),
          );
        },
      ),
    );
  }
}

class MovimentacoesTempoPage extends StatelessWidget {
  final ApiService apiService;
  const MovimentacoesTempoPage({required this.apiService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movimentações e Duração")),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.obterMovimentacoesComTempo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snapshot.data!;
          if (lista.isEmpty) return const Center(child: Text("Sem registros de tempo"));
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.timer, color: Colors.purple),
              title: Text("${lista[i]['descricao'] ?? ''}"),
              trailing: Text("${lista[i]['tempo_duracao'] ?? '0'} min", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}

class HistoricoMovimentacoesPage extends StatelessWidget {
  final ApiService apiService;
  const HistoricoMovimentacoesPage({required this.apiService});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Histórico Geral")), body: const Center(child: Text("Página de Histórico de Movimentações Completo")));
}

class ContarVendasPage extends StatelessWidget {
  final ApiService apiService;
  const ContarVendasPage({required this.apiService});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Faturamento Total")), body: const Center(child: Text("Painel do Valor Total de Vendas Acumuladas")));
}

class MenuOpcoesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Menu Administrativo")), body: const Center(child: Text("Outros Assuntos e Configurações")));
}