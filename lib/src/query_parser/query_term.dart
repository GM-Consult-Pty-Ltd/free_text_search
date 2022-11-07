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

  /// Compares whether:
  /// - [other] is [QueryTerm];
  /// - [modifier] == [other].modifier;
  /// - [term] == [other].term; and
  /// - [termPosition] == [other].termPosition.
  /// Does not compare [zone] as it is always null or [termPosition] as we only
  /// want to retain one element for a term/modifier combination.
  @override
  bool operator ==(Object other) =>
      other is QueryTerm && term == other.term && modifier == other.modifier;

  @override
  int get hashCode => Object.hash(term, modifier, termPosition);

  //
}

///
extension QueryTermListExtension on List<QueryTerm> {
  //

  /// Returns a subset of the collection that is unique for the combination
  /// of term/modifier. Iterates from the end of the collection to
  void unique() {
    final Map<String, QueryTerm> retVal = {};
    for (var i = length - 1; i > -1; i--) {
      final qt = this[i];
      final key = '${qt.term}::%${qt.modifier.toString()}%';
      retVal[key] = qt;
    }
    clear();
    addAll(retVal.values);
    sort(((a, b) => a.termPosition.compareTo(b.termPosition)));
  }
}

///
extension QueryTermCollectionExtension on Iterable<QueryTerm> {
  //

  /// Returns a list of [QueryTerm] objects that are unique for the combination
  /// of term/modifier. Iterates from the end of the collection to retain the
  /// term with the lowest term position.
  List<QueryTerm> unique() {
    // final list = toList();
    final Map<String, QueryTerm> retVal = {};
    for (final qt in this) {
      final key = '${qt.term}::%${qt.modifier.toString()}%';
      if (!retVal.keys.contains(key)) {
        retVal[key] = qt;
      }
    }
    final list = retVal.values.toList()
      ..sort(((a, b) => a.termPosition.compareTo(b.termPosition)));
    return list;
  }

  /// Filters the collection by [modifier] and returns a
  List<QueryTerm> filterByModifier(QueryTermModifier modifier) =>
      where((element) => element.modifier == modifier).unique();

  /// Returns the [QueryTerm] elements where [QueryTerm.modifier] is equal to:
  /// [QueryTermModifier.EXACT]; or
  /// [QueryTermModifier.AND]; or
  /// [QueryTermModifier.IMPORTANT].
  List<QueryTerm> get andTerms => where((element) =>
      element.modifier == QueryTermModifier.EXACT ||
      element.modifier == QueryTermModifier.AND ||
      element.modifier == QueryTermModifier.IMPORTANT).unique();

/// Returns the [QueryTerm] elements where [QueryTerm.modifier] is equal to
  /// [QueryTermModifier.NOT].
  List<QueryTerm> get notTerms => filterByModifier(QueryTermModifier.NOT);

  /// A list of all the [Term]s in the collection that contain white-space.
  List<String> get phrases =>
      uniqueTerms.where((element) => element.contains(' ')).toList();

  /// A list of the unique [Term]s in the collection in the same order
  /// as they occur in the source text.
  Set<Term> get uniqueTerms => allTerms.toSet();
}
