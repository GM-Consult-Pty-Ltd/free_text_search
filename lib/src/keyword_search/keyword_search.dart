// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';
import 'package:rxdart/rxdart.dart';

/// A utility class that returns query results from [index] for terms that
/// have a high starts-with similarity with a phrase.
///
/// Call the [startsWith] method to return the query results.
abstract class KeywordSearch {
  //

  /// Factory constructor hydrates a [KeywordSearch] instance on the [index].
  factory KeywordSearch(InvertedIndex index) => _StartsWithSearchImpl(index);

  /// The [InvertedIndex] that contains the indexes for the collection.
  ///
  /// The [index] is an [InvertedIndex] that contains the indexes for the
  /// collection.
  InvertedIndex get index;

  /// Searches the index k-grams for terms that have a high starts-with
  /// similarity with [startsWith]. Queries the keywords index for these
  /// terms and returns the [limit] document ids with the highest keyword
  /// scores.
  Future<List<MapEntry<String, double>>> startsWith(String startsWith,
      [int limit = 20]);

  /// Returns a stream of suggestions (document ids) for the input stream.
  /// Only returns suggestions that have a high starts-with similarity with the
  /// last element in [startsWith].
  ///
  /// The returned list is ordered in descending order of keyword score
  Stream<List<MapEntry<String, double>>> suggestionsStream(
      Stream<String> startsWith,
      [int limit = 20]);

  /// Extracts keywords from the JSON [document] and searches the keyword
  /// [index] for matches for the highest scoring keywords in [zones], returning
  /// the document ids with the [limit] highest keyword scores.
  ///
  /// If [zones] is not null the search results are weighted in accordance with
  /// the weights in [zones].
  ///
  ///  The default [limit] is 20.
  Future<List<MapEntry<String, double>>> documentMatches(JSON document,
      {int limit = 20, ZoneWeightMap? zones});
}

/// Abstract mixin class that implements [KeywordSearch.startsWith].
abstract class StartsWithSearchMixin implements KeywordSearch {
//

  @override
  Future<List<MapEntry<String, double>>> documentMatches(JSON document,
      {int limit = 20, ZoneWeightMap? zones}) async {
    document = zones == null ? {'data': document.toSourceText()} : document;
    zones = zones ?? {'data': 1.0};
    final docKeywords = _docKeywords(zones, document);
    final Map<String, double> retVal = await _keywordDocs(docKeywords);
    final entries = retVal.entries.toList();
    entries.sort(((a, b) => b.value.compareTo(a.value)));
    return entries.length > limit ? entries.sublist(0, limit) : entries;
  }

  /// Retrieves keyword postings for all the keys in [keywords], then iterates
  /// through the keywords, aggregating the cosine similarity for each document
  /// by calculating the keyword cosine similarity for each document.
  Future<Map<String, double>> _keywordDocs(Map<String, double> keywords) async {
    final Map<String, double> keywordDocs = {};
    final keywordIndex = await index.getKeywordPostings(keywords.keys);
    final documentKeyWordVectors = _documentKeywordVectors(keywordIndex);
    for (final e in documentKeyWordVectors.entries) {
      final docId = e.key;
      final similarity = keywords.cosineSimilarity(e.value);
      keywordDocs[docId] = similarity;
    }
    return keywordDocs;
  }

  Map<String, Map<String, double>> _documentKeywordVectors(
      Map<String, Map<String, double>> keywordIndex) {
    final Map<String, Map<String, double>> retVal = {};
    for (final eKw in keywordIndex.entries) {
      final keyword = eKw.key;
      for (final e in eKw.value.entries) {
        final docId = e.key;
        final score = e.value;
        final docEntry = (retVal[docId] ?? <String, double>{});
        docEntry[keyword] = score;
        retVal[docId] = docEntry;
      }
    }
    return retVal;
  }

  /// Extracts the keywords from [document] and calculates a weighted
  /// keyword score for each keyword, using the weights in [zones].
  ///
  /// Returns a hashmap of keyword to score for the [document].
  Map<String, double> _docKeywords(Map<Zone, double> zones, JSON document) {
    final Map<String, double> docKeywords = {};
    for (final zone in zones.entries) {
      final fieldName = zone.key;
      final wF = zone.value;
      final text = document[fieldName]?.toString().trim();
      if (text != null && text.isNotEmpty && wF != 0.0) {
        final keywords =
            index.keywordExtractor(text, nGramRange: index.nGramRange);
        final graph = TermCoOccurrenceGraph(keywords);
        final zoneKeywordsMap = graph.keywordScores;
        for (final e in zoneKeywordsMap.entries) {
          final keyword = e.key;
          docKeywords[keyword] = (docKeywords[keyword] ?? 0.0) + e.value * wF;
        }
      }
    }
    final entries = docKeywords.entries.toList();
    entries.sort(((a, b) => b.value.compareTo(a.value)));
    return docKeywords;
  }

