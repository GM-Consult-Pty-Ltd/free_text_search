// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// A object model class that enumerates the properties of a text search query:
/// - [phrase] is the unmodified search phrase, including all modifiers and
///   tokens; and
/// - [terms] is the ordered list of all terms extracted from the [phrase]
///   used to look up results in an inverted index.
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
  ///   tokens; and
  /// - [terms] is the ordered list of all terms extracted from the [phrase]
  ///   used to look up results in an inverted index.
  const FreeTextQuery({required this.phrase, required this.terms});
}
