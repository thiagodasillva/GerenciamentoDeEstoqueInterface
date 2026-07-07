import 'package:flutter/material.dart';
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
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _buscarPorTexto() async {
    if (_textController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final resultados = await _apiService.enviarTexto(_textController.text);
      setState(() => _resultados = resultados);
    } catch (e) {
      _mostrarErro(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Parar gravação
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        if (kIsWeb) {
          // SE FOR NO CHROME: 'path' é um link temporário na memória. Precisamos baixar os bytes.
          final response = await http.get(Uri.parse(path));
          _enviarAudioParaApiWeb(response.bodyBytes);
        } else {
          // SE FOR NO CELULAR: 'path' é o endereço do arquivo físico.
          _enviarAudioParaApi(path);
        }
      }
    } else {
      // Iniciar gravação
      if (await Permission.microphone.request().isGranted || kIsWeb) {
        if (kIsWeb) {
          // CORREÇÃO AQUI: Passamos 'path: ''' porque o pacote exige o parâmetro,
          // mas o Chrome vai ignorar o texto e gravar em formato Blob na memória.
          await _audioRecorder.start(const RecordConfig(), path: '');
        } else {
          // No Celular, salvamos na pasta temporária normalmente
          final dir = await getTemporaryDirectory();
          final filePath = '${dir.path}/audio_busca.m4a';
          await _audioRecorder.start(const RecordConfig(), path: filePath);
        }
        setState(() => _isRecording = true);
      } else {
        _mostrarErro("Permissão de microfone negada.");
      }
    }
  }


  // Envia o áudio do Celular (Arquivo físico)
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

  // Envia o áudio do Chrome (Memória RAM)
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












  // Future<void> _toggleRecording() async {
  //   if (_isRecording) {
  //     // Parar gravação e enviar
  //     final path = await _audioRecorder.stop();
  //     setState(() => _isRecording = false);
      
  //     if (path != null) {
  //       _enviarAudioParaApi(path);
  //     }
  //   } else {
  //     // Iniciar gravação
  //     if (await Permission.microphone.request().isGranted) {
  //       final dir = await getTemporaryDirectory();
  //       final filePath = '${dir.path}/audio_busca.m4a'; // Whisper lida bem com diversos formatos
        
  //       await _audioRecorder.start(const RecordConfig(), path: filePath);
  //       setState(() => _isRecording = true);
  //     } else {
  //       _mostrarErro("Permissão de microfone negada.");
  //     }
  //   }
  // }

  // Future<void> _enviarAudioParaApi(String path) async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final resultados = await _apiService.enviarAudio(path);
  //     setState(() => _resultados = resultados);
  //   } catch (e) {
  //     _mostrarErro(e.toString());
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }
















  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente de Estoque')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _resultados.isEmpty
                    ? const Center(child: Text('Nenhum resultado. Faça uma busca.'))
                    : ListView.builder(
                        itemCount: _resultados.length,
                        itemBuilder: (context, index) {
                          final item = _resultados[index] as Map<String, dynamic>;
                          // Como não sabemos as colunas do SQL com antecedência, 
                          // renderizamos todas as chaves e valores retornados.
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: item.entries.map((e) => Text(
                                  '${e.key}: ${e.value}', 
                                  style: const TextStyle(fontSize: 16),
                                )).toList(),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Pergunte algo sobre o estoque...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _buscarPorTexto,
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  color: _isRecording ? Colors.red : Colors.blue,
                  onPressed: _toggleRecording,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}