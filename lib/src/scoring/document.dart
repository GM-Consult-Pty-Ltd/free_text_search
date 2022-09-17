// Copyright ©2022, GM Consult (Pty) Ltd
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/free_text_search.dart';
import 'package:text_indexing/text_indexing.dart';
import 'postings_scoring_extensions.dart';
import 'dart:math';

/// Alias for Map<String, int>
typedef TermFrequencyMap = Map<Term, Ft>;

/// The [Document] object-model enumerates the properties of a document and
/// its indexed terms in an inverted positional index.
///
/// The [Document] properties are stored in the [Postings] of the index,
/// distributed over the vocabulary terms.  [Document]s are extracted from
/// the [Postings] by filtering the [Postings] entries for [DocumentPostingsEntry]
/// elements with the same identifier [docId] as the document.
abstract class Document {
  //

  /// Initializes a [Document] with all fields empty, except [docId].
  ///
  /// An exception is thrown if the [docId] parameter is empty.
  factory Document.empty(DocId docId) {
    assert(docId.isNotEmpty, 'The docId parameter must not be empty.');
    return _DocumentImpl(docId, {}, {}, []);
  }

  /// Returns an updated [Document] after inserting the [term] in [terms] and
  /// overwriting the [termFrequencies] and [termFieldPostings] for [term].
  Document setTermPostings(Term term, DocumentPostingsEntry entry);

  /// Instantiates a const [Document] instance.
  const Document();

  /// The document's unique identifier ([DocId]) in the corpus.
  DocId get docId;

  /// An alphabetically ordered list of the [Term]s in the document.
  List<Term> get terms;

  /// A hashmap of [Term]s to the number of times ([Ft]) each [Term] occurs in
  /// the document.
  Map<Term, Ft> get termFrequencies;

  /// Returns the frequency of [term] in the document.
  Ft tFt(Term term);

  /// A hashmap of [Term]s to [FieldPostings] for the document.
  Map<Term, FieldPostings> get termFieldPostings;

  /// Returns a weighting that reflects the number of term pairs that are
  /// matched in a document.  The weight is calculated as follows:
  /// fqPt - is the number of term pairs in query; and
  /// fdPt - is the number of query term pairs present in the document.
  double proximityWeight(List<QueryTerm> queryTerms);

  //
}

class _DocumentImpl implements Document {
  //

  List<String> get phrases =>
      terms.where((element) => element.contains(' ')).toList();

  @override
  double proximityWeight(List<QueryTerm> queryTerms) {
    // TODO: implement proximityWeight
    throw UnimplementedError();
  }

  // @override
  // int pairMatches(List<TermPair> termPairs) {
  //   var matches = 0;
  //   final docTermPairs = <TermPair>[];
  //   for (var i = 0; i < terms.length - 1; i++) {
  //     final termPair = TermPair(terms[i], terms[i + 1]);
  //     docTermPairs.add();
  //     matches = termPairs.contains(termPair) ? matches++ : matches;
  //   }
  //   final weight = log(matches / termPairs.length / (terms.length - 1));
  //   return matches;
  // }

  @override
  Document setTermPostings(Term term, DocumentPostingsEntry entry) {
    final docId = entry.key;
    // First check the entry is for this document
    if (docId != this.docId) return this;
    // Make a copy of termFieldPostings
    final termFieldPostings =
        Map<String, FieldPostings>.from(this.termFieldPostings);
    // make a copy of termFrequencies
    final Map<Term, Ft> termFrequencies =
        Map<Term, Ft>.from(this.termFrequencies);
    // overwrite/insert the field postings for term
    termFieldPostings[term] = entry.value;
    // overwrite/insert the frequency for term
    termFrequencies[term] = entry.value.tFt;

    /// get the terms from termFrequencies
    final terms = termFrequencies.keys.toList();
    // sort the terms alphabetically
    terms.sort(((a, b) => a.compareTo(b)));
    // return a new _DocumentImpl wiht the updated termFieldPostings and
    // termFrerquencies
    return _DocumentImpl(docId, termFieldPostings, termFrequencies, terms);
  }

  @override
  final DocId docId;

  const _DocumentImpl(
      this.docId, this.termFieldPostings, this.termFrequencies, this.terms);

  @override
  Ft tFt(Term term) => termFrequencies[term] ?? 0;

  @override
  final Map<FieldName, FieldPostings> termFieldPostings;

  @override
  final Map<Term, Ft> termFrequencies;

  @override
  final List<Term> terms;
}
