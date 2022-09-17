// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// The [FreeTextSearch] class exposes the [search] method that returns a list of
/// [SearchResult] instances in descending order of relevance:
/// - [index] is an inverted, positional, zoned index on a collection of
///   documents that is queried; and
/// - [queryParser] returns a [FreeTextQuery] from a searh phrase.
///
/// The length of the returned collection of [SearchResult] can be limited by
/// passing a limit parameter to [search]. The default limit is 20.
///
/// After parsing the phrase to terms, the [Postings] and [Dictionary] for the
/// query terms are asynchronously retrieved from the [index].
abstract class FreeTextSearch {
  //

  /// Hydrate a [FreeTextSearch] instance:
  /// - [index] is an inverted, positional, zoned index on a collection of
  ///   documents that is queried; and
  /// - [queryParser] returns a [FreeTextQuery] from a searh phrase.
  factory FreeTextSearch(InvertedPositionalZoneIndex index) {
    final queryParser = QueryParser(
        configuration: index.analyzer.configuration,
        tokenFilter: index.analyzer.tokenFilter);
    return _FreeTextSearchImpl(index, queryParser);
  }

  /// The query parser returns a [FreeTextQuery] from a searh phrase.
  QueryParser get queryParser;

  /// An an inverted, positional, zoned index on a collection of documents that
  /// is queried.
  InvertedPositionalZoneIndex get index;

  /// Returns a list of [SearchResult] instances in descending order of
  /// relevance to [phrase].
  ///
  /// The returned collection of [SearchResult] will be limited to the [limit]
  /// most relevant results. The default [limit] is 20.
  Future<List<SearchResult>> search(String phrase, [int limit = 20]);
}

class _FreeTextSearchImpl implements FreeTextSearch {
  _FreeTextSearchImpl(this.index, this.queryParser);

  @override
  Future<List<SearchResult>> search(String phrase, [int limit = 20]) async {
    final query = await queryParser.parseQuery(phrase);
    final terms = query.uniqueTerms;
    // final dictionary = await dictionaryLoader(terms);
    final postings = await index.getPostings(terms);
    final scorer = SearchResultScorer(
        query: query,
        dictionary: await index.getDictionary(terms),
        postings: postings);
    final retVal = scorer.results(limit);
    return retVal;
  }

  @override
  final InvertedPositionalZoneIndex index;

  @override
  final QueryParser queryParser;
}
