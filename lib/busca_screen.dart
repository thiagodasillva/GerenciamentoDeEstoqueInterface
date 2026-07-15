import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Fornece feedback sonoro e tátil nativo
import 'package:record/record.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    // Dispara o popup informativo assim que a primeira renderização do frame terminar
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

  Widget _buildItemInformativo(BuildContext context, IconData icon, String titulo, String descricao) {
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
      barrierDismissible: true, // Permite fechar tocando fora do card
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Center(
          child: Dismissible(
            key: const Key('info_popup_dismiss'),
            direction: DismissDirection.horizontal, // Permite arrastar para esquerda ou direita para fechar
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
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Botão para fechar "X" localizado no canto superior direito
                    Positioned(
                      right: -12,
                      top: -12,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[100],
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: Colors.grey, size: 20),
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

  Future<void> _iniciarGravacao() async {
    if (await Permission.microphone.request().isGranted || kIsWeb) {
      // Toca um clique sonoro e gera uma vibração ao iniciar
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();

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
    
    // Pequena vibração tátil sutil ao soltar o dedo
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
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _resultados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum resultado.\nFaça uma busca por texto ou segure o microfone.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _resultados.length,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemBuilder: (context, index) {
                          final item = _resultados[index] as Map<String, dynamic>;
                          
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: item.entries.map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    scale: _isRecording ? 1.25 : 1.0, // Amplia o botão de audio 25% enquanto pressionado
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutBack, // Curva elástica estilizada
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.redAccent : colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: _isRecording ? [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 3,
                          )
                        ] : null,
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