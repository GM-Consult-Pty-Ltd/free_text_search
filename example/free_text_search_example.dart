// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

void main() async {
  //

  // A phrase with all the modifiers.
  const phrase =
      '"athletics track" +surfaced arena OR stadium "Launceston" -hobart NOT help-me';

  // parse the phrase
  await _parsePhrase(phrase);
}

/// To parse a phrase simply pass it to the `QueryParser.parse` method,
/// including any modifiers.
Future<List<QueryTerm>> _parsePhrase(String phrase) async {
  // initialize the QueryParser
  final queryParser = QueryParser(tokenizer: TextTokenizer.english);
  // parse the phrase
  final query = await queryParser.parseQuery(phrase);

  // print the terms and their modifiers
  for (final qt in query.queryTerms) {
    // prints -   "term" [MODIFIER]
    print(' - "${qt.term}" [${qt.modifier.name}]');
  }
  // prints:
  //  - "athletics track" [EXACT]
  //  - "athletics" [OR]
  //  - "track" [OR]
  //  - "surfaced" [IMPORTANT]
  //  - "arena" [AND]
  //  - "stadium" [OR]
  //  - "Launceston" [EXACT]
  //  - "launceston" [OR]
  //  - "hobart" [NOT]
  //  - "help-me" [NOT]
  //  - "help" [NOT]"
  return query.queryTerms;
}
