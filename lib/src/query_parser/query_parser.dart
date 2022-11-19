// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// A utility class that parses free text queries.
///
/// Ensure that the [configuration] and [tokenFilter] match the [TextAnalyzer]
/// used to construct the index on the target collection that will be searched.
///
/// The [parseQuery] method parses a phrase to a collection of [QueryTerm]s
/// that includes:
/// - all the original words in the phrase, except query modifiers
///   ('AND', 'OR', '"', '-', 'NOT);
/// - derived versions of all words returned by the [configuration].termFilter,
///   including child words of exact phrases; and
/// - derived versions of all words always have the [QueryTermModifier.OR]
///   unless they are already marked [QueryTermModifier.NOT].
abstract class QueryParser {
  //

  /// The index that will be queried.
  InvertedIndex get index;

  /// Parses a search [phrase] to a [FreeTextQuery].
  /// - [queryAnalyzer] is the [TextAnalyzer] used to parse the query. Defaults
  ///   to [index.analyzer].
  /// - [nGramRange] is the length of the n-grams to extract from the [phrase].
  ///   If [nGramRange] is null, whole phrases will be extracted.
  Future<Iterable<QueryTerm>> parseQuery(String phrase,
      {NGramRange? nGramRange, TextAnalyzer? queryAnalyzer});

  /// Parses a JSON [document] to a [FreeTextQuery].
  /// - [documentZones] is a hashmap of the field names (keys) in the [document]
  ///   that will be parsed to query terms. The values in [documentZones] will
  ///   be used to weight terms from the different fields when ordering the
  ///   parsed terms.
  /// - [docAnalyzer] is the [TextAnalyzer] used to parse the query. Defaults
  ///   to [index.analyzer].
  ///
  /// The returned [FreeTextQuery.terms] will include:
  /// - all the original words in the [phrase], except query modifiers
  ///   ('AND', 'OR', '"', '-', 'NOT);
  /// - derived versions of all words returned by the [_termFilter], including
  ///   child words of exact phrases; and
  /// - derived versions of all words always have the [QueryTermModifier.OR]
  ///   unless they are already marked [QueryTermModifier.NOT].
  Future<Iterable<QueryTerm>> parseDocument(
      JSON document, ZoneWeightMap documentZones,
      {int limit = 10,
      TokenFilter? tokenFilter,
      int? termPositionThreshold,
      TextAnalyzer? docAnalyzer,
      NGramRange nGramRange});

  /// Instantiates a [QueryParser] instance associated with the [index].
  factory QueryParser(InvertedIndex index) => _QueryParserImpl(index);
}

class _QueryParserImpl extends QueryParserBase {
  //

  @override
  final InvertedIndex index;

  const _QueryParserImpl(this.index);
}

/// Abstract base class implementation of [QueryParser] with [nGramRange].
///
/// Provides an unnamed const default generative constructor for sub-classes.
abstract class QueryParserBase with QueryParserMixin {
  /// Unnamed const default generative constructor for sub-classes.
  const QueryParserBase();
}

/// Mixin class implements [QueryParser.parseQuery].
abstract class QueryParserMixin implements QueryParser {
  //

  // /// The length of phrases in the queried index.
  // NGramRange? get nGramRange;

