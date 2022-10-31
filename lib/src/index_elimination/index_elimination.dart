// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// import 'dart:math';
import 'package:free_text_search/src/_index.dart';
import 'package:text_analysis/extensions.dart';
// import 'package:collection/collection.dart';

///
class IndexSearch {
//

  final FreeTextQuery query;

  /// The [InvertedIndex] that contains the indexes for the collection.
  final InvertedIndex index;

  /// Hydrates a [IndexSearch] instance with the [index].
  const IndexSearch(this.index, this.query);

  /// Iteratively searches the index for the [query] terms until the minimum
  /// result set size is achieved or no more results are returned.
  Future<Map<String, SearchResult>> search() async {
    // map the queryTerm objects to a list of strings
    if (query.queryTerms.isEmpty) {
      // return an empty collection if no query terms are supplied
      return {};
    }
    // make a copy of the query terms in case the query terms is not a
    // growable list
    final queryTerms = List<QueryTerm>.from(query.queryTerms);
    // check if the query is maybe a predictive text query (single term of
    // 1 to 3 characters length)
    if (queryTerms.length == 1 && queryTerms.first.term.length < 4) {
      queryTerms.addAll(await _expandQuery(queryTerms.first, 5));
    }

    // get the postings for the query
    final PostingsMap postings = await _addPostingsForAllModifiers(queryTerms);
    // get the postings for unmatched terms
    postings.addAll(
        await _addPostingsForAllModifiers(await _unmatchedTerms(postings)));

    // Map the postings to a hashmap of docid to SearchResult
    final retVal = await _postingsToSearchResults(postings);

    // return the results and proceed to scoring and ranking
    return retVal;
  }

  Future<Map<String, SearchResult>> _postingsToSearchResults(
      PostingsMap postings) async {
    final terms = postings.keys;
    final dfTMap = await index.getDictionary(terms);
    final keywordPostings = await index.getKeywordPostings(terms);
    final docCount = await index.getCollectionSize();
    final docIds = postings.docIds;
    final searchResults = <String, SearchResult>{};
    for (final docId in docIds) {
      searchResults[docId] = SearchResult(
          docId: docId,
          docCount: docCount,
          postings: postings,
          dFtMap: dfTMap,
          keyWordPostings: keywordPostings);
    }
    return searchResults;
  }

  Future<PostingsMap> _addPostingsForAllModifiers(
      Iterable<QueryTerm> queryTerms) async {
    if (queryTerms.isEmpty) {
      return {};
    }
    final notTerms =
        queryTerms.filterByModifier(QueryTermModifier.NOT).uniqueTerms;
    // get the postings for the [NOT] terms
    final PostingsMap postings =
        notTerms.isEmpty ? {} : await index.getPostings(notTerms);
    // map the [NOT] postings to a set of document ids.
    final notDocIds = postings.docIds;
    // add exact term postings, if exact terms were provided.
    await _addPostings(
        postings, QueryTermModifier.EXACT, queryTerms, notDocIds);
    // add important terms if not enough results have been obtained AND important
    //  terms were provided
    await _addPostings(
        postings, QueryTermModifier.IMPORTANT, queryTerms, notDocIds);
    // add [AND] terms if not enough results have been obtained
    await _addPostings(postings, QueryTermModifier.AND, queryTerms, notDocIds);
    // add [OR] terms if not enough results have been obtained
    await _addPostings(postings, QueryTermModifier.OR, queryTerms, notDocIds);
    return postings;
  }

  Future<Iterable<QueryTerm>> _unmatchedTerms(PostingsMap postings) async {
    final found = postings.keys.toSet();
    final List<QueryTerm> retVal = [];
    final unmatched =
        query.queryTerms.where((element) => !found.contains(element.term));
    for (final e in unmatched) {
      retVal.addAll(await _expandQuery(e, 5));
    }
    return retVal;
  }

  /// Helper method that adds postings for the [modifier] if the [postings]
  /// collection does not contain enough results.
  Future<void> _addPostings(PostingsMap postings, QueryTermModifier modifier,
      Iterable<QueryTerm> queryTerms, Set<String> notDocIds) async {
    if ((postings.docIds.length - notDocIds.length) <
        query.targetResultSize * 2) {
      final terms = queryTerms.filterByModifier(modifier).uniqueTerms;
      if (terms.isNotEmpty) {
        postings.addAll(await index.getPostings(terms));
      }
    }
  }

  /// Queries the index k-gram index for terms similar to [terms] and then
  /// returns the top [limit] matches as [QueryTerm] instances.
  Future<Set<QueryTerm>> _expandQuery(QueryTerm queryTerm, int limit) async {
    final kGrams = queryTerm.term.kGrams(index.k);
    final candidates = (await index.getKGramIndex(kGrams)).terms;
    final matches =
        queryTerm.term.matches(candidates, limit: limit, k: index.k);
    return matches
        .map((e) => QueryTerm(e, QueryTermModifier.AND, queryTerm.termPosition,
            e.split(' ').length))
        .toSet();
  }
}
