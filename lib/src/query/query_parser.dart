// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// A utility class that parses free text queries.
///
/// Ensure that the [configuration] and [tokenFilter] match the [TextAnalyzer]
/// used to construct the index on the target collection that will be searched.
///
/// The [parse] method parses a phrase to a collection of [QueryTerm]s
/// that includes:
/// - all the original words in the phrase, except query modifiers
///   ('AND', 'OR', '"', '-', 'NOT);
/// - derived versions of all words returned by the [configuration].termFilter,
///   including child words of exact phrases; and
/// - derived versions of all words always have the [QueryTermModifier.OR]
///   unless they are already marked [QueryTermModifier.NOT].
class QueryParser extends TextAnalyzer {
  //

  /// Instantiates a [QueryParser] instance:
  /// - [configuration] is used to tokenize the query phrase (default is
  ///   [English.configuration]); and
  /// - provide a custom [tokenFilter] if you want to manipulate tokens or
  ///   restrict tokenization to tokens that meet specific criteria (default is
  ///   [TextAnalyzer.defaultTokenFilter].
  const QueryParser(
      {TextAnalyzerConfiguration configuration = English.configuration,
      TokenFilter tokenFilter = TextAnalyzer.defaultTokenFilter})
      : super(configuration: configuration, tokenFilter: tokenFilter);

  /// Shortcut to configuration.termFilter
  TermFilter get _termFilter => configuration.termFilter;

  /// Shortcut to configuration.termSplitter
  TermSplitter get _termSplitter => configuration.termSplitter;

  /// Parses a search [phrase] to a collection of [QueryTerm]s.
  ///
  /// The returned collection will include:
  /// - all the original words in the [phrase], except query modifiers
  ///   ('AND', 'OR', '"', '-', 'NOT);
  /// - derived versions of all words returned by the [_termFilter], including
  ///   child words of exact phrases; and
  /// - derived versions of all words always have the [QueryTermModifier.OR]
  ///   unless they are already marked [QueryTermModifier.NOT].
  Future<List<QueryTerm>> parse(String phrase) async {
    // - initialize the return value;
    final retVal = <QueryTerm>[];
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
    for (final term in terms) {
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
            ? term.modifier(previous)
            // if this is a term in an exact phrase, set it to EXACT
            : QueryTermModifier.EXACT;
        // concatenate rawTermOrPhrase and term, inserting a space if rawTermOrPhrase
        // already contains a word.
        rawTermOrPhrase =
            rawTermOrPhrase.isEmpty ? term : '$rawTermOrPhrase $term';
        // check modifier is not EXACT or else the next term is "EXACTEND":
        if (modifier != QueryTermModifier.EXACT || next == 'EXACTEND') {
          // if we're here it means we can add the term to the return value
          // because it is either:
          // NOT an exact match term, or
          // the last word in an exact match phrase
          //
          // let's initialize a collection to hold the exact term/phrase and any
          // child words of a phrase or a stemmed version of the term.
          var searchTerms = <String>[rawTermOrPhrase];
          // check if we are dealing with an exact term or phrase
          if (modifier == QueryTermModifier.EXACT) {
            // ok it's an exact match phrase
            //

            // now split the phrase at whitespace into its component words
            final subterms = rawTermOrPhrase.split(RegExp(r'\s+'));
            // let's iterate through the subTerms and add them to the searchTerms
            for (var subTerm in subterms) {
              // first check the subTerm is not empty
              if (subTerm.isNotEmpty) {
                // not an empty subTerm, so let's stem/split the subTerm by
                // passing it to the termFilter callback
                final filteredTerms = await _termFilter(subTerm);
                // now iterate through whatever we got back from the termFilter
                for (final e in filteredTerms) {
                  // check the term is not already in the list
                  if (!searchTerms.contains(e)) {
                    // it's a new term, let's add it to the list
                    searchTerms.add(e);
                  }
                }
              }
            }
          } else {
            // this is not an EXACT match term, so pass it to the termFilter to
            // get the stemmed version or split terms and add it/them to the list
            searchTerms.addAll(await _termFilter(rawTermOrPhrase));
          }
          // Let's get rid of duplicates.
          searchTerms = Set<String>.from(searchTerms).toList();
          // initialize a counter for the QueryTerms
          var queryTermIndex = 0;
          // let's iterate through the unique terms/phrases
          for (final qt in searchTerms) {
            // hydrate the QueryTerm
            final queryTerm = QueryTerm(
                qt,
                // if this is the second or later term at this position set its
                // modifier to OR, unless this is a NOT modified term
                queryTermIndex == 0 || modifier == QueryTermModifier.NOT
                    ? modifier
                    : QueryTermModifier.OR,
                // the QueryTerms all have the same position
                termPosition);
            // add it to the return value
            retVal.add(queryTerm);
            // increment the queryTermIndex
            queryTermIndex++;
          }
          // as this was not an EXACT modified term or the next term is
          // "EXACTEND":

          // reset the rawTermOrPhrase
          rawTermOrPhrase = '';
          // and increment the termPosition counter
          termPosition++;
        }
      }
      // increment the termIndex
      termIndex++;
    }
    // return the QueryTerms collection return value
    return retVal;
  }
}

extension _TermsListExtension on List<String> {
  String? previous(int index) => index == 0 ? null : this[index - 1];

  String? next(int index) => index < length - 1 ? this[index + 1] : null;
}

extension _QueryModifierReplacementExtension on String {
  //

  /// Matches all phrases included in quotes.
  static const rInDoubleQuotes = r'"\w[^"]+\w"';

  /// Matches '-' where preceded by white-space or the start of the string AND
  /// followed by a double quote or word character.
  static const rNot = r'(?<=^|\s)-(?="|\w)';

  /// Matches '+' where preceded by white-space or the start of the string AND
  /// followed by a double quote or word character.
  static const rImportant = r'(?<=^|\s)\+(?="|\w)';

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

  QueryTermModifier modifier(String? previousTerm) {
    switch (previousTerm) {
      case 'OR':
        return QueryTermModifier.OR;
      case 'NOT':
        return QueryTermModifier.NOT;
      case 'IMPORTANT':
        return QueryTermModifier.IMPORTANT;
      case 'EXACTSTART':
        return QueryTermModifier.EXACT;
      default:
        return QueryTermModifier.AND;
    }
  }

  /// Replaces all the [QueryTermModifier] instances with tokens;
  String replaceModifiers() => not().important().exact();

  /// Replaces '-' at the start of a term or phrase with 'NOT '.
  String not() => replaceAll(RegExp(rNot), 'NOT ');

  /// Replaces '-' at the start of a term or phrase with 'NOT '.
  String important() => replaceAll(RegExp(rImportant), 'IMPORTANT ');

  /// Matches words or phrases enclosed with double quotes and replaces the
  /// leading quote with 'EXACTSTART' and the ending quote with 'EXACTEND'.
  String exact() => replaceAllMapped(RegExp(rInDoubleQuotes), (match) {
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
// ///
// class QueryParserConfiguration extends English {}
