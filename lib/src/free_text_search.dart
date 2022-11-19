// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// The [FreeTextSearch] class exposes the [search] method that returns a list of
/// [QuerySearchResult] instances in descending order of relevance:
/// - [index] is an inverted, positional, zoned index on a collection of
///   documents that is queried; and
/// - [queryParser] returns a [FreeTextQuery] from a searh phrase.
///
/// The length of the returned collection of [QuerySearchResult] can be limited by
/// passing a limit parameter to [search]. The default limit is 20.
///
/// After parsing the phrase to terms, the [PostingsMap] and [Dictionary] for the
/// query terms are asynchronously retrieved from the [index].
abstract class FreeTextSearch {
  //

  /// Hydrate a [FreeTextSearch] instance:
  /// - [index] is an inverted, positional, zoned index on a collection of
  ///   documents that is queried; and
  /// - [queryParser] returns a [FreeTextQuery] from a searh phrase.
  factory FreeTextSearch(InvertedIndex index) {
    final queryParser = QueryParser(index);
    return _FreeTextSearchImpl(index, queryParser);
  }

  /// The query parser returns a [FreeTextQuery] from a searh phrase.
  QueryParser get queryParser;

  /// An an inverted, positional, zoned index on a collection of documents that
  /// is queried.
  InvertedIndex get index;

  /// Returns a list of [QuerySearchResult] instances in descending order of
  /// cosine similarity with the query's tf-iDf vector.
  Future<List<QuerySearchResult>> query(FreeTextQuery query, [int limit = 20]);

  /// Returns a list of [QuerySearchResult] instances in descending order of
  /// relevance to [phrase].
  ///
  /// The returned collection of [QuerySearchResult] will be limited to the
  /// [limit] most relevant results. The default [limit] is 20.
  Future<List<QuerySearchResult>> phrase(String phrase,
      {bool expandUnmatched = false,
      int limit = 20,
      WeightingStrategy weightingStrategy,
      TextAnalyzer? queryAnalyzer});

  /// Extracts keywords from the JSON [document] and searches the keyword
  /// [index] for matches for the highest scoring keywords in [zones], returning
  /// the document ids with the [limit] highest keyword scores.
  ///
  /// If [documentZones] is not null the search results are weighted in accordance with
  /// the weights in [documentZones].
  ///
  ///  The default [limit] is 20.
  Future<List<QuerySearchResult>> document(JSON document,
      {required WeightingStrategy weightingStrategy,
      int limit = 20,
      TokenFilter? tokenFilter,
      TextAnalyzer? docAnalyzer,
      NGramRange nGramRange});

  /// Returns a list of document ids from a keyword index in descending order
  /// of keyword score for keywords that start with [startsWith].
  ///
  /// The returned collection of document ids will be limited to the [limit]
  /// most relevant results. The default [limit] is 20.
  Future<List<MapEntry<String, double>>> startsWith(String startsWith,
      [int limit = 20]);

  /// Returns a stream of suggestions (document ids) for the input stream.
  /// Only returns suggestions that have a high starts-with similarity with the
  /// last element in [startsWith].
  ///
  /// The returned list is ordered in descending order of keyword score
  Stream<List<MapEntry<String, double>>> suggestionsStream(
      Stream<String> startsWith,
      [int limit = 20]);

//
}

/// Abstract mixin class that implements [FreeTextSearch.phrase],
/// [FreeTextSearch.query] and [FreeTextSearch.startsWith]
abstract class FreeTextSearchMixin implements FreeTextSearch {
  //

  /// The analyzer used to parse a phrase to a [FreeTextQuery].
  ///
  /// Returns [index.analyzer].
  TextAnalyzer get analyzer => index.analyzer;

  /// The n-gram range used to parse a phrase to a [FreeTextQuery].
  ///
  /// Returns [index.nGramRange].
  NGramRange? get nGramRange => index.nGramRange;