  @override
  Future<Iterable<QueryTerm>> parseDocument(
      JSON document, ZoneWeightMap documentZones,
      {int limit = 10,
      TokenFilter? tokenFilter,
      TextAnalyzer? docAnalyzer,
      int? termPositionThreshold,
      NGramRange nGramRange = const NGramRange(1, 3)}) async {
    // - turn the document into a secondary index.
    final docIndex = await _getDocumentIndex(document, documentZones,
        tokenFilter, docAnalyzer ?? index.analyzer, nGramRange);
    // - get the postings from the secondary index
    // final postings = docIndex.postings;
    //// - retrieve the dFtMap for the unique terms from the index
    final dFtMap = await index.getDictionary(docIndex.postings.keys.toSet());
// limit the postings to terms that exist in the corpus

    final postingsMap = _filteredPostingsMap(
        await index.getPostings(dFtMap.keys), termPositionThreshold);
    dFtMap.removeWhere((key, value) => !postingsMap.keys.contains(key));
    docIndex.dictionary.removeWhere((key, value) => !dFtMap.keys.contains(key));
    docIndex.keywordPostings
        .removeWhere((key, value) => !dFtMap.keys.contains(key));
    docIndex.postings.removeWhere((key, value) => !dFtMap.keys.contains(key));
    // - get the weighted document term freqeuncies from the postings
    final weightedDtf =
        InvertedIndex.docTermFrequencies(docIndex.postings, documentZones);
    // - retrieve the corpus size from the index
    final n = docIndex.postings.length;
    // - get the inverse term document frequencies for the terms
    final idfMap = dFtMap.idFtMap(n);
    // - get a tf-idft map for the weighted document term frequencies
    final tfIdftMap = dFtMap.tfIdfMap(weightedDtf, n);
    // - assign modifiers to terms on basis of weighted tf-idf
    return _docToQueryTerms(docIndex, idfMap, tfIdftMap);
  }

  PostingsMap _filteredPostingsMap(
      PostingsMap postingsMap, int? termPositionThreshold) {
    if (termPositionThreshold == null) {
      return postingsMap;
    }
    final PostingsMap retVal = {};
    for (final e in postingsMap.entries) {
      // final term = e.key;
      var highestPosition = termPositionThreshold + 1;
      for (final d in e.value.values) {
        for (final z in d.values) {
          final min = z.isEmpty ? highestPosition : z.first;
          highestPosition = min < highestPosition ? min : highestPosition;
        }
      }
      if (highestPosition <= termPositionThreshold) {
        retVal.addEntries([e]);
      }
    }
    return retVal;
  }

  Set<QueryTerm> _docToQueryTerms(InMemoryIndex index,
      Map<String, double> idfMap, Map<String, double> tfIdftMap) {
    final queryTerms = <QueryTerm>{};
    final modifierMap = _modifierMap(tfIdftMap, index);
    var termPosition = 0;
    final entries = tfIdftMap.entries
        .where((e) => modifierMap.keys.contains(e.key))
        .toList()
      ..sort(((a, b) => b.value.compareTo(a.value)));
    for (final e in entries) {
      final term = e.key;
      final modifier = modifierMap[term];
      if (modifier != null) {
        queryTerms.add(QueryTerm(term, modifier, termPosition,
            RegExp(r'\s+').allMatches(term).length + 1));
      }
      termPosition++;
    }
    return queryTerms;
  }

  Map<String, QueryTermModifier> _modifierMap(
      Map<String, double> tfIdftMap, InMemoryIndex index) {
    if (tfIdftMap.isEmpty) {
      return {};
    }
    final Map<String, double> kwWeightedTfIdfMap = {};
    for (final e in tfIdftMap.entries) {
      final kwPostings = index.keywordPostings[e.key];
      final docScore = kwPostings?.values.first ?? 0.0;
      kwWeightedTfIdfMap[e.key] = e.value * docScore;
    }
    final max = (kwWeightedTfIdfMap.values.toList()
          ..sort(((a, b) => b.compareTo(a))))
        .first;
    final retVal = kwWeightedTfIdfMap.map((k, v) {
      final normalized = v / max;
      final value = normalized > 0.9
          ? QueryTermModifier.EXACT
          : normalized > 0.5
              ? QueryTermModifier.IMPORTANT
              : normalized > 0.3
                  ? QueryTermModifier.AND
                  : QueryTermModifier.NOT;
      return MapEntry(k, value);
    });
    retVal.removeWhere((key, value) => value == QueryTermModifier.NOT);
    return retVal;
  }

  /// Turn the document into a mini index.
  Future<InMemoryIndex> _getDocumentIndex(
      JSON document,
      ZoneWeightMap documentZones,
      TokenFilter? tokenFilter,
      TextAnalyzer analyzer,
      NGramRange nGramRange) async {
    final docIndex = InMemoryIndex(
        zones: documentZones,
        analyzer: analyzer,
        collectionSize: 1,
        k: index.k,
        nGramRange: nGramRange);
    await docIndex.indexJson('docId', document, tokenFilter: tokenFilter);
    return docIndex;
  }

