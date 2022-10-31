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
      required List<QueryTerm> queryTerms,
      int targetResultSize = 50}) {
    return _FreeTextQueryImpl(phrase, queryTerms, targetResultSize);
  }

  /// The unmodified search phrase, including all modifiers and tokens.
  String get phrase;

  /// The desired size of the result set.
  int get targetResultSize;

  /// A list of the [QueryTerm]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  List<QueryTerm> get queryTerms;

  /// A list of all the [Term]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  List<Term> get allTerms;

  /// A list of the unique [Term]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  Set<Term> get uniqueTerms;

  /// A list of all the terms in the query that contain white-space.
  List<String> get phrases;

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
}

/// Mixin class that implements [FreeTextQuery.phrases],
/// [FreeTextQuery.allTerms] and [FreeTextQuery.uniqueTerms].
abstract class FreeTextQueryMixin implements FreeTextQuery {
  //

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

  /// The unmodified search phrase, including all modifiers and tokens.
  @override
  final String phrase;

  /// A list of the [QueryTerm]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  @override
  final List<QueryTerm> queryTerms;

  /// Instantiates a const [FreeTextQuery] with the following required
  /// parameters:
  /// - [phrase] is the unmodified search phrase, including all modifiers and
  ///   tokens; and
  /// - [queryTerms] is the ordered list of all [QueryTerm] extracted from the
  ///   [phrase].
  const _FreeTextQueryImpl(this.phrase, this.queryTerms, this.targetResultSize);

  @override
  final int targetResultSize;
}
