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
  factory QueryParser(TextTokenizer tokenizer) => _QueryParserImpl(tokenizer);

  /// Instantiates a [QueryParser] instance associated with the [index].
  factory QueryParser.index(InvertedIndex index) =>
      _QueryParserImpl(index.tokenizer);
}

class _QueryParserImpl extends QueryParserBase {
  @override
  final TextTokenizer tokenizer;

  const _QueryParserImpl(this.tokenizer);
}

/// Abstract base class implementation of [QueryParser] with [QueryParserMixin].
///
/// Provides an unnamed const default generative constructor for sub-classes.
abstract class QueryParserBase with QueryParserMixin {
  /// Unnamed const default generative constructor for sub-classes.
  const QueryParserBase();
}

/// Mixin class implements [QueryParser.parseQuery].
abstract class QueryParserMixin implements QueryParser {
  //

  /// A TextAnalyzer used to tokenize the query phrase.
  TextTokenizer get tokenizer;

  /// Shortcut to tokenizer.termSplitter
  TermSplitter get _termSplitter => tokenizer.analyzer.termSplitter;

  @override
  Future<FreeTextQuery> parseQuery(String phrase) async {
    final queryTerms = await _parseToTerms(phrase);
    final query = FreeTextQuery(phrase: phrase, queryTerms: queryTerms);
    return query;
  }