  @override
  Future<Iterable<QueryTerm>> parseQuery(String phrase,
      {NGramRange? nGramRange, TextAnalyzer? queryAnalyzer}) async {
    // initialize the queryTerms, front-load it with all the exact-matches
    final queryTerms =
        await _exactMatchPhrases(phrase, queryAnalyzer ?? index.analyzer);
    // add all the query terms with their modifiers
    queryTerms.addAll(await _toQueryTerms(phrase, queryTerms.length, nGramRange,
        queryAnalyzer ?? index.analyzer));
    queryTerms.unique();
    return queryTerms;
  }

  /// Returns all the terms or phrases in double quotes as [QueryTerm] instances
  /// with the [QueryTermModifier.EXACT].  These phrases are also given
  /// a term position of 0 to give them the highest weighting in scoring.
  Future<List<QueryTerm>> _exactMatchPhrases(
      String phrase, TextAnalyzer analyzer) async {
    // - initialize the return value;
    final retVal = <QueryTerm>[];
    // - inditialize a term counter

    final notExactTerms =
        RegExp(_rInDoubleQuotesNotNOT).allMatches(phrase).map((e) {
      final match = e.group(0);

      if (match != null) {
        phrase = phrase.replaceAll(match, '');
        return match
            .replaceAll(RegExp(r'\-"|"'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }
    });
    for (final e in notExactTerms) {
      if (e != null && e.trim().isNotEmpty) {
        final n = e.n;
        final terms =
            (await analyzer.tokenizer(e, nGramRange: NGramRange(n, n))).terms;
        retVal.add(
            QueryTerm(terms.join(' '), QueryTermModifier.NOT, 0, terms.length));
      }
    }
    final exactTerms = RegExp(_rInDoubleQuotes).allMatches(phrase).map((e) =>
        e.group(0)?.replaceAll('"', '').replaceAll(RegExp(r'\s+'), ' ').trim());
    for (final e in exactTerms) {
      if (e != null && e.trim().isNotEmpty) {
        final n = e.n;
        final terms =
            (await analyzer.tokenizer(e, nGramRange: NGramRange(n, n))).terms;
        retVal.add(QueryTerm(
            terms.join(' '), QueryTermModifier.EXACT, 0, terms.length));
        // retVal.addAll(terms.map(
        //     (e) => QueryTerm(e, QueryTermModifier.EXACT, 0, terms.length)));
      }
    }
    return retVal;
  }

  /// Parses a search [phrase] to a collection of [QueryTerm]s.
  ///
  /// The returned collection will include:
  /// - all the original words in the [phrase], except query modifiers
  ///   ('AND', 'OR', '"', '-', 'NOT);
  /// - derived versions of all words returned by the [_termFilter], including
  ///   child words of exact phrases; and
  /// - derived versions of all words always have the [QueryTermModifier.OR]
  ///   unless they are already marked [QueryTermModifier.NOT].
  Future<List<QueryTerm>> _toQueryTerms(String phrase, int startAt,
      NGramRange? nGramRange, TextAnalyzer analyzer) async {
    //
    phrase = phrase
        // remove the phrases in double quotes
        .replaceAll(RegExp('$_rInDoubleQuotesNotNOT|$_rInDoubleQuotes'), '')
        // replace multiple spaces with single spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        // trim whitespace from start and end
        .trim();
    if (phrase.isEmpty) {
      return [];
    }
    final retVal = <QueryTerm>[];
    // - replace the modifiers with tokens;
    phrase = phrase.replaceModifiers();
    // - split the phrase;
    final terms = index.analyzer.termSplitter(phrase);
    if (!terms.containsModifiers()) {
      return (await analyzer.tokenizer(phrase,
              nGramRange: nGramRange ?? NGramRange(1, terms.length)))
          .map((e) =>
              QueryTerm(e.term, QueryTermModifier.AND, e.termPosition, e.n))
          .toList();
    }

    // - inditialize a term counter
    var i = startAt;
    final List<MapEntry<String, QueryTermModifier>> termToModifierList =
        terms.toTermModifiersList();
    final List<MapEntry<Set<String>, QueryTermModifier>> andNotTermSetsList =
        await _andNotTermSetsList(termToModifierList, analyzer);
    final nGramTerms = <Set<String>>[];
    for (final e in andNotTermSetsList) {
      final modifier = e.value;
      final termSet = e.key;
      if (termSet.isNotEmpty) {
        if (modifier == QueryTermModifier.NOT) {
          retVal.addAll(termSet.map((e) => QueryTerm(e, modifier, i, 1)));
        } else {
          if (nGramRange != null) {
            nGramTerms.add(termSet);
            if (nGramTerms.length > nGramRange.max) {
              nGramTerms.removeAt(0);
            }
            retVal.addAll(_getNGrams(nGramTerms, nGramRange, i, modifier));
          }
        }
      }
      i++;
    }
    return retVal;
  }

  Iterable<QueryTerm> _getNGrams(List<Set<String>> nGramTerms,
      NGramRange nGramRange, int termPosition, QueryTermModifier modifier) {
    if (nGramTerms.length > nGramRange.max) {
      nGramTerms = nGramTerms.sublist(nGramTerms.length - nGramRange.max);
    }
    if (nGramTerms.length < nGramRange.min) {
      return <QueryTerm>[];
    }
    final nGrams = <List<String>>[];
    var n = 0;

    for (var i = nGramTerms.length - 1; i >= 0; i--) {
      final param = <List<String>>[];
      param.addAll(nGrams
          .where((element) => element.length == n)
          .map((e) => List<String>.from(e)));
      final newNGrams = _prefixWordsTo(param, nGramTerms[i]);
      nGrams.addAll(newNGrams);
      n++;
    }
    final tokenGrams = nGrams.where((element) =>
        element.length >= nGramRange.min && element.length <= nGramRange.max);

    final tokens = <QueryTerm>[];
    for (final e in tokenGrams) {
      final n = e.length;
      final term = e.join(' ');
      tokens.add(QueryTerm(term, modifier, termPosition - n, n));
    }
    return tokens;
  }

  static Iterable<List<String>> _prefixWordsTo(
      Iterable<List<String>> nkGrams, Iterable<String> words) {
    final nGrams = List<List<String>>.from(nkGrams);
    words = words.map((e) => e.trim()).where((element) => element.isNotEmpty);
    final retVal = <List<String>>[];
    if (nGrams.isEmpty) {
      retVal.addAll(words.map((e) => [e]));
    }
    for (final word in words) {
      for (final nGram in nGrams) {
        final newNGram = List<String>.from(nGram);
        newNGram.insert(0, word);
        retVal.add(newNGram);
      }
    }
    return retVal;
  }

  Future<List<MapEntry<Set<String>, QueryTermModifier>>> _andNotTermSetsList(
      List<MapEntry<String, QueryTermModifier>> termToModifierList,
      TextAnalyzer analyzer) async {
    final List<MapEntry<Set<String>, QueryTermModifier>> retVal = [];
    final orSet = <String>{};
    var i = 0;
    var effectiveModifier = QueryTermModifier.AND;
    await Future.forEach(termToModifierList,
        (MapEntry<String, QueryTermModifier> e) async {
      final term = e.key;
      final modifier = e.value;
      effectiveModifier =
          modifier == QueryTermModifier.OR ? effectiveModifier : modifier;
      final nextModifier = i < termToModifierList.length - 1
          ? termToModifierList[i + 1].value
          : null;
      final versions = await _tokenize(term, analyzer);
      orSet.addAll(versions);
      if (modifier != QueryTermModifier.OR ||
          nextModifier != QueryTermModifier.OR) {
        retVal.add(MapEntry(Set<String>.from(orSet), effectiveModifier));
        orSet.clear();
      }
      i++;
    });
    return retVal;
  }

  /// Uses the analyzer to get the tokenized version(s) of [term].
  Future<Set<String>> _tokenize(String term, TextAnalyzer analyzer) async {
    final retVal = <String>{};
    retVal.addAll(
        (await analyzer.tokenizer(term, nGramRange: NGramRange(1, 1))).terms);
    return retVal;
  }

  /// Matches all phrases included in quotes.
  static const _rInDoubleQuotes = r'"\w[^"]+\w"';

  /// Matches all phrases included in quotes.
  static const _rInDoubleQuotesNotNOT = r'\-"\w[^"]+\w"';

  /// Matches '-' where preceded by white-space or the start of the string AND
  /// followed by a double quote or word character.
  static const _rNot = r'(?<=^|\s)-(?="|\w)';

  /// Matches '+' where preceded by white-space or the start of the string AND
  /// followed by a double quote or word character.
  static const _rImportant = r'(?<=^|\s)\+(?="|\w)';
}

extension _StringExtension on String {
  //
  int get n => RegExp(r'\s+').allMatches(this).length + 1;
}

extension _TermsListExtension on List<String> {
  //

  bool containsModifiers() {
    return toSet().intersection(_kModifierNames).isNotEmpty;
  }

  List<MapEntry<String, QueryTermModifier>> toTermModifiersList() {
    final List<MapEntry<String, QueryTermModifier>> retVal = [];
    // - inditialize a term counter
    final terms = List<String>.from(this);
    var termIndex = 0;
    for (final term in terms) {
      // get the previous term if this is not the first term
      final previous = terms.previous(termIndex);
      // get the next term if this is not the last term
      final next = terms.next(termIndex);
      // check if the current term is a modifier or a search term
      if (!term.isModifier) {
        // ok, not a modifier, so let's turn it into a QueryTerm
        final modifier = term.modifier(previous, next);
        retVal.add(MapEntry(term, modifier));
      }
      // increment the termIndex
      termIndex++;
    }
    return retVal;
  }

  String? previous(int index) => index == 0 ? null : this[index - 1];

  String? next(int index) => index < length - 1 ? this[index + 1] : null;
}

const _kModifierNames = {
  'AND',
  'OR',
  'NOT',
  'IMPORTANT',
  'EXACTSTART',
  'EXACTEND'
};

extension _QueryModifierReplacementExtension on String {
  //

  /// Returns true if the trimmed String is equal to any of:
  /// - ('AND', 'OR', 'NOT', 'EXACTSTART', 'EXACTEND').
  bool get isModifier => _kModifierNames.contains(trim());

  QueryTermModifier modifier(String? precedingTerm, String? followingTerm) {
    switch (precedingTerm) {
      case 'OR':
        return QueryTermModifier.OR;
      case 'NOT':
        return QueryTermModifier.NOT;
      case 'IMPORTANT':
        return QueryTermModifier.IMPORTANT;
      default:
        return followingTerm == 'OR'
            ? QueryTermModifier.OR
            : QueryTermModifier.AND;
    }
  }

  /// Replaces all the [QueryTermModifier] instances with tokens;
  String replaceModifiers() => not().important().exact();

  /// Replaces '-' at the start of a term or phrase with 'NOT '.
  String not() => replaceAll(RegExp(QueryParserMixin._rNot), 'NOT ');

  /// Replaces '-' at the start of a term or phrase with 'NOT '.
  String important() =>
      replaceAll(RegExp(QueryParserMixin._rImportant), 'IMPORTANT ');

  /// Matches words or phrases enclosed with double quotes and removes the
  /// quotes.
  String exact() =>
      replaceAllMapped(RegExp(QueryParserMixin._rInDoubleQuotes), (match) {
        final phrase = match.group(0) ?? '';
        if (phrase.length > 2 &&
            phrase.startsWith(r'"') &&
            phrase.endsWith(r'"')) {
          return phrase.substring(1, phrase.length - 1);
          // return 'EXACTSTART $phrase EXACTEND';
        }
        return phrase;
      });
}
