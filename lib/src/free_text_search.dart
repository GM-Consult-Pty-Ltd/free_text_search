// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// The free text class exposes the [search] method that returns a list of
/// [SearchResult] instances in descending order of relevance.
abstract class FreeTextSearch {
  //

  /// Asynchronously retrieves a [Postings] subset for a collection of terms
  /// from a [Postings] data source.
  PostingsLoader get postingsLoader;

  /// Asynchronously retrieves a [Dictionary] subset for a collection of terms
  /// from a [Dictionary] data source.
  DictionaryLoader get termsLoader;

  /// Returns a list of [SearchResult] instances in descending order of
  /// relevance to [phrase].
  Future<List<SearchResult>> search(String phrase);
}
