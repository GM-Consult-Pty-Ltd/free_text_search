// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// A utility class that parses free text queries.
/// The [parse] method parses a search phrase to a collection of [QueryTerm]s
/// using:
/// - [configuration] is used to tokenize the query phrase (defaults to
///   [English.configuration]); and
/// - provide a custom [tokenFilter] if you want to manipulate tokens or
///   restrict tokenization to tokens that meet specific criteria (default is
///   [TextAnalyzer.defaultTokenFilter].
///
/// Ensure that the [configuration] and [tokenFilter] match the [TextAnalyzer]
/// used to construct the index on the target collection that will be searched.
class QueryParser extends TextAnalyzer {
  //

  /// Instantiates a [QueryParser] instance:
  /// - [configuration] is used to tokenize the query phrase (default is
  ///   [English.configuration]); and
  /// - provide a custom [tokenFilter] if you want to manipulate tokens or
  ///   restrict tokenization to tokens that meet specific criteria (default is
  ///   [TextAnalyzer.defaultTokenFilter].
  const QueryParser(
      {TextAnalyzerConfiguration configuration = English.configuration,
      TokenFilter tokenFilter = TextAnalyzer.defaultTokenFilter})
      : super(configuration: configuration, tokenFilter: tokenFilter);

//

  /// Parses a search [phrase] to a collection of [QueryTerm]s.
  List<QueryTerm> parse(String phrase) {
    // TODO: implement QueryParser.parse
    return [];
  }
}

// ///
// class QueryParserConfiguration extends English {}
