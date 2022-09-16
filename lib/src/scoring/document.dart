// Copyright ©2022, GM Consult (Pty) Ltd
// BSD 3-Clause License
// All rights reserved

import 'package:text_indexing/text_indexing.dart';
import 'postings_scoring_extensions.dart';

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
  factory Document.empty(DocId docId) {
    assert(docId.isNotEmpty, 'The docId paramater must not be empty.');
    return _DocumentImpl(docId, {}, {});
  }

  /// Returns an updated [Document] after updating the [termFrequencies]
  /// and [termFieldPostings] for [term] from the [entry].
  Document addPostings(Term term, DocumentPostingsEntry entry);

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
  Ft tF(Term term);

  /// A hashmap of [Term]s to [FieldPostings] for the document.
  Map<Term, FieldPostings> get termFieldPostings;

  //
}

class _DocumentImpl implements Document {
  //

  @override
  Document addPostings(Term term, DocumentPostingsEntry entry) {
    final docId = entry.key;
    if (docId != this.docId) return this;
    termFieldPostings[term] = entry.value;
    final Map<Term, Ft> termFrequencies =
        Map<Term, Ft>.from(this.termFrequencies);
    termFrequencies[term] = entry.value.tFt;

    return _DocumentImpl(docId, termFieldPostings, termFrequencies);
  }

  @override
  final DocId docId;

  const _DocumentImpl(this.docId, this.termFieldPostings, this.termFrequencies);

  @override
  Ft tF(Term term) => termFrequencies[term] ?? 0;

  @override
  final Map<FieldName, FieldPostings> termFieldPostings;

  @override
  final Map<Term, Ft> termFrequencies;

  @override
  List<Term> get terms {
    final terms = termFrequencies.keys.toList();
    terms.sort(((a, b) => a.compareTo(b)));
    return terms;
  }
}
