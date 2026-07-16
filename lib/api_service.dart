import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // endereço do serviço alocado no render
  final String baseUrl = 'https://gerenciamentodeestoque-uysv.onrender.com/api/busca';

  Future<List<dynamic>> enviarTexto(String texto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pergunta'),
      headers: {'Content-Type': 'text/plain'}, 
      body: texto,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar dados: ${response.body}');
    }
  }

  Future<List<dynamic>> enviarAudio(String audioPath) async {
    var uri = Uri.parse('$baseUrl/perguntar/audio');
    var request = http.MultipartRequest('POST', uri);
    
    request.files.add(await http.MultipartFile.fromPath('audio', audioPath));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao enviar áudio: ${response.body}');
    }
  }


  // Nova função para enviar o áudio quando estiver no Chrome
  Future<List<dynamic>> enviarAudioWeb(List<int> bytes) async {
    var uri = Uri.parse('$baseUrl/perguntar/audio');
    var request = http.MultipartRequest('POST', uri);
    
    // Anexa os bytes da memória diretamente na requisição
    request.files.add(http.MultipartFile.fromBytes(
      'audio', 
      bytes,
      filename: 'audio_gravado.webm'
    ));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao enviar áudio no Web: ${response.body}');
    }
  }
}