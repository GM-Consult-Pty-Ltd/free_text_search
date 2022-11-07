// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';
import 'package:rxdart/rxdart.dart';

/// A utility class that returns query results from [index] for terms that
/// have a high starts-with similarity with a phrase.
///
/// Call the [search] method to return the query results.
abstract class StartsWithSearch {
  //

  /// Factory constructor hydrates a [StartsWithSearch] instance on the [index].
  factory StartsWithSearch(InvertedIndex index) => _StartsWithSearchImpl(index);

  /// The [InvertedIndex] that contains the indexes for the collection.
  ///
  /// The [index] is an [InvertedIndex] that contains the indexes for the
  /// collection.
  InvertedIndex get index;

  /// Searches the index k-grams for terms that have a high starts-with
  /// similarity with [startsWith]. Queries the keywords index for these
  /// terms and returns the [limit] document ids with the highest keyword
  /// scores.
  Future<List<MapEntry<String, double>>> search(String startsWith,
      [int limit = 20]);

  /// Returns a stream of suggestions (document ids) for the input stream.
  /// Only returns suggestions that have a high starts-with similarity with the
  /// last element in [startsWith].
  ///
  /// The returned list is ordered in descending order of keyword score
  Stream<List<MapEntry<String, double>>> suggestionsStream(
      Stream<String> startsWith,
      [int limit = 20]);
}

/// Abstract mixin class that implements [StartsWithSearch.search].
abstract class StartsWithSearchMixin implements StartsWithSearch {
//

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
      event = event.toLowerCase().trim();
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
  Future<List<MapEntry<String, double>>> search(String startsWith,
      [int limit = 20]) async {
    final retVal = <String, double>{};
    startsWith = startsWith.toLowerCase().trim();
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
