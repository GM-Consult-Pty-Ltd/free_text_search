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

  /// A hashmap of [Term] to the number of occurences in the [Postings] of
  /// the [Term].
  final TermFrequencyMap cFtMap = {};

  /// A hashmap of [Term] to the inverse document frequency of the [Term] in
  /// [Postings].
  final Map<String, double> idFtMap = {};

  /// The [ChampionList] containing all the documents for a [Term].
  ChampionList low = {};

  /// The [ChampionList] containing documents with best static match with
  /// the [query]:
  /// - contains all the [query.queryTerms] with the [QueryTermModifier.EXACT],
  ///   if any are present in the [query]; and
  /// - contains one or more term pairs in the same order as in the
  ///   [query.phrase], if the phrase has more than 1 term
  ChampionList high = {};

  /// Reduce the size of the [postings] before scoring (if it is large):
  /// - remove elements from [postings] for terms with a low idf;
  /// - remove elements from [postings] where documents have few of the terms;
  void indexElimination() {}

  /// Returns a hashmap of [Term] to an ordered set of [Document]s that contain
  /// that term:
  /// - the hash value is an ordered set of [Document]s is in descending order
  ///   of term frequency ([Document.tF]) for the [Term];
  /// - each document ([Document.docId])] can only occur once in the ordered
  ///   list (i.e. an ordered set);
  /// - if [r] is not null, the length of the ordered set of [Document]s will be
  ///   limited to the first [r] documents, i.e. the [r] documents with the
  ///   highest [Document.tF].
  void getChampionLists([int? r]) {
    final terms = query.uniqueTerms;
    final documents = postings.documents(terms);
    //now build the champion list
    final ChampionList championList = {};
    for (final queryTerm in query.queryTerms) {
      final term = queryTerm.term;
      // get the collection frequency for the term while we're iterating through
      // the postings
      cFtMap[term] = postings.cFt(term);
      // get the inverse document frequency for the term while we're iterating through
      // the postings
      idFtMap[term] = postings.idFt(term, documents.length);
      // get the documents for term
      final termDocs = documents.values
          .where((element) => element.terms.contains(term))
          .toRankedSet(term, r);
      championList[term] = termDocs;
    }
    low = championList;
  }

  /// Returns a [List] of [SearchResult]
  List<SearchResult> computeScores() {
    getChampionLists();

    final List<SearchResult> results =
        []; // TODO: SearchResultScorer.computeScores
    return results;
  }

  /// A hashmap of terms to document frequency for the search terms.
  ///
  /// A subset of the collection dictionary that only contains the keys
  /// ([Term]s) in [query.terms].
  final Dictionary dictionary;

  /// A hashmap of terms to posting lists for the search terms.
  ///
  /// A subset of the collection dictionary that only contains the keys
  /// ([Term]s) in [query.terms].
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
