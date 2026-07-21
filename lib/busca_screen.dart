import 'package:flutter/material.dart';
import 'api_service.dart';

class BuscaEstoqueScreen extends StatefulWidget {
  const BuscaEstoqueScreen({Key? key}) : super(key: key);

  @override
  State<BuscaEstoqueScreen> createState() => _BuscaEstoqueScreenState();
}

class _BuscaEstoqueScreenState extends State<BuscaEstoqueScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _mensagens = [];
  bool _carregando = false;
  
  // Flag para identificar se a IA está aguardando confirmação do alerta
  bool _aguardandoConfirmacaoBaixoEstoque = false;

  @override
  void initState() {
    super.initState();
    _iniciarConversaProativa();
  }

  /// Verifica o estoque no momento em que a tela abre e define a mensagem proativa da IA
  Future<void> _iniciarConversaProativa() async {
    setState(() => _carregando = true);
    try {
      final produtosBaixoEstoque = await _apiService.obterProdutosBaixoEstoque();

      if (produtosBaixoEstoque.isNotEmpty) {
        _aguardandoConfirmacaoBaixoEstoque = true;
        _adicionarMensagemIA(
          "Olá! Notei que existem ${produtosBaixoEstoque.length} produto(s) com quantidade baixa no estoque. Quer saber quais são?"
        );
      } else {
        _adicionarMensagemIA(
          "Olá! Como posso ajudar você hoje? Pergunte algo sobre o banco de dados ou digite o nome de um produto."
        );
      }
    } catch (_) {
      _adicionarMensagemIA(
        "Olá! Como posso ajudar você hoje? Faça uma pergunta sobre o estoque."
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _adicionarMensagemIA(String texto) {
    setState(() {
      _mensagens.add({'remetente': 'ia', 'texto': texto});
    });
    _rolarParaFim();
  }

  void _adicionarMensagemUsuario(String texto) {
    setState(() {
      _mensagens.add({'remetente': 'usuario', 'texto': texto});
    });
    _rolarParaFim();
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarMensagem() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    _controller.clear();
    _adicionarMensagemUsuario(texto);

    String promptFinal = texto;

    // Se a IA ofereceu o relatório e o usuário respondeu afirmativamente
    if (_aguardandoConfirmacaoBaixoEstoque) {
      _aguardandoConfirmacaoBaixoEstoque = false;
      final textoBaixo = texto.toLowerCase();

      final intencoesAfirmativas = ['sim', 's', 'quero', 'quero sim', 'quais sao', 'quais são', 'mostre', 'ver', 'por favor'];

      if (intencoesAfirmativas.any((palavra) => textoBaixo.contains(palavra))) {
        promptFinal = "quais produtos estão com quantidade baixa no estoque";
      }
    }

    setState(() => _carregando = true);

    try {
      final resposta = await _apiService.enviarTexto(promptFinal);
      final textoFormatado = _formatarResposta(resposta);
      _adicionarMensagemIA(textoFormatado);
    } catch (e) {
      _adicionarMensagemIA("Erro ao consultar o servidor: $e");
    } finally {
      setState(() => _carregando = false);
    }
  }

  String _formatarResposta(List<dynamic> resposta) {
    if (resposta.isEmpty) return "Nenhum resultado encontrado no banco.";

    StringBuffer buffer = StringBuffer();
    for (var item in resposta) {
      if (item is Map) {
        item.forEach((chave, valor) {
          final chaveFormatada = chave.toString().replaceAll('_', ' ').toUpperCase();
          buffer.writeln("• $chaveFormatada: $valor");
        });
        buffer.writeln();
      } else {
        buffer.writeln(item.toString());
      }
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Assistente de Estoque IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _mensagens.length,
              itemBuilder: (context, index) {
                final msg = _mensagens[index];
                final isIA = msg['remetente'] == 'ia';

                return Align(
                  alignment: isIA ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isIA ? Colors.white : const Color(0xFF00A859),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isIA ? Radius.zero : const Radius.circular(16),
                        bottomRight: isIA ? const Radius.circular(16) : Radius.zero,
                      ),
                      border: isIA ? Border.all(color: Colors.grey.shade200) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      msg['texto'] ?? '',
                      style: TextStyle(
                        color: isIA ? const Color(0xFF1E293B) : Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A859)),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _enviarMensagem(),
                    decoration: InputDecoration(
                      hintText: "Pergunte algo ao assistente...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: const Color(0xFFF1F5F9),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF00A859)),
                  onPressed: _enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}