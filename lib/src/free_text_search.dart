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
    final queryParser =
        QueryParser(tokenizer: index.tokenizer, nGramRange: index.nGramRange);
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
      WeightingStrategy weightingStrategy});

  /// Returns a list of document ids in descending order of relevance to terms
  /// that start with [startsWith].
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

  /// The tokenizer used to parse a phrase to a [FreeTextQuery].
  ///
  /// Returns [index.tokenizer].
  TextTokenizer get tokenizer => index.tokenizer;

  /// The n-gram range used to parse a phrase to a [FreeTextQuery].
  ///
  /// Returns [index.nGramRange].
  NGramRange get nGramRange => index.nGramRange;

  @override
  Future<List<QuerySearchResult>> phrase(String phrase,
      {bool expandUnmatched = false,
      int limit = 20,
      WeightingStrategy weightingStrategy = WeightingStrategy.simple}) async {
    // parse the phrase to a query
    final queryTerms = (await queryParser.parseQuery(phrase)).toList();
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
    final search = StartsWithSearch(index);
    return await search.search(startsWith, limit);
  }

  @override
  Stream<List<MapEntry<String, double>>> suggestionsStream(
          Stream<String> startsWith,
          [int limit = 20]) =>
      StartsWithSearch(index).suggestionsStream(startsWith, limit);
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
