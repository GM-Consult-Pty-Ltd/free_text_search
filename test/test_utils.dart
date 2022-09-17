// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// ignore: unused_import
// import 'package:free_text_search/free_text_search.dart';
import 'package:free_text_search/src/_index.dart';
import 'data/sample_news.dart';

class TestIndex extends InMemoryIndexer {
  TestIndex._() : super(analyzer: TextAnalyzer());

  static Future<TestIndex> hydrate() async {
    final indexer = TestIndex._();
    await indexer.indexCollection(indexer.collection, indexer.fields);
    return indexer;
  }

  final JsonCollection collection = sampleNews;

  final List<FieldName> fields = ['name', 'description', 'hashTags'];

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
