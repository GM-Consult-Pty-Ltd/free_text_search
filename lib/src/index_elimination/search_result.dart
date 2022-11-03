// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'dart:math';
import 'package:free_text_search/src/_index.dart';
import 'package:collection/collection.dart';

part 'index_elimination_extensions.dart';

/// Object model for a search result of a query against a text index.
/// - [docId] is the identifier of the document result in the corpus.
/// - [termPostings] is a hashmap of query terms to postings of the term in
///   the document.
/// - [termFrequencies] is a  hashmap of query terms to the number of times
///   each term occurs in the document.
/// - [keywordScores] is a hashmap of query terms to keyword scores.
/// - [tfIdfVector] is a hashmap of query terms to tf-idf for the term in
///   the document.
/// - [tfIdfScore] is the weighted sum of all the tf-idf weights in
///   [tfIdfVector].
/// - [queryTerms] is all the query terms mapped to this document.
abstract class SearchResult {
  //

  //   @override
  // final Map<Term, Map<Term, int>> termZoneFrequencies;

  // @override
  // final Map<Term, double> weightedTermFrequencies;

  ///  /// A factory constructor that constructs a search result for a document id.
  /// - [docId] is the identifier of the document result in the corpus.
  /// - [termPostings] is a hashmap of query terms to postings of the term in
  ///   the document.
  /// - [termFrequencies] is a  hashmap of query terms to the number of times
  ///   each term occurs in the document.
  /// - [keywordScores] is a hashmap of query terms to keyword scores.
  /// - [tfIdfVector] is a hashmap of query terms to tf-idf for the term in
  ///   the document.
  /// - [tfIdfScore] is the weighted sum of all the tf-idf weights in
  ///   [tfIdfVector].
  factory SearchResult(
          {required String docId,
          required Map<String, double> keywordScores,
          required Map<String, Map<String, List<int>>> termPostings,
          required Map<Term, Map<Term, int>> termZoneFrequencies,
          required Map<Term, double> weightedTermFrequencies,
          required Map<String, int> termFrequencies,
          required Map<String, double> tfIdfVector,
          required double tfIdfScore}) =>
      _SearchResultImpl(
          docId,
          keywordScores,
          termPostings,
          termFrequencies,
          tfIdfVector,
          tfIdfScore,
          termZoneFrequencies,
          weightedTermFrequencies);

  /// A static factory that constructs a search result for a document id.
  /// Returns null if the document contains none of the query terms or only
  /// query terms with the [QueryTermModifier.NOT] modifier.
  /// - [docId] is the unique identifier of the document result in the corpus.
  /// - [docCount] is the total number of documents in the corpus, used to
  ///   compute tf-Idf for each term.
  /// - [postings] is a hashmap of the query terms to the postings for [docId].
  /// - [dFtMap] is the a hashmap of query term to document frequency of the
  ///   term, used to calculate the iDf and tf-Idf values.
  /// - [keyWordPostings] is h hashmap of query terms to keyword score postings
  ///   for the document, from which the keyword scores are extracted for the
  ///   search result/docId.
  static SearchResult? fromPostings(
      {required DftMap dFtMap,
      required int docCount,
      required FreeTextQuery query,
      required String docId,
      required PostingsMap postings,
      required KeywordPostingsMap keyWordPostings}) {
    final notQueryTerms =
        query.queryTerms.filterByModifier(QueryTermModifier.NOT).uniqueTerms;
    final docTermPostings = postings.docTermPostings(docId);
    final docTerms = docTermPostings.keys.toSet();
    if (docTerms.isEmpty ||
        docTerms.union(notQueryTerms).length == notQueryTerms.length) {
      return null;
    }
    final keywordScores = keyWordPostings.docKeywordScores(docId);
    final termZoneFrequencies = docTermPostings.termZoneFrequencies(query);
    final termFrequencies = termZoneFrequencies.termFrequencies(query);
    final weightedTermFrequencies =
        termZoneFrequencies.weightedTermFrequencies(query);
    // docTermPostings.docTermFrequencies(query.weightingStrategy.zoneWeights);
    final tfIdfVector = dFtMap.tfIdfMap(weightedTermFrequencies, docCount);
    final tfIdfScore = tfIdfVector.computeTfIdfScore(query);
    return _SearchResultImpl(
        docId,
        keywordScores,
        docTermPostings,
        termFrequencies,
        tfIdfVector,
        tfIdfScore,
        termZoneFrequencies,
        weightedTermFrequencies);
  }

