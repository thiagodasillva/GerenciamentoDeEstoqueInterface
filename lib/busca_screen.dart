import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'web_feedback_stub.dart'
    if (dart.library.js) 'web_feedback_web.dart';

class BuscaEstoqueScreen extends StatefulWidget {
  @override
  _BuscaEstoqueScreenState createState() => _BuscaEstoqueScreenState();
}

class _BuscaEstoqueScreenState extends State<BuscaEstoqueScreen> {
  final TextEditingController _textController = TextEditingController();
  final ApiService _apiService = ApiService();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isLoading = false;
  List<dynamic> _resultados = [];
  List<String> _pesquisasPredefinidas = [];

  @override
  void initState() {
    super.initState();
    _carregarPesquisasPredefinidas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarPopupInformativo();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _carregarPesquisasPredefinidas() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pesquisasPredefinidas = prefs.getStringList('pesquisas_rapidas') ?? [];
    });
  }

  Future<void> _salvarPesquisasPredefinidas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pesquisas_rapidas', _pesquisasPredefinidas);
  }

  void _adicionarPesquisaPredefinida(String texto) {
    if (texto.isEmpty) return;

    // Validação extra de segurança para os 50 caracteres
    if (texto.length > 50) {
      _mostrarErro('A pesquisa não pode ter mais de 50 caracteres.');
      return;
    }

    if (_pesquisasPredefinidas.length >= 5) {
      _mostrarErro('Você já atingiu o limite de 5 pesquisas predefinidas.');
      return;
    }

    setState(() {
      _pesquisasPredefinidas.add(texto);
    });
    _salvarPesquisasPredefinidas();
  }

  void _removerPesquisaPredefinida(String texto) {
    setState(() {
      _pesquisasPredefinidas.remove(texto);
    });
    _salvarPesquisasPredefinidas();
  }

  // Janela pop-up acionada ao SEGURAR o botão por alguns instantes
  void _mostrarDialogDeletarPesquisa(String texto) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Apagar Pesquisa'),
            ],
          ),
          content: Text('Deseja remover a pesquisa rápida abaixo?\n\n"$texto"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _removerPesquisaPredefinida(texto);
                Navigator.pop(context);
              },
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogAdicionarPesquisa() {
    final TextEditingController _dialogController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nova Pesquisa Predefinida'),
          content: TextField(
            controller: _dialogController,
            autofocus: true,
            maxLength: 50, // Limitador nativo do teclado Android (Exibe o contador 0/50)
            decoration: const InputDecoration(
              hintText: 'Ex: Qual o produto mais vendido?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _adicionarPesquisaPredefinida(_dialogController.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemInformativo(
    BuildContext context,
    IconData icon,
    String titulo,
    String descricao,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descricao,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarPopupInformativo() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Center(
          child: Dismissible(
            key: const Key('info_popup_dismiss'),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              Navigator.of(context).pop();
            },
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 12,
              backgroundColor: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(24),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warehouse_rounded,
                                size: 40,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'Guia do Assistente',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildItemInformativo(
                            context,
                            Icons.help_outline_rounded,
                            'Para que serve?',
                            'O sistema agiliza sua busca por mercadorias utilizando Inteligência Artificial por reconhecimento de voz e envio de texto.',
                          ),
                          const SizedBox(height: 20),

                          _buildItemInformativo(
                            context,
                            Icons.admin_panel_settings_outlined,
                            'Seu papel como Gestor',
                            'Como gestor, você monitora em tempo real e valida a quantidade, relaciona os produtos com as vendas e acessa o status atualizado do inventário.',
                          ),
                          const SizedBox(height: 20),

                          _buildItemInformativo(
                            context,
                            Icons.manage_search_rounded,
                            'Tipos de busca disponíveis',
                            '• Por nome do produto: "Quantas unidades do Notebook temos no estoque?"\n• Por número de vendas: "Qual o produto mais vendido?"\n• Por quantidade: "Quais itens estão abaixo de 10 unidades?"',
                          ),
                          const SizedBox(height: 32),

                          const Center(
                            child: Text(
                              'Dica: deslize este card para fechar',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Entendido, vamos lá!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      right: -12,
                      top: -12,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[100],
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _buscarPorTexto() async {
    final texto = _textController.text.trim();
    if (texto.isEmpty) return;

    _textController.clear();

    setState(() => _isLoading = true);
    try {
      final resultados = await _apiService.enviarTexto(texto);
      setState(() => _resultados = resultados);
    } catch (e) {
      _mostrarErro(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _reproduzirFeedbackSonoroInicio() {
    if (kIsWeb) {
      try {
        playWebAudioFeedback();
      } catch (e) {
        debugPrint('Erro de inicialização do AudioContext Web: $e');
      }
    } else {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _iniciarGravacao() async {
    if (await Permission.microphone.request().isGranted || kIsWeb) {
      _reproduzirFeedbackSonoroInicio();

      setState(() => _isRecording = true);
      try {
        if (kIsWeb) {
          await _audioRecorder.start(RecordConfig(), path: '');
        } else {
          final dir = await getTemporaryDirectory();
          final filePath = '${dir.path}/audio_busca.m4a';
          await _audioRecorder.start(RecordConfig(), path: filePath);
        }
      } catch (e) {
        _mostrarErro("Erro ao iniciar gravação: $e");
        setState(() => _isRecording = false);
      }
    } else {
      _mostrarErro("Permissão de microfone negada.");
    }
  }

  Future<void> _pararGravacao() async {
    if (!_isRecording) return;

    await HapticFeedback.lightImpact();

    setState(() => _isRecording = false);
    try {
      final path = await _audioRecorder.stop();

      if (path != null) {
        if (kIsWeb) {
          final response = await http.get(Uri.parse(path));
          _enviarAudioParaApiWeb(response.bodyBytes);
        } else {
          _enviarAudioParaApi(path);
        }
      }
    } catch (e) {
      _mostrarErro("Erro ao finalizar gravação: $e");
    }
  }

  Future<void> _enviarAudioParaApi(String path) async {
    setState(() => _isLoading = true);
    try {
      final resultados = await _apiService.enviarAudio(path);
      setState(() => _resultados = resultados);
    } catch (e) {
      _mostrarErro(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarAudioParaApiWeb(List<int> bytes) async {
    setState(() => _isLoading = true);
    try {
      final resultados = await _apiService.enviarAudioWeb(bytes);
      setState(() => _resultados = resultados);
    } catch (e) {
      _mostrarErro(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assistente de Estoque',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: _resultados.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Voltar ao Início',
                  onPressed: () {
                    setState(() {
                      _resultados = [];
                    });
                  },
                )
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _resultados.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum resultado ainda.\nFaça uma busca ou use um atalho rápido abaixo:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '(Segure um atalho para apagá-lo)',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10, 
                            runSpacing: 10, 
                            children: [
                              ..._pesquisasPredefinidas.map((search) {
                                return GestureDetector(
                                  onTap: () {
                                    _textController.text = search;
                                    _buscarPorTexto();
                                  },
                                  onLongPress: () {
                                    // Detecta que o usuário segurou o botão e abre a função de deletar
                                    _mostrarDialogDeletarPesquisa(search);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: colorScheme.primary.withOpacity(0.3),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18, 
                                      vertical: 12
                                    ),
                                    child: Text(
                                      search,
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),

                              if (_pesquisasPredefinidas.length < 5)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: const StadiumBorder(),
                                    side: BorderSide(color: colorScheme.primary, width: 1.5),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: _mostrarDialogAdicionarPesquisa,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text(
                                    'add Pesquisa',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _resultados.length,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemBuilder: (context, index) {
                      final item = _resultados[index] as Map<String, dynamic>;

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${e.key}: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${e.value}',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 24,
              top: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _buscarPorTexto(),
                    decoration: InputDecoration(
                      hintText: 'Pergunte algo sobre o estoque...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: colorScheme.primary,
                  onPressed: _buscarPorTexto,
                ),
                const SizedBox(width: 4),

                GestureDetector(
                  onLongPressStart: (_) => _iniciarGravacao(),
                  onLongPressEnd: (_) => _pararGravacao(),
                  child: AnimatedScale(
                    scale: _isRecording ? 1.5 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.redAccent
                            : colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: _isRecording
                            ? [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
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