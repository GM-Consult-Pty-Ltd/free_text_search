// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';
import 'package:gmconsult_dev/gmconsult_dev.dart';
import 'package:hive_text_index/hive_text_index.dart';
import 'data/sample_news.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'hashtag_analyzer.dart';

String get kPath => '${Directory.current.path}\\dev\\data';

final kZones = {'id': 1.0, 'name': 1.0, 'hashTag': 1.0};

final kK = 3;

final kStrategy = TokenizingStrategy.all;

final kNGramRange = NGramRange(1, 2);

final kIndexName = 'hashtags';

class TestIndex extends TextIndexerBase {
  TestIndex._(
      this.index, this.collection); // : super(analyzer: TextAnalyzer());

  // Future<TextTokenizer> kTokenizer(JsonDataService<Box<String>> service) async {
  //   final analyzer = await HashTagAnalyzer.hydrate(service);
  //   return TextTokenizer(analyzer: analyzer);
  // }

  @override
  final InMemoryIndex index;

  static Future<TestIndex> hydrate(
      [Map<String, Map<String, Object>> collection = sampleNews]) async {
    final index = InMemoryIndex(
        dictionary: {},
        postings: {},
        keywordPostings: {},
        collectionSize: collection.length,
        analyzer: HashTagAnalyzer(),
        keywordExtractor: English.analyzer.keywordExtractor,
        zones: zoneMap,
        strategy: TokenizingStrategy.all);
    final indexer = TestIndex._(index, collection);
    await indexer.indexCollection(indexer.collection);
    return indexer;
  }

  /// The in-memory term dictionary for the indexer.
  DftMap get dictionary => index.dictionary;

  KeywordPostingsMap get keywordPostings => index.keywordPostings;

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

Future<HiveTextIndex> hiveIndex(CollectionSizeCallback collectionSizeLoader) async {
  return await HiveTextIndex.hydrate(kIndexName,
      collectionSizeLoader: collectionSizeLoader,
      analyzer: HashTagAnalyzer(),
      nGramRange: kNGramRange,
      k: kK,
      zones: kZones,
      strategy: kStrategy);
}

Future<InMemoryIndex> inMemoryIndex(int collectionSize) async {
  return InMemoryIndex(
      collectionSize: collectionSize,
      analyzer: HashTagAnalyzer(),
      keywordExtractor: English.analyzer.keywordExtractor,
      nGramRange: kNGramRange,
      k: kK,
      zones: kZones,
      strategy: kStrategy);
}

/// Hydrates a [JsonDataService] with a large dataset of securities.
Future<JsonDataService<Box<String>>> getService(String boxName) async {
  final Box<String> dataStore = await Hive.openBox(boxName);
  return HiveJsonService(dataStore);
}

// class HashTagAnalyzer with LatinLanguageAnalyzerMixin {
//   //

//   // static Future<HashTagAnalyzer> hydrate(
//   //     JsonDataService<Box<String>> service) async {
//   //   final companyNames = await _getCompanyNames(service);
//   //   return HashTagAnalyzer._(companyNames);
//   // }

//   const HashTagAnalyzer._(this.companyNames);

//   /// A set of unique terms that limit the keywords to the
//   /// first word of a company's registered trading name.
//   final Set<String> companyNames;

//   // @override
//   // TermFilter get termFilter => (term) {
//   //       term = term.trim();

//   //       term = term.split(RegExp(r'[^a-zA-Z0-9\-]')).first;
//   //       if (term.isNotEmpty) {
//   //         if (companyNames.contains(term)) {
//   //           return {term};
//   //         }
//   //         term = term.toUpperCase();
//   //         if (companyNames.contains(term)) {
//   //           return {term};
//   //         }
//   //         term = term.substring(0, 1) + term.substring(1).toLowerCase();
//   //         if (companyNames.contains(term)) {
//   //           return {term};
//   //         }
//   //       }
//   //       return {};
//   //     };

//   @override
//   Set<String> get stopWords => {};

//   @override
//   Stemmer get stemmer => (term) => term.trim();

//   @override
//   Map<String, String> get abbreviations => {};

//   @override
//   CharacterFilter get characterFilter => (term) => term.trim();

//   @override
//   Lemmatizer get lemmatizer => (term) => term.trim();

//   @override
//   Map<String, String> get termExceptions => {};

//   static Future<Set<String>> getCompanyNames(
//       JsonDataService<Box<String>> service) async {
//     final retVal = <String>{};
//     final keys = service.dataStore.keys.map((e) => e.toString());
//     await Future.forEach(keys, (String key) async {
//       final json = await service.read(key);
//       if (json != null) {
//         final name = (json['name'] as String?)?.split(' ');
//         if (name != null && name.isNotEmpty) {
//           retVal.add(name.first);
//         }
//       }
//     });
//     return retVal;
//   }
// }
