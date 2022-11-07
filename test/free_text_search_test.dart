// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/free_text_search.dart';
import 'package:gmconsult_dev/gmconsult_dev.dart';
import 'package:test/test.dart';
import 'package:text_indexing/type_definitions.dart';
import 'test_utils.dart';

void main() {
  //

  group('FreeTextSearch', () {
    setUp(() {
      // Additional setup goes here.
    });
    test('FreeTextSearch.startsWith', (() async {
      final phrase = 'nv';

      // initialize an in-memory indexer
      final indexer = await TestIndex.hydrate();
      // get the results
      final results = await FreeTextSearch(indexer.index).startsWith(phrase);
      // map the results for printing to console
      final JsonCollection jsonResults = {};
      for (final e in results) {
        final doc = indexer.collection[e.key];
        if (doc != null) {
          var name = (doc['name'] as String?) ?? '';
          name = name.length > 120 ? name.substring(0, 120) : name;
          jsonResults[e.key] = {'Title': name, 'Score': e.value};
        }
      }

      Console.out(
          maxColWidth: 120,
          title: 'SEARCH RESULTS for "$phrase"',
          results: jsonResults.values);
    }));

    test('QuerySearch.search', () async {
      final phrase = 'dan ives wedbush';
      // initialize an in-memory indexer
      final indexer = await TestIndex.hydrate();
      // get the results
      final results = await FreeTextSearch(indexer.index).phrase(phrase);

      final JsonCollection jsonResults = {};
      for (final e in results) {
        final doc = indexer.collection[e.docId];
        if (doc != null) {
          var name = (doc['name'] as String?) ?? '';
          name = name.length > 120 ? name.substring(0, 120) : name;
          jsonResults[e.docId] = {
            'Title': name,
            'tf-Idf Score': e.tfIdfScore,
            'cosineSimilarity': e.cosineSimilarity
          };
        }
      }

      Console.out(
          maxColWidth: 120,
          title: 'SEARCH RESULTS for "$phrase"',
          results: jsonResults.values);
      // print(results.length);
    });

    //
  });
}