  @override
  Future<List<QuerySearchResult>> phrase(String phrase,
      {bool expandUnmatched = false,
      int limit = 20,
      WeightingStrategy weightingStrategy = WeightingStrategy.simple,
      TextAnalyzer? queryAnalyzer}) async {
    // parse the phrase to a query
    final queryTerms =
        (await queryParser.parseQuery(phrase, queryAnalyzer: queryAnalyzer))
            .toList();
    // initialize a query
    final query = FreeTextQuery(
        phrase: phrase,
        queryTerms: queryTerms,
        targetResultSize: limit * 2,
        expandUnmatched: expandUnmatched,
        weightingStrategy: weightingStrategy);
    // initialize a QuerySearch object with the query and index
    final search = QuerySearch(index: index, query: query);
    // execute the query search
    var results = (await search.search()).values.toList();
    // sort the results by cosine similarity
    results.sort(((a, b) => b.cosineSimilarity.compareTo(a.cosineSimilarity)));
    results = results.length > limit ? results.sublist(0, limit) : results;
    return results;
  }

  @override
  Future<List<QuerySearchResult>> query(FreeTextQuery query,
      [int limit = 20]) async {
    // initialize a QuerySearch object with the query and index
    final search = QuerySearch(index: index, query: query);
    // execute the query search
    var results = (await search.search()).values.toList();
    results.sort(((a, b) => b.cosineSimilarity.compareTo(a.cosineSimilarity)));
    results = results.length > limit ? results.sublist(0, limit) : results;
    return results;
  }

  @override
  Future<List<MapEntry<String, double>>> startsWith(String startsWith,
      [int limit = 20]) async {
    final search = KeywordSearch(index);
    return await search.startsWith(startsWith, limit);
  }

  @override
  Future<List<QuerySearchResult>> document(JSON document,
      {required WeightingStrategy weightingStrategy,
      int limit = 20,
      TokenFilter? tokenFilter,
      TextAnalyzer? docAnalyzer,
      NGramRange nGramRange = const NGramRange(1, 3)}) async {
    final zoneWeights = _getZoneWeights(weightingStrategy, document);
    final queryTerms = await QueryParser(index).parseDocument(
        document, zoneWeights,
        termPositionThreshold: weightingStrategy.positionThreshold,
        nGramRange: nGramRange,
        tokenFilter: tokenFilter,
        docAnalyzer: docAnalyzer);
    final phrase = queryTerms.terms.join(' ');
    final ftQuery = FreeTextQuery(
      phrase: phrase,
      weightingStrategy: weightingStrategy,
      queryTerms: queryTerms,
      targetResultSize: limit * 2,
    );
    return await query(ftQuery, limit);
  }

  ZoneWeightMap _getZoneWeights(WeightingStrategy strategy, JSON document) {
    if (strategy.zoneWeights != null) {
      return strategy.zoneWeights!;
    }
    final retVal = <String, double>{};
    for (final e in document.entries) {
      final v = e.value;
      if (v is String && v.isNotEmpty) {
        retVal[e.key] = 1.0;
      }
    }
    return retVal;
  }

  @override
  Stream<List<MapEntry<String, double>>> suggestionsStream(
          Stream<String> startsWith,
          [int limit = 20]) =>
      KeywordSearch(index).suggestionsStream(startsWith, limit);
}

/// Implementation base class that mixes in [FreeTextSearchMixin]. Provides
/// const default generative constructor for sub-classes.
abstract class FreeTextSearchBase with FreeTextSearchMixin {
  //

  /// Const default generative constructor for sub-classes.
  const FreeTextSearchBase();

  //
}

/// Implementation class for [FreeTextSearch] unnamed factory.
class _FreeTextSearchImpl extends FreeTextSearchBase {
  /// Const default generative constructor.
  const _FreeTextSearchImpl(this.index, this.queryParser);
//

  @override
  final InvertedIndex index;

  @override
  final QueryParser queryParser;

  //
}
