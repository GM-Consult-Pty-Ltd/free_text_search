// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';
import 'package:text_indexing/text_indexing.dart';
import 'dart:math';

/// Stub for [VectorSpaceModel].
class VectorSpaceModel {
  //TODO: implement class [VectorSpaceModel]
}

///
extension DocumentPostingsEntryScoringExtension on DocumentPostingsEntry {
  /// The tf-idf weighting for the document is the product of the term's
  /// frequency in the document ([tFt]) with the inverse document frequency of
  /// the term ([PostingsExtension.idFt]) in the collection.
  ///
  /// ``` dart
  ///   tfIdf(idFt) => tFt * idFt
  /// ``
  double tfIdf(double idFt) => tFt * idFt;

  /// Returns the frequency of the term ([Ft]) in the document.
  Ft get tFt {
    var termFrequency = 0;
    for (final pL in fieldPostings.values) {
      termFrequency += pL.length;
    }
    return termFrequency;
  }
}

/// Extension methods and properties on [Postings].
extension PostingsScoringExtension on Postings {
  /// The number of occurences in the [Postings] of [term] (the
  /// collection frequency).
  Ft cFt(Term term) {
    var collectionFrequency = 0;
    final docPostings = this[term] ?? {};
    for (final e in docPostings.entries) {
      collectionFrequency += e.tFt;
    }
    return collectionFrequency;
  }

  /// The number of documents in the [Postings] that contains one or more
  /// instances of [term] (the document frequency of term).
  Ft dFt(Term term) => this[term]?.length ?? 0;

  /// The inverse document frequency is the logarith of the total number of
  /// documents ([N]) divided by the document frequency (df) of term [t].
  ///
  /// ``` dart
  /// idFt(t, N) = log ( N / dFt(t) )
  /// ```
  double idFt(Term t, int N) => log(N / dFt(t));

  /// Returns all the unique document ids ([DocId]) in the [Postings].
  Set<DocId> get documents {
    final Set<DocId> retVal = {};
    for (final docPostings in values) {
      retVal.addAll(docPostings.keys);
    }
    return retVal;
  }

  /// Returns a [Set] of [DocId] of those documents that contain all the
  /// [terms].
  Set<DocId> get andDocuments => containsAll(terms);

  /// Returns a [Set] of [DocId] of those documents that contain
  /// all the [terms].
  Set<DocId> containsAll(Iterable<Term> terms) {
    final byTerm = termPostings(terms);
    Set<String> intersection = byTerm.documents;
    for (final docPostings in byTerm.values) {
      intersection = intersection.intersection(docPostings.keys.toSet());
    }
    return intersection;
  }

  /// Returns a [Set] of [DocId] of those documents that contain
  /// all the [terms].
  Set<DocId> containsAny(Iterable<Term> terms) => termPostings(terms).documents;
}
