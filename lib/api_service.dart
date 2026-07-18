import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

// Endereço do serviço alocado no render
  final String baseUrl = 'https://gerenciamentodeestoque-uysv.onrender.com/api/busca';
  final String metricsUrl = 'https://gerenciamentodeestoque-uysv.onrender.com/api'; 

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

  Future<List<dynamic>> enviarAudioWeb(List<int> bytes) async {
    var uri = Uri.parse('$baseUrl/perguntar/audio');
    var request = http.MultipartRequest('POST', uri);
    
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

  // ---- MÉTODOS DO DASHBOARD (Consultas Diretas ao Banco) ----

  Future<Map<String, dynamic>> obterDadosDashboard() async {
    try {
      final response = await http.get(Uri.parse('$metricsUrl/dashboard/resumo'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"total_produtos": 0, "valor_vendas_mes": 0.0, "baixo_estoque_count": 0, "movimentacoes_count": 0};
    } catch (_) {
      return {"total_produtos": 0, "valor_vendas_mes": 0.0, "baixo_estoque_count": 0, "movimentacoes_count": 0};
    }
  }

  Future<List<dynamic>> obterProdutos() async {
    final response = await http.get(Uri.parse('$metricsUrl/produtos'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  Future<List<dynamic>> obterUltimasMovimentacoes() async {
    final response = await http.get(Uri.parse('$metricsUrl/movimentacoes/recentes'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  Future<List<dynamic>> obterProdutosBaixoEstoque() async {
    final response = await http.get(Uri.parse('$metricsUrl/produtos/baixo-estoque'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  Future<List<dynamic>> obterMovimentacoesComTempo() async {
    final response = await http.get(Uri.parse('$metricsUrl/movimentacoes/detalhes-tempo'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }


}