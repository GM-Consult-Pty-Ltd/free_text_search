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
      double? iDfThreshold,
      bool expandUnmatched = false}) {
    return _FreeTextQueryImpl(phrase, queryTerms.toSet(), targetResultSize,
        weightingStrategy, iDfThreshold, expandUnmatched);
  }

  /// The unmodified search phrase, including all modifiers and tokens.
  String get phrase;

  /// A flag that instructs search classes whether to expand any unmatched
  /// terms (e.g. correct spelling).
  bool get expand;

  /// A threshold value for the minimum inverse document frequency (iDf) of
  /// query terms.
  ///
  /// When [iDfThreshold] is not null and greater than 0.0, query terms that
  /// have a iDf less that [iDfThreshold] will be ignored.
  double? get iDfThreshold;

  /// The desired size of the result set.
  int get targetResultSize;

  /// A list of the [QueryTerm]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  Set<QueryTerm> get queryTerms;

  /// A list of all the terms extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  List<String> get allTerms;

  /// A list of the unique terms extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  Set<String> get uniqueTerms;

  /// A list of all the terms in the query that contain white-space.
  List<String> get phrases;

  /// A hashmap of [QueryTermModifier] to weighting value.
  ///
  /// Weights are used in calculating the [QuerySearchResult.tfIdfScore], used in
  /// extracting the top [FreeTextQuery.targetResultSize] results from an
  /// index.
  WeightingStrategy get weightingStrategy;

  /// A hashmap of query terms to weighted tf-idf for the term in the document.
  /// The raw tf-idf is multiplied by the modifier weight and the phrase length
  /// weight in the [weightingStrategy].
  ///
  /// - [dftMap] is a hashmap of query term to document frequency of the term
  ///   in the collection; and
  /// - [n] is the total number of documents in the collection.
  /// The tf-idf weighting for the document is the product of the term's
  /// frequency in the document with the inverse document frequency of
  /// the term in the collection and the .
  ///
  /// ``` dart
  ///   tfIdf(idFt) => tFt * idFt
  /// ``
  Map<String, double> tfIdfVector(DftMap dftMap, int n);

  /// Replaces elements of [queryTerms] with the values in [newTerms].
  ///
  /// The key of the [newTerms] hashmap is the old query term's term.
  void expandTerms(Map<String, Iterable<QueryTerm>> newTerms);

  /// Removes elements of [queryTerms] where the inverse document frequency is
  /// below [iDfThreshold].
  void purgeTerms(DftMap docFrequencyMap, int n);
}

/// Mixin class that implements [FreeTextQuery.phrases],
/// [FreeTextQuery.allTerms] and [FreeTextQuery.uniqueTerms].
abstract class FreeTextQueryMixin implements FreeTextQuery {
  //

  @override
  final queryTerms = <QueryTerm>{};

  /// Returns a hashmap of terms to [QueryTerm]
  Map<String, QueryTerm> get queryTermsMap => <String, QueryTerm>{}
    ..addEntries(queryTerms.map((e) => MapEntry(e.term, e)));

  @override
  void purgeTerms(DftMap docFrequencyMap, int n) {
    final qtMap = Map<String, QueryTerm>.from(queryTermsMap);
    final idFtMap = docFrequencyMap.idFtMap(n);
    final termsToRemove = idFtMap.entries
        .where((element) => element.value < (iDfThreshold ?? 0.0))
        .map((e) => e.key);
    qtMap.removeWhere((key, value) => termsToRemove.contains(key));
    queryTerms.removeWhere((e) => termsToRemove.contains(e.term));
  }

  @override
  void expandTerms(Map<String, Iterable<QueryTerm>> newTerms) {
    final qtMap = Map<String, QueryTerm>.from(queryTermsMap);
    qtMap.removeWhere((key, value) => newTerms.keys.contains(key));
    final newEntries = <QueryTerm>[];
    for (final e in newTerms.values) {
      newEntries.addAll(e);
    }
    queryTerms.removeWhere((e) => newTerms.keys.contains(e.term));
    queryTerms.addAll(newEntries);
  }

  @override
  Map<String, double> tfIdfVector(DftMap dftMap, int n) {
    final termFrequencies = <String, int>{};
    final qtMap = queryTermsMap;
    for (final t in allTerms) {
      termFrequencies[t] = (termFrequencies[t] ?? 0) + 1;
    }
    final Map<String, double> retVal = {};
    for (final qt in qtMap.values) {
      final t = qt.term;
      final wM = weightingStrategy.getWeight(qt).abs();
      final tf = termFrequencies[t] = (termFrequencies[t] ?? 0);
      final idf = dftMap.idFt(t, n);
      if (idf != null) {
        retVal[t] = tf * idf * wM;
      }
    }
    return retVal;
  }

  @override
  List<String> get phrases => queryTerms.phrases;

  @override
  List<String> get allTerms => queryTerms.allTerms;

  @override
  Set<String> get uniqueTerms => queryTerms.uniqueTerms;
}

/// A [FreeTextQuery] implementation base-class with [FreeTextQueryMixin].
abstract class FreeTextQueryBase with FreeTextQueryMixin {
//

}

class _FreeTextQueryImpl extends FreeTextQueryBase {
//

  @override
  final WeightingStrategy weightingStrategy;

  @override
  final String phrase;

  /// Instantiates a [FreeTextQuery] with the following required
  /// parameters:
  /// - [phrase] is the unmodified search phrase, including all modifiers and
  ///   tokens; and
  /// - [queryTerms] is the a collection of all [QueryTerm] extracted from the
  ///   [phrase].
  _FreeTextQueryImpl(
      this.phrase,
      Set<QueryTerm> queryTerms,
      this.targetResultSize,
      this.weightingStrategy,
      this.iDfThreshold,
      this.expand) {
    this.queryTerms.addAll(queryTerms);
  }

  @override
  final double? iDfThreshold;

  @override
  final int targetResultSize;

  @override
  final bool expand;
}