  /// Returns all the terms or phrases in double quotes as QueryTerm instances
  /// with the [QueryTermModifier.EXACT].  These phrases are also given
  /// a term position of 0 to give them the highest weighting in scoring.
  Future<List<QueryTerm>> _exactMatchPhrases(String phrase) async {
    // - initialize the return value;
    final retVal = <QueryTerm>[];
    // - inditialize a term counter
    final exactTerms = RegExp(_rInDoubleQuotes)
        .allMatches(phrase)
        .map((e) => e.group(0)?.replaceAll('"', ''));
    for (final e in exactTerms) {
      if (e != null) {
        final qt = QueryTerm(e, QueryTermModifier.EXACT, 0);
        retVal.add(qt);
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
  Future<List<QueryTerm>> _parseToTerms(String phrase) async {
    //
    // - initialize the return value, front-load it with all the exact-matches
    final retVal = await _exactMatchPhrases(phrase);
    // - keep a record of the exactmatches
    final exactPhrases = retVal.terms;
    // - replace the modifiers with tokens;
    phrase = phrase.replaceModifiers();
    // - tokenize the phrase;
    final terms = _termSplitter(phrase);
    // - intitialize a term position counter
    var termPosition = 0;
    // - inditialize a term counter
    var termIndex = 0;
    // - initialize a placeholder for the search term, in case we need to
    // concatenate words that are part of an exact match phrase.
    var rawTermOrPhrase = '';
    var previousParsedTerm = '';
    await Future.forEach(terms, (String term) async {
      // get the previous term if this is not the first term
      final previous = terms.previous(termIndex);
      // get the next term if this is not the last term
      final next = terms.next(termIndex);
      // check if the current term is a modifier or a search term
      if (!term.isModifier) {
        // ok, not a modifier, so let's turn it into a QueryTerm
        //
        // if rawTermOrPhrase is not empty this is a second or later term in an
        //  exact match phrase
        final modifier = rawTermOrPhrase.isEmpty
            // infer the modifier for the term from the previous term, or
            ? term.modifier(previous, next)
            // if this is a term in an exact phrase, set it to EXACT
            : QueryTermModifier.AND;
        // concatenate rawTermOrPhrase and term, inserting a space if rawTermOrPhrase
        // already contains a word.
        rawTermOrPhrase =
            rawTermOrPhrase.isEmpty ? term : '$rawTermOrPhrase $term';
        // check modifier is not EXACT or else the next term is "EXACTEND":
        if (modifier != QueryTermModifier.EXACT || next == 'EXACTEND') {
          // if we're here it means we can add the term to the return value
          // because it is either:
          //  - NOT an exact match term, or
          //  - the last word in an exact match phrase
          //
          // let's initialize a collection to hold the exact term/phrase and any
          // child words of a phrase or a stemmed version of the term.
          var searchTerms = <String>[];

          // check if we are dealing with an exact term or phrase
          if (modifier == QueryTermModifier.EXACT) {
            // ok it's the end of an exact match phrase
            //
            // searchTerms = <String>[rawTermOrPhrase];
            previousParsedTerm = rawTermOrPhrase;
            // now split the phrase at whitespace into its component words
            final subterms = rawTermOrPhrase.split(RegExp(r'\s+'));
            // let's iterate through the subTerms and add them to searchTerms
            var previousSubTerm = '';
            for (var subTerm in subterms) {
              // first check the subTerm is not empty
              if (subTerm.isNotEmpty) {
                // not an empty subTerm, so let's tokenize it
                final filteredTerms = (await tokenizer.tokenize(subTerm)).terms;
                // now iterate through whatever we got back from the tokenizer
                for (final e in filteredTerms) {
                  // check the term is not already in the list
                  if (!searchTerms.contains(e)) {
                    // it's a new term, let's add it to searchTerms
                    searchTerms.add(e);
                  }
                }
                // add a paired term for the exact terms
                final newSubterm =
                    filteredTerms.length == 1 ? filteredTerms.first : subTerm;
                if (previousSubTerm.isNotEmpty && newSubterm.isNotEmpty) {
                  searchTerms.add('$previousSubTerm $newSubterm');
                }
                previousSubTerm = newSubterm;
              }
            }
          } else {
            // not an EXACT match term, so tokenize it and add to searchTerms
            final tokens = (await tokenizer.tokenize(rawTermOrPhrase)).terms;
            searchTerms.addAll(tokens);
            searchTerms.add(rawTermOrPhrase);
            final newParsedTerm =
                tokens.length != 1 ? rawTermOrPhrase : tokens.first;
            if (previousParsedTerm.isNotEmpty &&
                newParsedTerm.isNotEmpty &&
                modifier != QueryTermModifier.NOT) {
              searchTerms.add('$previousParsedTerm $newParsedTerm');
            }
            previousParsedTerm =
                next != 'OR' ? newParsedTerm : previousParsedTerm;
          }
          // Let's get rid of duplicates.
          searchTerms = Set<String>.from(searchTerms).toList();
          // initialize a counter for the QueryTerms
          var queryTermIndex = 0;
          // let's iterate through the unique terms/phrases
          for (final qt in searchTerms) {
            if (qt.isNotEmpty && !exactPhrases.contains(qt)) {
              // add a QueryTerm to the return value
              retVal.add(QueryTerm(
                  qt,
                  // if this is the second or later term at this position set its
                  // modifier to OR, unless this is a NOT modified term
                  modifier == QueryTermModifier.EXACT
                      ? QueryTermModifier.OR
                      : queryTermIndex == 0 ||
                              modifier == QueryTermModifier.NOT ||
                              (modifier == QueryTermModifier.IMPORTANT &&
                                  !qt.contains(' '))
                          ? modifier
                          : QueryTermModifier.OR,
                  // the QueryTerms all have the same position
                  termPosition));
            }
            // increment the queryTermIndex
            queryTermIndex++;
          }

          // reset the rawTermOrPhrase
          rawTermOrPhrase = '';
          // and increment the termPosition counter
          termPosition++;
        }
      }
      // increment the termIndex
      termIndex++;
    });
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

extension _TermsListExtension on List<Term> {
  //

  String? previous(int index) => index == 0 ? null : this[index - 1];

  String? next(int index) => index < length - 1 ? this[index + 1] : null;
}

extension _QueryModifierReplacementExtension on Term {
  //

  /// Returns true if the trimmed String is equal to any of:
  /// - ('AND', 'OR', 'NOT', 'EXACTSTART', 'EXACTEND').
  bool get isModifier => [
        'AND',
        'OR',
        'NOT',
        'IMPORTANT',
        'EXACTSTART',
        'EXACTEND'
      ].contains(trim());

  QueryTermModifier modifier(Term? precedingTerm, Term? followingTerm) {
    switch (precedingTerm) {
      case 'OR':
        return QueryTermModifier.OR;
      case 'NOT':
        return QueryTermModifier.NOT;
      case 'IMPORTANT':
        return QueryTermModifier.IMPORTANT;
      case 'EXACTSTART':
        return QueryTermModifier.EXACT;
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

  /// Matches words or phrases enclosed with double quotes and replaces the
  /// leading quote with 'EXACTSTART' and the ending quote with 'EXACTEND'.
  String exact() =>
      replaceAllMapped(RegExp(QueryParserMixin._rInDoubleQuotes), (match) {
        String phrase = match.group(0) ?? '';
        if (phrase.length > 2 &&
            phrase.startsWith(r'"') &&
            phrase.endsWith(r'"')) {
          phrase = phrase.substring(1, phrase.length - 1);
          return 'EXACTSTART $phrase EXACTEND';
        }
        return phrase;
      });
}
