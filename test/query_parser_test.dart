// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// ignore: unused_import
import 'package:free_text_search/free_text_search.dart';
import 'package:free_text_search/src/_index.dart';
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  //

  const phraseWithModifiers =
      '"athletics track" +surfaced arena OR stadium "Launceston" -hobart NOT help-me';

  group('QueryParser', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('QueryParser: Test Modifiers', () async {
      // initialize the QueryParser
      final queryParser = QueryParser();
      // parse the phrase
      final queryTerms = await queryParser.parse(phraseWithModifiers);
      // print the terms and their modifiers
      TestIndex.printQueryTerms(queryTerms);

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
    });
  });
}
