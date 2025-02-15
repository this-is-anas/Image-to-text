import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeService {
  final String _baseUrl = 'https://api.anthropic.com/v1/messages';
  final String _apiKey = 'your-api-key-here'; // Replace with valid key
  final String _model = 'claude-3-opus-20240229';

  Future<String> analyzeImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(image.path);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-beta': 'messages-2023-12-15',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mimeType,
                    'data': base64Image,
                  },
                },
                {'type': 'text', 'text': 'Please describe this image in detail'}
              ]
            }
          ]
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Claude analysis failed: ${e.toString()}');
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ext == 'png' ? 'image/png' : 'image/jpeg';
  }

  String _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'];
    }

    print('Claude API Error: ${response.statusCode}');
    print('Response Body: ${response.body}');
    throw Exception('Failed to analyze image: ${response.statusCode}');
  }
}
