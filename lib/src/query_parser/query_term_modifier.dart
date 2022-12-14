// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// ignore_for_file: constant_identifier_names

/// Enumerations of modifiers used in free text queries:
/// - all terms are marked [AND] unless marked with another modifier;
/// - terms preceding and following "OR" are marked [OR];
/// - terms following the hyphen "-" are marked [NOT]; and
/// - terms enclosed in double "quotes", are marked [EXACT].
enum QueryTermModifier {
  //

  /// Default. All terms are marked [AND] unless marked with another modifier.
  AND,

  /// Terms preceding and following "OR" are marked [OR].
  OR,

  /// Terms following the hyphen "-" or the upper case word 'NOT'  are marked
  /// [NOT].
  NOT,

  /// Terms following the plus sign "+" are marked [IMPORTANT].
  IMPORTANT,

  /// Terms enclosed in double "quotes", are marked [EXACT].
  EXACT,

  // /// A concatenation of two or more adjacent terms into a phrase.
  // PHRASE,
}

