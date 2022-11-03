// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// ignore_for_file: constant_identifier_names

//TODO: remove this enum
import 'package:free_text_search/src/_index.dart';

/// Enumerates the tier of a search result.
enum SearchResultTier {
  //

  /// Results that contain any of the query terms, but not any terms
  /// marked with the [QueryTermModifier.NOT].
  contains,

  /// Results that contain terms marked with [QueryTermModifier.EXACT].
  exact,

  /// Results that contain terms marked with [QueryTermModifier.IMPORTANT].
  important,

  /// Results with a high term frequency or keyword score for the search
  /// term(s) or n-grams
  championList,

  /// Results that contain terms marked with [QueryTermModifier.NOT].
  not
}
