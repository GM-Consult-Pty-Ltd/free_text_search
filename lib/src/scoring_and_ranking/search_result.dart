// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

/// Object model for a ranked search result of a query against a text index:
/// - [docId] is the unique identifier of the document result in the corpus; and
/// - [relevance] is the relevance score awarded to the document by the scoring
///   and ranking  algorithm. Higher scores indicate increased relevance of the
///   document.
class SearchResult {
  //

  /// The unique identifier of the document result in the corpus.
  final String docId;

  /// The relevance score awarded to the document by the scoring and ranking
  /// algorithm.
  ///
  /// Higher scores indicate increased relevance of the document.
  final double relevance;

  /// Instantiates a const [SearchResult] instance:
  /// - [docId] is the unique identifier of the document result in the corpus; and
  /// - [relevance] is the relevance score awarded to the document by the scoring
  ///   and ranking  algorithm. Higher scores indicate increased relevance of the
  ///   document.
  const SearchResult(this.docId, this.relevance);
}
