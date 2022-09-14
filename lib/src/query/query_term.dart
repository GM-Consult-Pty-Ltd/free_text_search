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
  const QueryTerm(String term, this.modifier, int termPosition,
      [int index = 0, double position = 0.0])
      : super(term, termPosition);

  /// The modifier used for this term.
  ///
  /// All terms are marked [QueryTermModifier.AND] unless marked with another
  /// modifier.
  final QueryTermModifier modifier;
}
