// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// The [FreeTextSearch] class exposes the [search] method that returns a list of
/// [SearchResult] instances in descending order of relevance.
///
/// The length of the returned collection of [SearchResult] can be limited by
/// passing a limit parameter to [search]. The default limit is 20.
///
/// After parsing the phrase to terms, the [Postings] and [Dictionary] for the
/// query terms are asynchronously retrieved from the index:
/// - [dictionaryLoader] retrieves [Dictionary]; and
/// - [postingsLoader] retrieves [Postings].
abstract class FreeTextSearch {
  //

  /// Hydrate a [FreeTextSearch] instance:
  /// - [dictionaryLoader] asynchronously retrieves a [Dictionary] for query
  ///   terms from a data source;
  /// - [postingsLoader] asynchronously retrieves [Postings] for query terms
  ///   from a data source;
  /// - [configuration] is used to tokenize the query phrase (defaults to
  ///   [English.configuration]); and
  /// - provide a custom [tokenFilter] if you want to manipulate tokens or
  ///   restrict tokenization to tokens that meet specific criteria (default is
  ///   [TextAnalyzer.defaultTokenFilter].
  ///
  /// Ensure that the [configuration] and [tokenFilter] match the [TextAnalyzer]
  /// used to construct the index on the target collection that will be searched.
  factory FreeTextSearch(
      {required DictionaryLoader dictionaryLoader,
      required PostingsLoader postingsLoader,
      TextAnalyzerConfiguration configuration = English.configuration,
      TokenFilter tokenFilter = TextAnalyzer.defaultTokenFilter}) {
    final queryParser =
        QueryParser(configuration: configuration, tokenFilter: tokenFilter);
    return _FreeTextSearchImpl(dictionaryLoader, postingsLoader, queryParser);
  }

  /// The query parser returns a [FreeTextQuery] from a searh phrase.
  QueryParser get queryParser;

  /// Asynchronously retrieves [Postings] for query terms from a data source.
  PostingsLoader get postingsLoader;

  /// Asynchronously retrieves a [Dictionary] for query terms from a data
  /// source.
  DictionaryLoader get dictionaryLoader;

  /// Returns a list of [SearchResult] instances in descending order of
  /// relevance to [phrase].
  ///
  /// The returned collection of [SearchResult] will be limited to the [limit]
  /// most relevant results. The default [limit] is 20.
  Future<List<SearchResult>> search(String phrase, [int limit = 20]);
}

class _FreeTextSearchImpl implements FreeTextSearch {
  _FreeTextSearchImpl(
      this.dictionaryLoader, this.postingsLoader, this.queryParser);

  /// Private index elimination function that requests only those entries from
  /// the index dictionary that contains any of the query [Term]s.
  Future<Dictionary> _getQueryDictionary(Iterable<String> terms) =>
      dictionaryLoader(terms);

  @override
  Future<List<SearchResult>> search(String phrase, [int limit = 20]) async {
    final queryTerms = await queryParser.parse(phrase);
    final query = FreeTextQuery(phrase: phrase, terms: queryTerms);
    final terms = queryTerms.map((e) => e.term);
    // final dictionary = await dictionaryLoader(terms);
    final postings = await postingsLoader(terms);
    final scorer = SearchResultScorer(
        query: query,
        dictionary: await _getQueryDictionary(terms),
        postings: postings);
    final retVal = scorer.results(limit);
    return retVal;
  }

  @override
  final DictionaryLoader dictionaryLoader;

  @override
  final PostingsLoader postingsLoader;

  @override
  final QueryParser queryParser;
}
