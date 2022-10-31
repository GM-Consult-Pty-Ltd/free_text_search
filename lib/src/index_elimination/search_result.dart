// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'dart:math';
import 'package:free_text_search/src/_index.dart';
import 'package:collection/collection.dart';

part 'index_elimination_extensions.dart';

/// Object model for a ranked search result of a query against a text index:
/// - [docId] is the unique identifier of the document result in the corpus; and
/// - [relevance] is the relevance score awarded to the document by the scoring
///   and ranking  algorithm. Higher scores indicate increased relevance of the
///   document.
abstract class SearchResult {
  //

  /// A factory constructor that constructs a search result for a document id
  /// from the [postings], [documentFrequencyMap] and [keyWordPostings].
  factory SearchResult(
      {required String docId,
      required int docCount,
      required PostingsMap postings,
      required DftMap dFtMap,
      required KeywordPostingsMap keyWordPostings}) {
    final docTermPostings = postings.docTermPostings(docId);
    final keywordScores = keyWordPostings.docKeywordScores(docId);
    final docTermFrequencies = docTermPostings.docTermFrequencies();
    final tfIdfMap = dFtMap.tfIdfMap(docTermFrequencies, docCount);
    final tfIdfScore = tfIdfMap.values.sum;
    return _SearchResultImpl(docId, keywordScores, docTermPostings,
        docTermFrequencies, tfIdfMap, tfIdfScore);
  }

  /// The unique identifier of the document result in the corpus.
  String get docId;

  /// A hashmap of query terms to postings of the term in the document.
  Map<Term, ZonePostingsMap> get termPostings;

  /// A hashmap of query terms to the number of times each term occurs in
  /// the document.
  Map<Term, Ft> get termFrequencies;

  /// A hashmap of query terms to keyword scores.
  Map<Term, double> get keywordScores;

  /// A hashmap of query terms to tf-idf for the term in the document.
  /// ///
  /// The tf-idf weighting for the document is the product of the term's
  /// frequency in the document with the inverse document frequency of
  /// the term in the collection.
  ///
  /// ``` dart
  ///   tfIdf(idFt) => tFt * idFt
  /// ``
  Map<Term, double> get tfIdfVector;

  /// Returns all the query terms mapped to this document.
  Set<Term> get queryTerms;

  /// Returns the term frequency of a term in the document.
  int tFt(Term term);

  /// Returns the tf-idf weighting for [term] in the document.
  double tfIdf(Term term);

  /// Returns the sum of all the tf-idf weights in [tfIdfMap].
  double get tfIdfScore;

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
  const _SearchResultImpl(this.docId, this.keywordScores, this.termPostings,
      this.termFrequencies, this.tfIdfVector, this.tfIdfScore);

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

  //
}
