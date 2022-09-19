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
      {required String phrase, required List<QueryTerm> queryTerms}) {
    return _FreeTextQueryImpl(phrase: phrase, queryTerms: queryTerms);
  }

  /// The unmodified search phrase, including all modifiers and tokens.
  String get phrase;

  /// A list of the [QueryTerm]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  List<QueryTerm> get queryTerms;

  /// A list of the [Term]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  List<Term> get allTerms;

  /// A list of the [Term]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  Set<Term> get uniqueTerms;

  /// A list of all the terms in the query that contain white-space.
  List<String> get phrases;
}

class _FreeTextQueryImpl implements FreeTextQuery {
//

  @override
  List<String> get phrases => queryTerms.phrases;

  /// The unmodified search phrase, including all modifiers and tokens.
  @override
  final String phrase;

  /// A list of the [QueryTerm]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  @override
  final List<QueryTerm> queryTerms;

  /// A list of the [Term]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  @override
  List<Term> get allTerms => queryTerms.allTerms;

  /// A list of the [Term]s extracted from the [phrase] in the same order
  /// as they occur in the [phrase].
  @override
  Set<Term> get uniqueTerms => queryTerms.uniqueTerms;

  /// Instantiates a const [FreeTextQuery] with the following required
  /// parameters:
  /// - [phrase] is the unmodified search phrase, including all modifiers and
  ///   tokens; and
  /// - [queryTerms] is the ordered list of all [QueryTerm] extracted from the
  ///   [phrase].
  const _FreeTextQueryImpl({required this.phrase, required this.queryTerms});
}
