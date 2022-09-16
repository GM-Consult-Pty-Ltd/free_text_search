// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// ignore_for_file: unused_local_variable

// ignore: unused_import
import 'package:free_text_search/free_text_search.dart';
import 'package:free_text_search/src/_index.dart';
import 'package:test/test.dart';
import 'data/sample_news.dart';
import 'test_utils.dart';

void main() {
  //

  const phrase = '"tesla batteries" technology';

  group('FreeTextSearch', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('FreeTextSearch: Terms', () async {
      final indexer = await TestIndex.hydrate();
      // initialize the QueryParser
      final queryParser = QueryParser();
      // parse the phrase
      final queryTerms = await queryParser.parse(phrase);
      // print the terms and their modifiers
      TestIndex.printQueryTerms(queryTerms);
      // create the in-memory dictionary and postings for sampleNews
      await indexer
          .indexCollection(sampleNews, ['name', 'description', 'hashTags']);

      final dictionaryTerms = indexer.index.dictionary.terms;

      // Get the document ids of those postings that contain ANY of the terms.
      indexer
          .printDocuments(indexer.index.postings.containsAny(queryTerms.terms));

      // Get the document ids of those postings that contain ALL the terms.
      indexer
          .printDocuments(indexer.index.postings.containsAll(queryTerms.terms));
    });
  });
}
