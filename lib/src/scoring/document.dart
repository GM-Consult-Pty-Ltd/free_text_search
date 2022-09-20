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
    return _DocumentImpl(docId, {}, {}, [], 0.0, 0.0);
  }

  /// Returns an updated [Document] after inserting the [term] in [terms] and
  /// overwriting the [termFrequencies] and [termZonePostings] for [term].
  Document setTermPostings(Term term, DocumentPostingsEntry entry);

  /// Returns an updated [Document] after re-calculating [termPairWeight].
  Document setTermPairWeight(List<QueryTerm> queryTerms);

  /// Returns an updated [Document] after re-calculating [proximityWeight].
  Document setPoximityWeight(List<QueryTerm> queryTerms);

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

  /// A hashmap of [Term]s to [ZonePostings] for the document.
  Map<Term, ZonePostings> get termZonePostings;

  /// Returns a weighting that reflects the number of term pairs that are
  /// matched in a document.  The weight is calculated as follows:
  /// fqPt - is the number of term pairs in query; and
  /// fdPt - is the number of query term pairs present in the document.
  double get proximityWeight;

  /// Returns a weighting that reflects the number of term pairs that are
  /// matched in a document.  The weight is calculated as follows:
  /// fqPt - is the number of term pairs in query; and
  /// fdPt - is the number of query term pairs present in the document.
  double get termPairWeight;

  /// A list of all the terms in the document that contain white-space.
  List<String> get phrases;

  /// Returns the proprtion of query terms matched in the document.
  double termsMatchWeight(Iterable<QueryTerm> queryTerms);
  //

  Document setWeightings(Iterable<QueryTerm> queryTerms);
}

class _DocumentImpl implements Document {
  //

  @override
  List<String> get phrases =>
      terms.where((element) => element.contains(' ')).toList();

  @override
  Document setPoximityWeight(List<QueryTerm> queryTerms) {
    final proximityWeight = 0.0;
    //TODO: implement setProximityWeight
    return _DocumentImpl(docId, termZonePostings, termFrequencies, terms,
        termPairWeight, proximityWeight);
  }

  @override
  Document setTermPairWeight(List<QueryTerm> queryTerms) {
    double termPairWeight = 0.0;
    final queryPhrases = queryTerms.phrases.toSet();
    final docPhrases = phrases;
    final matchedPhrases =
        docPhrases.where((element) => queryPhrases.contains(element));
    if (queryPhrases.isNotEmpty &&
        docPhrases.isNotEmpty &&
        matchedPhrases.isNotEmpty) {
      termPairWeight = matchedPhrases.length / queryPhrases.length;
    }
    return _DocumentImpl(docId, termZonePostings, termFrequencies, terms,
        termPairWeight, proximityWeight);
  }

  @override
  final double termPairWeight;

  @override
  final double proximityWeight;

  @override
  Document setTermPostings(Term term, DocumentPostingsEntry entry) {
    final docId = entry.key;
    // First check the entry is for this document
    if (docId != this.docId) return this;
    // Make a copy of termZonePostings
    final termZonePostings =
        Map<String, ZonePostings>.from(this.termZonePostings);
    // make a copy of termFrequencies
    final Map<Term, Ft> termFrequencies =
        Map<Term, Ft>.from(this.termFrequencies);
    // overwrite/insert the field postings for term
    termZonePostings[term] = entry.value;
    // overwrite/insert the frequency for term
    termFrequencies[term] = entry.value.tFt;

    /// get the terms from termFrequencies
    final terms = termFrequencies.keys.toList();
    // sort the terms alphabetically
    terms.sort(((a, b) => a.compareTo(b)));
    // return a new _DocumentImpl wiht the updated termZonePostings and
    // termFrerquencies
    return _DocumentImpl(docId, termZonePostings, termFrequencies, terms,
        termPairWeight, proximityWeight);
  }

  @override
  final DocId docId;

  const _DocumentImpl(this.docId, this.termZonePostings, this.termFrequencies,
      this.terms, this.termPairWeight, this.proximityWeight);

  @override
  Ft tFt(Term term) => termFrequencies[term] ?? 0;

  @override
  double termsMatchWeight(Iterable<QueryTerm> queryTerms) {
    final andTerms = queryTerms.andTerms;
    final matchedTerms =
        termFrequencies.entries.where((element) => element.value != 0);
    return matchedTerms.length / andTerms.length;
  }

  @override
  final Map<Zone, ZonePostings> termZonePostings;

  @override
  final Map<Term, Ft> termFrequencies;

  @override
  final List<Term> terms;

  @override
  Document setWeightings(Iterable<QueryTerm> queryTerms) {
    // TODO: implement setWeightings
    throw UnimplementedError();
  }
}
