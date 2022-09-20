// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';
import 'data/sample_news.dart';
import 'package:rxdart/rxdart.dart';

class TestIndex extends TextIndexerBase {
  TestIndex._(); // : super(analyzer: TextAnalyzer());

  @override
  final index = InMemoryIndex(
      dictionary: {}, postings: {}, analyzer: TextAnalyzer(), zones: zoneMap);
  static Future<TestIndex> hydrate() async {
    final indexer = TestIndex._();
    await indexer.indexCollection(indexer.collection);
    return indexer;
  }

  /// The in-memory term dictionary for the indexer.
  Dictionary get dictionary => (index as InMemoryIndex).dictionary;

  /// The in-memory postings hashmap for the indexer.
  Postings get postings => (index as InMemoryIndex).postings;

  final JsonCollection collection = sampleNews;

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

  @override
  Stream<Map<DocId, JSON>>? get collectionStream => null;

  @override
  final controller = BehaviorSubject<Postings>();

  @override
  Stream<MapEntry<DocId, JSON>>? get documentStream => null;
}
