// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// The [SearchResultScorer] exposes the [results] method that returns a
/// list of the most relevant [SearchResult] instances in descending order of
/// relevance after scoring and ranking the results using a vector space model:
/// - [query] is the query that was used to obtain the [dictionary] and
///   [postings];
/// - [dictionary] is a hashmap of terms to document frequency for the search
///   terms; and
/// - [postings] is a hashmap of terms to posting lists for the search terms.
class SearchResultScorer {
  //

  /// A hashmap of terms to document frequency for the search terms.
  final Dictionary dictionary;

  /// A hashmap of terms to posting lists for the search terms.
  final Postings postings;

  /// The query that was used to obtain the [dictionary] and [postings].
  final FreeTextQuery query;

  /// Returns a list of [SearchResult] instances in descending order of
  /// relevance.
  Future<List<SearchResult>> results(int limit) async {
    // - initialize the return value;
    final retVal = <SearchResult>[];
    retVal.sort(((a, b) => b.relevance.compareTo(a.relevance)));
    // - return the ranked [SearchResult], limiting the length of the return
    //   value to [limit];
    return retVal.length > limit ? retVal.sublist(0, limit) : retVal;
  }

  /// Instantiates a [SearchResultScorer] instance:
  /// - [query] is the query that was used to obtain the [dictionary] and
  ///   [postings];
  /// - [dictionary] is a hashmap of terms to document frequency for the search
  ///   terms; and
  /// - [postings] is a hashmap of terms to posting lists for the search terms.
  SearchResultScorer(
      {required this.query, required this.dictionary, required this.postings});
}
