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

  const phrase = 'Tesla EV battery technology';

  const fields = ['name', 'description', 'hashTags'];

  group('FreeTextSearch', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('FreeTextSearch: TestIndex', () async {
      final indexer = await TestIndex.hydrate();
      // initialize the QueryParser
      final queryParser = QueryParser();
      // parse the phrase
      final queryTerms = await queryParser.parseTerms(phrase);
      // print the terms and their modifiers
      TestIndex.printQueryTerms(queryTerms);
      // create the in-memory dictionary and postings for sampleNews
      // await indexer.indexCollection(sampleNews, fields);

      final dictionaryTerms = indexer.index.dictionary.terms;

      final andTerms = queryTerms.where((element) =>
          element.modifier == QueryTermModifier.EXACT ||
          element.modifier == QueryTermModifier.AND ||
          element.modifier == QueryTermModifier.IMPORTANT);
      // Get the document ids of those postings that contain ANY of the terms.
      indexer
          .printDocuments(indexer.index.postings.containsAny(queryTerms.terms));

      // Get the document ids of those postings that contain ALL the terms.
      indexer
          .printDocuments(indexer.index.postings.containsAll(andTerms.terms));
    });

    test('SearchResultScorer: championList', () async {
      // initialize an in-memory indexer
      final indexer = await TestIndex.hydrate();
      // initialize the QueryParser
      final queryParser = QueryParser();
      // parse the phrase to a query
      final FreeTextQuery query = await queryParser.parseQuery(phrase);
      // get the terms from the query
      final terms = query.uniqueTerms;

      final scorer = SearchResultScorer(
          query: query,
          dictionary: await indexer.index.getDictionary(terms.toSet()),
          postings: await indexer.index.getPostings(terms.toSet()));

      scorer.getChampionLists();
      print(scorer.low.length);
    });

    //
  });
}
