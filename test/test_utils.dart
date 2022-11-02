// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';
import 'data/sample_news.dart';

class TestIndex extends TextIndexerBase {
  TestIndex._(
      this.index, this.collection); // : super(analyzer: TextAnalyzer());

  // static const kCollection = sampleNews;

  @override
  final InMemoryIndex index;

  static Future<TestIndex> hydrate(
      [Map<String, Map<String, Object>> collection = sampleNews]) async {
    final index = InMemoryIndex(
      dictionary: {},
      postings: {},
      keywordPostings: {},
        collectionSize: collection.length,
      tokenizer: TextTokenizer.english,
      keywordExtractor: English.analyzer.keywordExtractor,
      zones: zoneMap,
      strategy: TokenizingStrategy.all);
    final indexer = TestIndex._(index, collection);
    await indexer.indexCollection(indexer.collection);
    return indexer;
  }

  /// The in-memory term dictionary for the indexer.
  DftMap get dictionary => index.dictionary;

  KeywordPostingsMap get keywordPostings =>
      index.keywordPostings;

  /// The in-memory postings hashmap for the indexer.
  PostingsMap get postings => index.postings;

  final JsonCollection collection;

  static const zoneMap = {'name': 1.0, 'description': 0.5, 'hashTags': 2.0};

  static void printQueryTerms(Iterable<QueryTerm> queryTerms) {
    for (final qt in queryTerms) {
      // prints -   "term" [MODIFIER]
      print(' - "${qt.term}" [${qt.modifier.name}]');
    }
  }

  JsonCollection getDocuments(Iterable<DocId> ids) =>
      JsonCollection.from(collection)
        ..removeWhere((key, value) => !ids.contains(key));

  void printDocuments(Iterable<DocId> ids) {
    final documents = getDocuments(ids);
    print('');
    print('__________________________________________________________________'
        '__________________________________________________________________');
    print('PRINTING: ${documents.length} DOCUMENTS');
    for (final entry in documents.entries) {
      final id = entry.key;
      String name = entry.value['name'].toString();
      name = (name.length > 80) ? name = name.substring(0, 80) : name;
      print('$id: $name');
    }
    print('=================================================================='
        '==================================================================');
  }
}
