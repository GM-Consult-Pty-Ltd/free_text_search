// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// A object model class that enumerates the properties of a text search query:
/// - [phrase] is the unmodified search phrase, including all modifiers and
///   tokens; and
/// - [queryTerms] is the ordered list of all terms extracted from the [phrase]
///   used to look up results in an inverted index.
abstract class FreeTextQuery {
//

  ///
  factory FreeTextQuery(
      {required String phrase,
      required Iterable<QueryTerm> queryTerms,
      int targetResultSize = 50,
      WeightingStrategy weightingStrategy = WeightingStrategy.simple,
      double? iDfThreshold}) {
    return _FreeTextQueryImpl(
        phrase, queryTerms, targetResultSize, weightingStrategy, iDfThreshold);
  }

  /// A threshold value for the minimum inverse document frequency (iDf) of
  /// query terms.
  ///
  /// When [iDfThreshold] is not null and greater than 0.0, query terms that
  /// have a iDf less that [iDfThreshold] will be ignored.
  double? get iDfThreshold;

  /// The unmodified search phrase, including all modifiers and tokens.
  String get phrase;

  /// The desired size of the result set.
  int get targetResultSize;

  /// A list of the [QueryTerm]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  Iterable<QueryTerm> get queryTerms;

  /// A list of all the [Term]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  List<Term> get allTerms;

  /// A list of the unique [Term]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  Set<Term> get uniqueTerms;

  /// A list of all the terms in the query that contain white-space.
  List<String> get phrases;

  /// A hashmap of [QueryTermModifier] to weighting value.
  ///
  /// Weights are used in calculating the [SearchResult.tfIdfScore], used in
  /// extracting the top [FreeTextQuery.targetResultSize] results from an
  /// index.
  WeightingStrategy get weightingStrategy;

  /// A hashmap of query terms to tf-idf for the term in the document.
  ///
  /// - [dftMap] is a hashmap of query term to document frequency of the term
  ///   in the collection; and
  /// - [n] is the total number of documents in the collection.
  /// The tf-idf weighting for the document is the product of the term's
  /// frequency in the document with the inverse document frequency of
  /// the term in the collection.
  ///
  /// ``` dart
  ///   tfIdf(idFt) => tFt * idFt
  /// ``
  Map<Term, double> tfIdfVector(DftMap dftMap, int n);

  /// Returns a copy of the [FreeTextQuery], replacing elements of [queryTerms]
  /// with values in [newTerms]. The key of the [newTerms] hashmap is the old
  /// query term's term.
  FreeTextQuery expandTerms(Map<String, Iterable<QueryTerm>> newTerms);

  /// Returns a copy of the [FreeTextQuery], removing elements of [queryTerms]
  /// where the inverse document frequency is below [iDfThreshold]
  FreeTextQuery purgeTerms(DftMap docFrequencyMap, int n);
}

/// Mixin class that implements [FreeTextQuery.phrases],
/// [FreeTextQuery.allTerms] and [FreeTextQuery.uniqueTerms].
abstract class FreeTextQueryMixin implements FreeTextQuery {
  //

  /// Returns a hashmap of terms to [QueryTerm]
  Map<String, QueryTerm> get queryTermsMap => <String, QueryTerm>{}
    ..addEntries(queryTerms.map((e) => MapEntry(e.term, e)));

  @override
  FreeTextQuery purgeTerms(DftMap docFrequencyMap, int n) {
    final qtMap = Map<String, QueryTerm>.from(queryTermsMap);
    final idFtMap = docFrequencyMap.getIdFtMap(n);
    final termsToRemove = idFtMap.entries
        .where((element) => element.value < (iDfThreshold ?? 0.0))
        .map((e) => e.key);
    qtMap.removeWhere((key, value) => termsToRemove.contains(key));
    return _FreeTextQueryImpl(phrase, qtMap.values.toList(), targetResultSize,
        weightingStrategy, iDfThreshold);
  }

  @override
  Map<Term, double> tfIdfVector(DftMap dftMap, int n) {
    final termFrequencies = <String, int>{};
    for (final t in allTerms) {
      termFrequencies[t] = (termFrequencies[t] ?? 0) + 1;
    }
    return termFrequencies
        .map((term, tF) => MapEntry(term, tF * dftMap.getIdFt(term, n)));
  }

  @override
  List<String> get phrases => queryTerms.phrases;

  @override
  List<Term> get allTerms => queryTerms.allTerms;

  @override
  Set<Term> get uniqueTerms => queryTerms.uniqueTerms;
}

/// A [FreeTextQuery] implementation base-class with [FreeTextQueryMixin].
///
/// Provides a const, unnamed default generative constructor for sub-classes.
abstract class FreeTextQueryBase with FreeTextQueryMixin {
//

  /// Const default generative constructor for sub-classes.
  const FreeTextQueryBase();
}

class _FreeTextQueryImpl extends FreeTextQueryBase {
//

  @override
  FreeTextQuery expandTerms(Map<String, Iterable<QueryTerm>> newTerms) {
    final qtMap = Map<String, QueryTerm>.from(queryTermsMap);
    qtMap.removeWhere((key, value) => newTerms.keys.contains(key));
    final newEntries = <QueryTerm>[];
    for (final e in newTerms.values) {
      newEntries.addAll(e);
    }
    qtMap.addEntries(newEntries.map((e) => MapEntry(e.term, e)));
    return _FreeTextQueryImpl(phrase, qtMap.values.toList(), targetResultSize,
        weightingStrategy, iDfThreshold);
  }

  @override
  final WeightingStrategy weightingStrategy;

  /// The unmodified search phrase, including all modifiers and tokens.
  @override
  final String phrase;

  /// A list of the [QueryTerm]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  @override
  final Iterable<QueryTerm> queryTerms;

  /// Instantiates a const [FreeTextQuery] with the following required
  /// parameters:
  /// - [phrase] is the unmodified search phrase, including all modifiers and
  ///   tokens; and
  /// - [queryTerms] is the ordered list of all [QueryTerm] extracted from the
  ///   [phrase].
  const _FreeTextQueryImpl(this.phrase, this.queryTerms, this.targetResultSize,
      this.weightingStrategy, this.iDfThreshold);

  @override
  final double? iDfThreshold;

  @override
  final int targetResultSize;
}
