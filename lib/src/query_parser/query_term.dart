// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// Extends a [Token], representing a term in a free text query phrase:
/// - [term] is the term that will be looked up in the index;
/// - [termPosition] is the zero-based position of the [term] in an ordered
///   list of all the terms in the source text; and
/// - [modifier] is the modifier used for this term.
class QueryTerm extends Token {
  //

  /// Instantiates a const [QueryTerm] instance:
  /// - [term] is the term that will be looked up in the index;
  /// - [termPosition] is the zero-based position of the [term] in an ordered
  ///   list of all the terms in the source text; and
  /// - [modifier] is the modifier used for this term.
  const QueryTerm(String term, this.modifier, int termPosition, int n)
      : super(term, n, termPosition);

  /// The modifier used for this term.
  ///
  /// All terms are marked [QueryTermModifier.AND] unless marked with another
  /// modifier.
  final QueryTermModifier modifier;

  //
}

///
extension QueryTermCollectionExtension on Iterable<QueryTerm> {
  //

  /// Returns the [QueryTerm] elements where [QueryTerm.modifier] is equal to:
  /// [QueryTermModifier.EXACT]; or
  /// [QueryTermModifier.AND]; or
  /// [QueryTermModifier.IMPORTANT].
  List<QueryTerm> get andTerms => where((element) =>
      element.modifier == QueryTermModifier.EXACT ||
      element.modifier == QueryTermModifier.AND ||
      element.modifier == QueryTermModifier.IMPORTANT).toList();

  /// A list of all the [Term]s in the collection that contain white-space.
  List<String> get phrases =>
      uniqueTerms.where((element) => element.contains(' ')).toList();

  /// A list of the unique [Term]s in the collection  in the same order
  /// as they occur in the source text.
  Set<Term> get uniqueTerms => allTerms.toSet();
}
