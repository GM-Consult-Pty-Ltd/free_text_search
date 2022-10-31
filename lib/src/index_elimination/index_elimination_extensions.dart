// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

part of 'search_result.dart';

/// Private extension methods on [PostingsMap].
extension _IndexEliminationPostingsMapExtension on PostingsMap {
//

  /// Returns a hashmap of term to zone postings for docId from the
  /// postings hashmap.
  Map<String, Map<String, List<int>>> docTermPostings(String docId) {
    final zonePostings = entries
        .where((element) => element.value.keys.contains(docId))
        .map((e) => MapEntry(e.key, e.value[docId] ?? {}));
    final Map<String, Map<String, List<int>>> retVal = {};
    retVal.addEntries(zonePostings);
    return retVal;
  }
}

/// Private extension methods on [KeywordPostingsMap].
extension _IndexEliminationKeywordPostingsExtension on KeywordPostingsMap {
//

  /// Returns a hashmap of term to keyword score for keywords in the document.
  Map<String, double> docKeywordScores(String docId) {
    final newEntries = entries
        .where((e) => e.value.keys.contains(docId))
        .map((e) => MapEntry(e.key, (e.value[docId] ?? 0)));
    final retVal = <String, double>{}..addEntries(newEntries);
    return retVal;
  }
}

/// Private extension methods on [DftMap].
extension _IndexEliminationDftMapExtension on DftMap {
//

  /// Returns the inverse document frequency of the [term] for a corpus of size
  /// [n].
  double idFt(String term, int n) => log(n / getFrequency(term));

  /// Returns a hashmap of term to Tf-idf weight for a document.
  Map<String, double> tfIdfMap(Map<String, int> docTermFrequencies, int n) =>
      docTermFrequencies.map((term, tF) => MapEntry(term, tF * idFt(term, n)));
}

/// Private extension methods on `Map<String, ZonePostingsMap>`.
extension _IndexEliminationTermPostingsExtension
    on Map<String, ZonePostingsMap> {
//

  /// Aggregates the number of postings of each term and maps the total to
  /// the term.
  Map<String, int> docTermFrequencies() {
    final Map<String, int> retVal = {};
    for (final e in entries) {
      final term = e.key;
      var tF = 0;
      for (final z in e.value.values) {
        tF += z.length;
      }
      retVal[term] = tF;
    }
    return retVal;
  }
}
