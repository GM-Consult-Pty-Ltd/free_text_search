// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// A object model class that enumerates the properties of a text search query:
/// - [phrase] is the unmodified search phrase, including all modifiers and
///   tokens;
/// - [terms] is the ordered list of all terms extracted from the [phrase]
///   used to look up results in an inverted index;
/// - [mustInclude] is a set of unique terms that must appear at least once
///   in a document for it to be included in the search results; and
/// - [excludeTerms] is a set of unique terms that must not appear in a
///   document for it to be included in the search results.
class FreeTextQuery {
//

  /// The unmodified search phrase, including all modifiers and tokens.
  final String phrase;

  /// A hashmap of the terms extracted from the [phrase] that will be
  /// used to look up results in an inverted index.
  final List<QueryTerm> terms;

  /// Instantiates a const [FreeTextQuery] with the following required
  /// parameters:
  /// - [phrase] is the unmodified search phrase, including all modifiers and
  ///   tokens;
  /// - [terms] is the ordered list of all terms extracted from the [phrase]
  ///   used to look up results in an inverted index;
  /// - [mustInclude] is a set of unique terms that must appear at least once
  ///   in a document for it to be included in the search results (defaults to an
  ///   empty set); and
  /// - [excludeTerms] is a set of unique terms that must not appear in a
  ///   document for it to be included in the search results (defaults to an
  ///   empty set).
  const FreeTextQuery({required this.phrase, required this.terms});
}