  /// The unique identifier of the document result in the corpus.
  String get docId;

  /// A hashmap of query terms to postings of the term in the document.
  Map<Term, ZonePostingsMap> get termPostings;

  /// A hashmap of query terms to the number of times each term occurs in
  /// the document.
  Map<Term, Ft> get termFrequencies;

  /// A hashmap of query terms to the number of times each term occurs in
  /// the document.
  Map<Term, double> get weightedTermFrequencies;

  /// The frequency of a term in the zones of the document.
  Map<Term, Map<Term, int>> get termZoneFrequencies;

  /// A hashmap of query terms to keyword scores.
  Map<Term, double> get keywordScores;

  /// A hashmap of query terms to tf-idf for the term in the document.
  ///
  /// The tf-idf weighting for a term is the product of the term's
  /// weighted frequency in the document with the inverse document frequency of
  /// the term in the collection.
  ///
  /// ``` dart
  ///   tfIdf(idFt) => tFt * idFt
  /// ``
  Map<Term, double> get tfIdfVector;

  /// Returns all the query terms mapped to this document.
  Set<Term> get queryTerms;

  /// Returns the sum of all the tf-idf weights in [tfIdfVector].
  double get tfIdfScore;

  /// Returns the term frequency of a term in the document.
  int tFt(Term term);

  /// Returns the tf-idf weighting for [term] in the document.
  double tfIdf(Term term);

  /// Returns the cosine similarity of the vector representations of the
  /// tf-idf weights of the terms in [query] and the same terms in the document.
  double cosineSimilarity(FreeTextQuery query);

  //
}

/// Mixin class that implements [SearchResult].
abstract class SearchResultMixin implements SearchResult {
//

  @override
  double cosineSimilarity(FreeTextQuery query) {
    // TODO: implement cosineSimilarity
    throw UnimplementedError();
  }

  @override
  double tfIdf(Term term) => tfIdfVector[term] ?? 0;

  @override
  int tFt(Term term) => termFrequencies[term] ?? 0;

  @override
  Set<String> get queryTerms => <String>{}
    ..addAll(termPostings.keys)
    ..addAll(keywordScores.keys);

//
}

/// Base class that implements [SearchResult] and mixes in [SearchResultMixin].
///
/// Provides a const default generative constructor for sub-classes.
abstract class SearchResultBase with SearchResultMixin {
  //

  /// A const default generative constructor for sub-classes.
  const SearchResultBase();
}

/// Implementation class for [SearchResult] factories.
class _SearchResultImpl extends SearchResultBase {
  //

  // Default generative constructor.
  const _SearchResultImpl(
      this.docId,
      this.keywordScores,
      this.termPostings,
      this.termFrequencies,
      this.tfIdfVector,
      this.tfIdfScore,
      this.termZoneFrequencies,
      this.weightedTermFrequencies);

  @override
  final String docId;

  @override
  final Map<String, double> keywordScores;

  @override
  final Map<String, ZonePostingsMap> termPostings;

  @override
  final Map<Term, Ft> termFrequencies;

  @override
  final Map<String, double> tfIdfVector;

  @override
  final double tfIdfScore;

  @override
  final Map<Term, Map<Term, int>> termZoneFrequencies;

  @override
  final Map<Term, double> weightedTermFrequencies;

  //
}
