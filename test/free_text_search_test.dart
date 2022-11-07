// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// ignore_for_file: unused_local_variable

// ignore: unused_import
import 'package:free_text_search/free_text_search.dart';
import 'package:free_text_search/src/_index.dart';
import 'package:gmconsult_dev/gmconsult_dev.dart';
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  //

  const phrase = 'Tesla EV battery technology';

  // const fields = ['name', 'description', 'hashTags'];

  group('FreeTextSearch', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('FreeTextSearch: TestIndex', () async {
      final indexer = await TestIndex.hydrate();
      // initialize the QueryParser
      final queryParser = QueryParser(tokenizer: TextTokenizer.english);
      // parse the phrase
      final queryTerms = await queryParser.parseQuery(phrase);

      final query = FreeTextQuery(phrase: phrase, queryTerms: queryTerms);

      // print the terms and their modifiers
      TestIndex.printQueryTerms(query.queryTerms);
      // create the in-memory dictionary and postings for sampleNews
      // await indexer.indexCollection(sampleNews, fields);

      final dictionaryTerms = indexer.dictionary.terms;

      final andTerms = query.queryTerms.andTerms;

      final terms = andTerms.map((e) => e.term).toSet();

      // // Get the document ids of those postings that contain ANY of the terms.
      // indexer
      //     .printDocuments(indexer.postings.containsAny(query.queryTerms.terms));

      final searchPostings = indexer.postings.containsAny(terms);

      final keywordPostings = indexer.keywordPostings.containsAny(terms);

      final dftMap = <String, int>{}..addEntries(indexer.dictionary.entries
          .where((element) => terms.contains(element.key)));

      final docIds = keywordPostings.union(searchPostings);

      final docCount = indexer.collection.length;
      final searchResults = <QuerySearchResult>[];
      for (final docId in docIds) {
        final result = QuerySearchResult.fromPostings(
            docId: docId,
            query: query,
            docCount: docCount,
            postings: indexer.postings.getPostings(terms),
            dFtMap: dftMap.getEntries(terms),
            keyWordPostings:
                indexer.keywordPostings.getKeywordsPostings(terms));
        if (result != null) {
          searchResults.add(result);
        }
      }

      // Get the document ids of those postings that contain ALL the terms.
      indexer.printDocuments(indexer.postings.containsAll(andTerms.terms));
    });

    test('QuerySearch.search', () async {
      final phrase = 'dan ives wedbush -tesla';
      // initialize an in-memory indexer
      final indexer = await TestIndex.hydrate();
      final index = indexer.index;
      // initialize the QueryParser
      final queryParser = QueryParser(
          tokenizer: TextTokenizer.english, nGramRange: index.nGramRange);
      // parse the phrase to a query
      final queryTerms = (await queryParser.parseQuery(phrase)).toList();
      // define the document field weights
      final ZoneWeightMap zoneWeigths = {'name': 1.0, 'description': 0.25};

      /// initialize a query
      final query = FreeTextQuery(
          phrase: phrase,
          queryTerms: queryTerms,
          weightingStrategy: WeightingStrategy(zoneWeights: zoneWeigths));
      // get the terms from the query
      final terms = query.queryTerms.uniqueTerms;

      final indexSearch = QuerySearch(index: indexer.index, query: query);

      var results = (await indexSearch.search()).entries.toList();
      results.sort(((a, b) =>
          b.value.cosineSimilarity.compareTo(a.value.cosineSimilarity)));

      results = results.length > 5 ? results.sublist(0, 5) : results;
      final JsonCollection jsonResults = {};
      for (final e in results) {
        final doc = indexer.collection[e.key];
        if (doc != null) {
          var name = (doc['name'] as String?) ?? '';
          name = name.length > 120 ? name.substring(0, 120) : name;
          jsonResults[e.key] = {
            'Title': name,
            'tf-Idf Score': e.value.tfIdfScore,
            'cosineSimilarity': e.value.cosineSimilarity
          };
        }
      }

      Console.out(
          maxColWidth: 120,
          title: 'SEARCH RESULTS for "${query.phrase}"',
          results: jsonResults.values);
      // print(results.length);
    });

    //
  });
}
