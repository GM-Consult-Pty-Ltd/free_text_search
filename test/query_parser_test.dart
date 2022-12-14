// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// ignore: unused_import
import 'package:free_text_search/free_text_search.dart';
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  //

  const phraseWithModifiers =
      '"athletics running track" +surfaced arena OR stadium "Launceston" -hobart NOT help-me south launceston';

  group('QueryParser', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('QueryParser: Test Modifiers', () async {
      // initialize the QueryParser
      final index = InMemoryIndex(
          analyzer: English.analyzer,
          collectionSize: 1,
          nGramRange: NGramRange(1, 2));
      final queryParser = QueryParser(
        index,
      );
      // parse the phrase
      final queryTerms = await queryParser.parseQuery(phraseWithModifiers);

      // final queryTerms = query.queryTerms;
      print(phraseWithModifiers);
      // print the terms and their modifiers
      printQueryTerms(queryTerms);

      // prints:
      //  - "athletics running track" [EXACT]
      //  - "Launceston" [EXACT]
      //  - "athlet" [AND]
      //  - "run" [OR]
      //  - "athletics running" [OR]
      //  - "track" [AND]
      //  - "surfac" [IMPORTANT]
      //  - "surfaced" [IMPORTANT]
      //  - "track surfac" [OR]
      //  - "arena" [OR]
      //  - "surfac arena" [OR]
      //  - "stadium" [OR]
      //  - "surfac stadium" [OR]
      //  - "launceston" [OR]
      //  - "hobart" [NOT]
      //  - "help-me" [NOT]
    });
  });
}
