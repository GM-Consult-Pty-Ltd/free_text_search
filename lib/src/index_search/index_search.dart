// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// import 'dart:math';
import 'package:free_text_search/src/_index.dart';

///
abstract class IndexSearch {
  ///
  factory IndexSearch(
          {required InvertedIndex index,
          required FreeTextQuery query,
          WeightingStrategy weightingStrategy = WeightingStrategy.simple}) =>
      _IndexSearchImpl(index, query);

  /// The query executed by the [IndexSearch] instance.
  FreeTextQuery get query;

  /// The [InvertedIndex] that contains the indexes for the collection.
  InvertedIndex get index;

  /// Iteratively searches the index for the [query] terms until the minimum
  /// result set size is achieved or no more results are returned.
  Future<Map<String, SearchResult>> search();
}

///
abstract class IndexSearchMixin implements IndexSearch {
  //

  @override
  Future<Map<String, SearchResult>> search() async {
    // map the queryTerm objects to a list of strings
    if (query.queryTerms.isEmpty) {
      // return an empty collection if no query terms are supplied
      return {};
    }
    // get N from the index collection
    final docCount = await index.getCollectionSize();
    // initialize a collection for the terms (strings) in the query
    var terms = query.queryTerms.terms;
    // get the document frequencies for the terms
    final dfTMap = await index.getDictionary(terms);
    // expand the terms if not all terms were found in the dictionary
    final unMatchedTerms = await _unmatchedTerms(dfTMap);
    // expand the query (replace unmatched terms with expanded ones)
    query.expandTerms(unMatchedTerms);
    // check for any additional terms and add them to the doc frequency map
    if (query.allTerms.toSet().union(terms).length != terms.length) {
      final List<QueryTerm> newEntries = [];
      for (final e in unMatchedTerms.values) {
        newEntries.addAll(e);
      }
      final newDfTMap = await index.getDictionary(
          newEntries.terms.where((e) => !dfTMap.keys.contains(e)));
      dfTMap.addAll(newDfTMap);
    }
    // now discard any terms that have a inverse doc frequency below the threshold
    query.purgeTerms(dfTMap, docCount);
    // update the terms collection
    terms = query.queryTerms.terms;
    // get the postings for the query
    final PostingsMap postings =
        await _addPostingsForAllModifiers(query.queryTerms);
    // Map the postings to a hashmap of docid to SearchResult
    final retVal = await _postingsToSearchResults(
        postings, query.queryTerms, dfTMap, docCount);
    // return the results and proceed to scoring and ranking
    return retVal;
  }

  Future<Map<String, SearchResult>> _postingsToSearchResults(
      PostingsMap postings,
      Iterable<QueryTerm> queryTerms,
      DftMap dfTMap,
      int docCount) async {
    final qt = queryTerms.map((e) => e.term).toSet();
    final terms = postings.keys.where((element) => qt.contains(element));

    final keywordPostings = await index.getKeywordPostings(terms);

    final docIds = postings.docIds;
    final searchResults = <String, SearchResult>{};
    for (final docId in docIds) {
      final value = SearchResult.fromPostings(
          docId: docId,
          query: query,
          docCount: docCount,
          postings: postings,
          dFtMap: dfTMap,
          keyWordPostings: keywordPostings);
      if (value != null && value.tfIdfScore > 0) {
        searchResults[docId] = value;
      }
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

  Future<Map<String, Iterable<QueryTerm>>> _unmatchedTerms(
      Map<String, dynamic> postings) async {
    final found = postings.keys.toSet();
    final Map<String, Set<QueryTerm>> retVal = {};
    final unmatched =
        query.queryTerms.where((element) => !found.contains(element.term));
    for (final e in unmatched) {
      retVal[e.term] = await _expandQuery(e, 2);
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

  /// Queries the k-gram index for terms similar to [queryTerm] and then
  /// returns the top [limit] matches as [QueryTerm] instances.
  Future<Set<QueryTerm>> _expandQuery(QueryTerm queryTerm, int limit) async {
    final term =
        queryTerm.term.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final candidates = await index.getKGramIndex(term.kGrams(index.k));
    final terms = candidates.terms.toList();
    if (term.length < 4) {}
    var suggestions = (term.length < 4)
        ? term.startsWithSimilarities(terms)
        : term.getSuggestions(terms, limit: limit, k: index.k);
    suggestions = suggestions.length > limit
        ? suggestions.sublist(0, limit)
        : suggestions;
    final matches = suggestions.map((e) => e.term);
    return matches
        .map((e) => QueryTerm(e, QueryTermModifier.AND, queryTerm.termPosition,
            e.split(' ').length))
        .toSet();
  }
}

///
abstract class IndexSearchBase with IndexSearchMixin {
  ///
  const IndexSearchBase();
}

///
class _IndexSearchImpl extends IndexSearchBase {
//

  @override
  final FreeTextQuery query;

  @override
  final InvertedIndex index;

  /// Hydrates a [IndexSearch] instance with the [index].
  const _IndexSearchImpl(this.index, this.query);
}
