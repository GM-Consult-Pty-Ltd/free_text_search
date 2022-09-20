// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';
import 'dart:math';

/// Extension methods on a collection of [ZonePostings].
extension FieldPostingsExtension on ZonePostings {
  //

  /// Returns the term frequncy in a [ZonePostings] instance.
  Ft get tFt {
    var tFt = 0;
    for (final entry in values) {
      tFt += entry.length;
    }
    return tFt;
  }
}

///
extension DocumentPostingsEntryScoringExtension on DocumentPostingsEntry {
  //

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
  //

  /// Iterates through all the entries in the postings and builds a hashmap
  /// of [DocId] to [Document].
  Map<DocId, Document> documents(Iterable<Term> terms) {
    final documents = <DocId, Document>{};
    for (final term in terms) {
      final Iterable<DocumentPostingsEntry> docEntries =
          this[term]?.entries.toList() ?? [];
      for (final entry in docEntries) {
        // get the id of the document from the entry
        final docId = entry.key;
        // get the document from championList if it already exists, otherwise initialize one
        Document document = documents[docId] ?? Document.empty(docId);
        // add the document postings for term to document
        document = document.setTermPostings(term, entry);
        // update the document in the documents hashmap
        documents[docId] = document;
      }
    }
    return documents;
  }

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

  /// The inverse document frequency is the logarithm of the total number of
  /// documents ([N]) divided by the document frequency (df) of term [t].
  ///
  /// ``` dart
  /// idFt(t, N) = log ( N / dFt(t) )
  /// ```
  double idFt(Term t, int N) => log(N / dFt(t));
}
