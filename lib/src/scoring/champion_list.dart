// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// A hashmap of [Term] to the list of [Document]s that contain that term.
/// - the list of [Document]s is in descending order of term frequency
/// ([Ft]); and
/// - the list is unique for [DocId], i.e. each document can only occur once
/// (ordered set).
typedef ChampionList = Map<Term, List<Document>>;

/// An entry in a [ChanpionList]
typedef ChampionListEntry = MapEntry<Term, List<Document>>;

/// Extension methods on a [Iterable] of [Document]s.
extension DocumentListExtension on Iterable<Document> {
//

  /// Returns ordered set of [Document]s, unique for [Document.docId], in
  /// descending order of [Document.tF] for [term].
  List<Document> toRankedSet(Term term) {
    final hashedSet = <DocId, Document>{};
    // turn into a set unique for docId.
    for (final document in this) {
      hashedSet[document.docId] = document;
    }
    final rankedSet = hashedSet.values.toList();
    rankedSet.sort(((a, b) => b.tF(term).compareTo(a.tF(term))));
    return rankedSet;
  }
}
