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

  /// Parses a search [phrase] to a [FreeTextQuery].
  ///
  /// The returned [FreeTextQuery.terms] will include:
  /// - all the original words in the [phrase], except query modifiers
  ///   ('AND', 'OR', '"', '-', 'NOT);
  /// - derived versions of all words returned by the [_termFilter], including
  ///   child words of exact phrases; and
  /// - derived versions of all words always have the [QueryTermModifier.OR]
  ///   unless they are already marked [QueryTermModifier.NOT].
  Future<FreeTextQuery> parseQuery(String phrase);

  /// Instantiates a [QueryParser] instance with a [tokenizer].
  factory QueryParser(
          {required TextTokenizer tokenizer,
          NGramRange nGramRange = const NGramRange(1, 1)}) =>
      _QueryParserImpl(tokenizer, nGramRange);

  /// Instantiates a [QueryParser] instance associated with the [index].
  factory QueryParser.index(InvertedIndex index) =>
      _QueryParserImpl(index.tokenizer, index.nGramRange);
}

class _QueryParserImpl extends QueryParserBase {
  //

  @override
  final TextTokenizer tokenizer;

  @override
  final NGramRange nGramRange;

  const _QueryParserImpl(this.tokenizer, this.nGramRange);
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

  /// A [TextAnalyzer] used to tokenize the query phrase. The tokenizer should
  /// be the same as that used to create the index being queried.
  TextTokenizer get tokenizer;

  /// The length of phrases in the queried index.
  NGramRange get nGramRange;

  /// Shortcut to tokenizer.termSplitter
  TermSplitter get _termSplitter => tokenizer.analyzer.termSplitter;

  @override
  Future<FreeTextQuery> parseQuery(String phrase) async {
    // initialize the queryTerms, front-load it with all the exact-matches
    final queryTerms = await _exactMatchPhrases(phrase);
    // add all the query terms with their modifiers
    queryTerms.addAll(await _toQueryTerms(phrase, queryTerms.length));
    queryTerms.unique();
    final query = FreeTextQuery(phrase: phrase, queryTerms: queryTerms);
    return query;
  }

  /// Returns all the terms or phrases in double quotes as [QueryTerm] instances
  /// with the [QueryTermModifier.EXACT].  These phrases are also given
  /// a term position of 0 to give them the highest weighting in scoring.
  Future<List<QueryTerm>> _exactMatchPhrases(String phrase) async {
    // - initialize the return value;
    final retVal = <QueryTerm>[];
    // - inditialize a term counter
    final exactTerms = RegExp(_rInDoubleQuotes).allMatches(phrase).map((e) =>
        e.group(0)?.replaceAll('"', '').replaceAll(RegExp(r'\s+'), ' ').trim());
    for (final e in exactTerms) {
      if (e != null && e.trim().isNotEmpty) {
        final n = e.n;
        final terms =
            (await tokenizer.tokenize(e, nGramRange: NGramRange(n, n))).terms;
        terms.add(e);
        retVal.addAll(terms.map(
            (e) => QueryTerm(e, QueryTermModifier.EXACT, 0, terms.length)));
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
  Future<List<QueryTerm>> _toQueryTerms(String phrase, int startAt) async {
    //

    final retVal = await _exactMatchPhrases(phrase);
    // // - keep a record of the terms processed

    // - replace the modifiers with tokens;
    phrase = phrase.replaceModifiers();
    // - split the phrase;
    final terms = _termSplitter(phrase);
    if (!terms.containsModifiers()) {
      return (await tokenizer.tokenize(phrase))
          .map((e) =>
              QueryTerm(e.term, QueryTermModifier.AND, e.termPosition, e.n))
          .toList();
    }

    // - inditialize a term counter
    var i = startAt;
    // - initialize a placeholder for the search term, in case we need to
    // concatenate words that are part of an exact match phrase.
    final List<MapEntry<String, QueryTermModifier>> termToModifierList =
        terms.toTermModifiersList();
    final List<MapEntry<Set<String>, QueryTermModifier>> andNotTermSetsList =
        await _andNotTermSetsList(termToModifierList);
    final nGramTerms = <Set<String>>[];
    for (final e in andNotTermSetsList) {
      final modifier = e.value;
      final termSet = e.key;
      if (termSet.isNotEmpty) {
        if (modifier == QueryTermModifier.NOT) {
          retVal.addAll(termSet.map((e) => QueryTerm(e, modifier, i, 1)));
        } else {
          nGramTerms.add(termSet);
          if (nGramTerms.length > nGramRange.max) {
            nGramTerms.removeAt(0);
          }
          retVal.addAll(_getNGrams(nGramTerms, nGramRange, i, modifier));
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
      List<MapEntry<String, QueryTermModifier>> termToModifierList) async {
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
      final versions = await _tokenize(term);
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

  /// Uses the tokenizer to get the tokenized version(s) of [term].
  Future<Set<String>> _tokenize(String term) async {
    final retVal = <String>{};
    retVal.addAll(
        (await tokenizer.tokenize(term, nGramRange: NGramRange(1, 1))).terms);
    return retVal;
  }

  /// Matches all phrases included in quotes.
  static const _rInDoubleQuotes = r'"\w[^"]+\w"';

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

extension _TermsListExtension on List<Term> {
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

extension _QueryModifierReplacementExtension on Term {
  //

  /// Returns true if the trimmed String is equal to any of:
  /// - ('AND', 'OR', 'NOT', 'EXACTSTART', 'EXACTEND').
  bool get isModifier => _kModifierNames.contains(trim());

  QueryTermModifier modifier(Term? precedingTerm, Term? followingTerm) {
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
