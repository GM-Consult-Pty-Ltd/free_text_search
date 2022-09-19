// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// A hashmap of [Term] to the list of [Document]s that contain that
/// term. The ordered set of [Document]s is in descending order of term
/// frequency ([Ft]) and each document ([Document.docId]) can only occur once.
typedef ChampionList = Map<Term, List<Document>>;

/// An entry in a [ChampionList].
typedef ChampionListEntry = MapEntry<Term, List<Document>>;

/// Extension methods on a [Iterable] of [Document]s.
extension DocumentListExtension on Iterable<Document> {
//

  /// Returns ordered set of [Document]s, unique for [Document.docId], in
  /// descending order of [Document.tF] for [term].
  List<Document> toRankedSet(Term term, [int? r]) {
    final hashedSet = <DocId, Document>{};
    // turn into a set unique for docId.
    for (final document in this) {
      hashedSet[document.docId] = document;
    }
    final rankedSet = hashedSet.values.toList();
    // sort by term frequency
    rankedSet.sort(((a, b) => b.tFt(term).compareTo(a.tFt(term))));
    // sort by termPairWeight
    rankedSet.sort(((a, b) => b.termPairWeight.compareTo(a.termPairWeight)));
    if (r == null) return rankedSet;
    return r > rankedSet.length ? rankedSet.sublist(0, r) : rankedSet;
  }
}
