// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

part of 'search_result.dart';

/// Private extension methods on [PostingsMap].
extension _IndexSearchPostingsMapExtension on PostingsMap {
//

  /// Returns a hashmap of term to zone postings for docId from the
  /// postings hashmap.
  Map<String, Map<String, List<int>>> docTermPostings(String docId) {
    final zonePostings = entries
        .where((element) => element.value.keys.contains(docId))
        .map((e) => MapEntry(e.key, e.value[docId] ?? {}));
    final Map<String, Map<String, List<int>>> retVal = {}
      ..addEntries(zonePostings);
    return retVal;
  }
}

/// Private extension methods on [KeywordPostingsMap].
extension _IndexSearchKeywordPostingsExtension on KeywordPostingsMap {
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
extension _IndexSearchDftMapExtension on DftMap {
//

  /// Returns the inverse document frequency of the [term] for a corpus of size
  /// [n].
  double idFt(String term, int n) => log(n / getFrequency(term));

  /// Returns a hashmap of term to Tf-idf weight for a document.
  Map<String, double> tfIdfMap(
          Map<String, double> weightedTermFrequencies, int n) =>
      weightedTermFrequencies
          .map((term, tF) => MapEntry(term, tF * idFt(term, n)));
}

/// Private extension methods on `Map<String, ZonePostingsMap>`.
extension _IndexSearchTermPostingsExtension
    on Map<String, ZonePostingsMap> {
//

  // /// Aggregates the number of postings of each term and maps the total to
  // /// the term.
  // Map<String, int> docTermFrequencies(Map<String, int>? zoneWeights) {
  //   final Map<String, int> retVal = {};
  //   for (final e in entries) {
  //     final term = e.key;
  //     var tF = 0;
  //     for (final z in e.value.entries) {
  //       final weight = zoneWeights == null ? 1 : zoneWeights[z.key] ?? 0;
  //       tF += z.value.length;
  //     }
  //     retVal[term] = tF;
  //   }
  //   return retVal;
  // }

  /// Aggregates the number of postings of each term and maps the total to
  /// the term.
  Map<Term, Map<Term, int>> termZoneFrequencies(FreeTextQuery query) {
    final Map<Term, Map<Term, int>> retVal = {};
    final zoneWeights = query.weightingStrategy.zoneWeights;
    for (final e in entries) {
      final term = e.key;
      final tF = <String, int>{};
      final zoneEntries = zoneWeights == null
          ? e.value.entries
          : e.value.entries
              .where((element) => zoneWeights.keys.contains(element.key));
      for (final z in zoneEntries) {
        tF[z.key] = z.value.length;
      }
      retVal[term] = tF;
    }
    return retVal;
  }
}

extension _TermZoneFrequencyExtension on Map<Term, Map<Term, int>> {
  /// Aggregates the term frequencies from all zones to a term frequency for
  /// the document.
  Map<Term, int> termFrequencies(FreeTextQuery query) {
    final Map<Term, int> retVal = {};
    final zoneWeights = query.weightingStrategy.zoneWeights;
    for (final e in entries) {
      final term = e.key;
      var f = 0;
      final zoneEntries = zoneWeights == null
          ? e.value.entries
          : e.value.entries
              .where((element) => zoneWeights.keys.contains(element.key));
      for (final z in zoneEntries) {
        f += z.value;
      }
      retVal[term] = f;
    }
    return retVal;
  }

  /// Returns a map of term to weighted term frequency from the term zone
  /// frequency map.
  Map<Term, double> weightedTermFrequencies(FreeTextQuery query) {
    final zoneWeights = query.weightingStrategy.zoneWeights;
    final Map<Term, double> retVal = {};
    final qtMap = <String, QueryTerm>{}
      ..addEntries(query.queryTerms.map((e) => MapEntry(e.term, e)));
    for (final e in entries) {
      final term = e.key;
      final qt = qtMap[term];
      if (qt != null) {
        final wM = query.weightingStrategy.getWeight(qt);
        var f = 0.0;
        final zoneEntries = zoneWeights == null
            ? e.value.entries
            : e.value.entries
                .where((element) => zoneWeights.keys.contains(element.key));
        for (final z in zoneEntries) {
          final wZ = zoneWeights == null ? 1 : zoneWeights[z.key] ?? 0;
          f += z.value * wM * wZ;
        }
        retVal[term] = f;
      }
    }
    return retVal;
  }
}

/// Extension on vector map.
extension _TfIdfMapExtensions on Map<String, double> {
  /// Computes a score from the tTfIdfMap and the [weighting].
  double computeTfIdfScore(FreeTextQuery query) {
    var retVal = 0.0;
    final qtMap = <String, QueryTerm>{}
      ..addEntries(query.queryTerms.map((e) => MapEntry(e.term, e)));
    for (final e in entries) {
      final qt = qtMap[e.key];
      final tfIdf = e.value;
      if (qt != null) {
        final wt = query.weightingStrategy.getWeight(qt);
        retVal += wt * tfIdf;
      }
    }

    return retVal;
  }
}
