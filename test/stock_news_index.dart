// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:text_indexing/text_indexing.dart';
import 'package:text_indexing/type_definitions.dart';
import 'data/sample_news.dart';

class StockNewsIndex extends InMemoryIndexBase {
  static Future<StockNewsIndex> hydrate() async {
    final index = StockNewsIndex();
    await index.indexCollection(collection, tokenFilter: tokenFilter);
    return index;
  }

  static Future<List<Token>> tokenFilter(List<Token> tokens) async {
    return tokens
        .map((e) => Token(e.term.toLowerCase(), e.n, e.termPosition, e.zone))
        .toList();
  }

  static JsonCollection get collection => sampleNews;

  @override
  TextAnalyzer get analyzer => English.analyzer;

  @override
  int get collectionSize => collection.length;

  @override
  final DftMap dictionary = {};

  @override
  int get k => 3;

  @override
  final KGramsMap kGramIndex = {};

  @override
  final KeywordPostingsMap keywordPostings = {};

  @override
  final nGramRange = NGramRange(1, 3);

  @override
  final PostingsMap postings = {};

  @override
  final ZoneWeightMap zones = {'name': 1.0, 'description': 0.5};
}
