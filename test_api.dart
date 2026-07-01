import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String apiKey = '';
  for (var line in lines) {
    if (line.startsWith('NVIDIA_API_KEY=')) {
      apiKey = line.split('=')[1];
      break;
    }
  }

  print('Key: ' + apiKey.substring(0, 5) + '...');
  
  final response = await http.post(
    Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + apiKey,
    },
    body: jsonEncode({
      "model": "meta/llama-3.1-8b-instruct",
      "messages": [
        {"role": "user", "content": "Hi"}
      ],
      "max_tokens": 10
    }),
  );
  
  print('Status: ' + response.statusCode.toString());
  print('Body: ' + response.body);
}