  @override
  Stream<List<MapEntry<String, double>>> suggestionsStream(
      Stream<String> startsWith,
      [int limit = 20]) {
    final retValMap = <String, double>{};
    final Map<String, Set<String>> kGramMap = {};
    final Map<String, Map<String, double>> keywordPostings = {};
    String startGram = '';
    final controller = BehaviorSubject<List<MapEntry<String, double>>>();
    startsWith.listen((event) async {
      retValMap.clear();
      event = event.trim();
      if (event.isNotEmpty) {
        final firstGram = event.kGrams(index.k).first;
        if (firstGram != startGram) {
          startGram = firstGram;
          kGramMap.clear();
          kGramMap.addAll(await index.getKGramIndex([startGram]));
        }

        final terms = event
            .startsWithSimilarities(kGramMap.terms)
            .map((e) => e.term)
            .where((element) => element.startsWith(event))
            .toList();
        if (terms.isEmpty) {
          controller.sink.add([]);
        }
        var i = 0;
        await Future.doWhile(() async {
          final t = terms[i];
          if (keywordPostings[t] == null) {
            keywordPostings.addAll(await index.getKeywordPostings([t]));
          }
          if (keywordPostings.isNotEmpty) {
            final value = keywordPostings[t] ?? {};
            for (final e in value.entries) {
              final existing = retValMap[e.key] ?? e.value;
              retValMap[e.key] = e.value > existing ? e.value : existing;
            }
          }
          i++;
          return retValMap.length < limit && i < terms.length;
        });
        if (retValMap.isEmpty) {
          controller.sink.add([]);
        }
        var entries = retValMap.entries.toList()
          ..sort(((a, b) => b.value.compareTo(a.value)));
        entries = entries.length > limit ? entries.sublist(0, limit) : entries;
        controller.sink.add(entries);
      } else {
        controller.sink.add([]);
      }
    });

    return controller.stream;
  }

  @override
  Future<List<MapEntry<String, double>>> startsWith(String startsWith,
      [int limit = 20]) async {
    final retVal = <String, double>{};
    startsWith = startsWith.trim();
    if (startsWith.isEmpty) return [];
    final kGrams = [startsWith.kGrams(index.k).first];
    final kGramMap = await index.getKGramIndex(kGrams);
    final terms = startsWith
        .startsWithSimilarities(kGramMap.terms)
        .map((e) => e.term)
        .where((element) => element.startsWith(startsWith))
        .toList();
    if (terms.isEmpty) {
      return [];
    }
    var i = 0;
    await Future.doWhile(() async {
      final t = terms[i];
      final keywordPostings = await index.getKeywordPostings([t]);
      if (keywordPostings[t] == null) {
        keywordPostings.addAll(await index.getKeywordPostings([t]));
      }
      if (keywordPostings.isNotEmpty) {
        final value = keywordPostings[t] ?? {};
        for (final e in value.entries) {
          final existing = retVal[e.key] ?? e.value;
          retVal[e.key] = e.value > existing ? e.value : existing;
        }
      }
      i++;
      return retVal.length < limit && i < terms.length;
    });

    if (retVal.isEmpty) {
      return [];
    }
    var entries = retVal.entries.toList()
      ..sort(((a, b) => b.value.compareTo(a.value)));
    entries = entries.length > limit ? entries.sublist(0, limit) : entries;
    return entries;
  }
}

/// Abstract implementation base class that mixes in [StartsWithSearchMixin].
///
/// Provides a const default generative constructor for sub-classes.
abstract class StartsWithSearchBase with StartsWithSearchMixin {
  //

  /// A const default generative constructor for sub-classes.
  const StartsWithSearchBase();
}

class _StartsWithSearchImpl extends StartsWithSearchBase {
  @override
  final InvertedIndex index;

  const _StartsWithSearchImpl(this.index);
}
