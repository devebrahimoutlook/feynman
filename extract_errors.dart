import 'dart:convert';
import 'dart:io';

void main() async {
  final lines = await File('test_results.json').readAsLines();
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    try {
      final json = jsonDecode(line);
      if (json['type'] == 'error') {
        print(json['error']);
      }
    } catch (_) {}
  }
}
