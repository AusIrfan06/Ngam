import 'dart:io';
import 'dart:convert';

void main() async {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  Map<String, String> commentMap = {};
  
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('//')) {
        int idx = line.indexOf('//');
        if (idx > 0 && line[idx - 1] == ':') continue;
        
        String commentText = line.substring(idx + 2).trim();
        if (commentText.startsWith('/')) continue;
        if (commentText.endsWith(';') || commentText.contains('){') || commentText.contains('} else {')) continue;
        if (commentText.length < 3) continue;
        if (!RegExp(r'[a-zA-Z]').hasMatch(commentText)) continue;
        if (commentText.contains('ignore:')) continue;
        if (commentText.contains('=')) continue; // likely code
        
        commentMap[commentText] = "";
      }
    }
  }
  
  final file = File('comments_to_translate.json');
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(commentMap));
  print('Found ${commentMap.length} unique comments.');
}
