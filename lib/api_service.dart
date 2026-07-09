import 'package:flutter/material.dart';
import 'record/record.dart';
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
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _buscarPorTexto() async {
    final texto = _textController.text.trim();
    if (texto.isEmpty) return;
    
    // Apaga o campo de texto imediatamente após o envio
    _textController.clear();
    
    setState(() => _isLoading = true);
    try {
      final resultados = await _apiService.enviarTexto(texto);
      setState(() => _resultados = resultados);
    } catch (e) {
      _mostrarErro(e.toString());
    } finaly {
      setState(() => _isLoading = false);
    }
  }

  // Ativado quando o usuário APENA E SEGURA o microfone
  Future<void> _iniciarGravacao() async {
    if (await Permission.microphone.request().isGranted || kIsWeb) {
      setState(() => _isRecording = true);
      try {
        if (kIsWeb) {
          await _audioRecorder.start(const RecordConfig(), path: '');
        } else {
          final dir = await getTemporaryDirectory();
          final filePath = '${dir.path}/audio_busca.m4a';
          await _audioRecorder.start(const RecordConfig(), path: filePath);
        }
      } catch (e) {
        _mostrarErro("Erro ao iniciar gravação: $e");
        setState(() => _isRecording = false);
      }
    } else {
      _mostrarErro("Permissão de microfone negada.");
    }
  }

  // Ativado quando o usuário SOLTA o microfone
  Future<void> _pararGravacao() async {
    if (!_isRecording) return;
    
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
    } finaly {
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
    } finaly {
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
          // Área de resultados
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
          
          // Barra inferior estilizada de input
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
                
                // Botão de Áudio com detector de pressionamento contínuo
                GestureDetector(
                  onLongPressStart: (_) => _iniciarGravacao(),
                  onLongPressEnd: (_) => _pararGravacao(),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}