import 'dart:convert';

import 'package:http/http.dart' as http;

typedef JsonMap = Map<String, Object?>;

class Fact {
  const Fact({this.text = '', this.sourceUrl = ''});

  factory Fact.fromMap(JsonMap map) {
    return Fact(
      text: map['text'] as String? ?? '',
      sourceUrl: map['source_url'] as String? ?? '',
    );
  }

  final String text;
  final String sourceUrl;
}

class RandomFactApi {
  Future<Fact> fetch({bool enabled = true}) async {
    if (!enabled) {
      throw Exception('Web API is disabled.');
    }

    const urlString = 'https://uselessfacts.jsph.pl/random.json?language=en';
    final url = Uri.parse(urlString);
    final response = await http.get(url);

    return Fact.fromMap(
      jsonDecode(response.body) as JsonMap,
    );
  }
}
