<!-- 
BSD 3-Clause License
Copyright (c) 2022, GM Consult Pty Ltd
All rights reserved. 
-->

# free_text_search

Search a text index and return ranked references to documents relevant to a search phrase.

*THIS PACKAGE IS IN BETA DEVELOPMENT AND SUBJECT TO DAILY BREAKING CHANGES.*

Skip to section:
- [Overview](#overview)
- [Usage](#usage)
- [API](#api)
- [Definitions](#definitions)
- [References](#references)
- [Issues](#issues)


## Overview

This library is intended for applications that are part of an information retrieval system with the following components:
* a [text analyzer](https://pub.dev/packages/text_analysis) that extracts tokens from text for use in full-text search queries and indexes (`tokenizer`);
* a [text indexer](https://pub.dev/packages/text_indexing) that creates an [inverted positional index](https://pub.dev/packages/text_indexing) for a collection of text documents (the `inverted index`); 
* a [query parser](#queryparser) that parses a free text query into tokens using a `tokenizer` while extracting the `query term modifiers` for each token;
* tools for performing [index elimination](#index-elimination) to reduce the number of results returned from the `index` (if too many results are found); 
* `query expansion functions` to increase the number of search results by including synonyms for terms and correcting the spelling of misspelt terms; and
* a `scoring and ranking` tool that iterates over the results to compute a score for each document that enumerates how well it matches the search phrase.

This library provides the [query parser](#queryparser), [index elimination tools](#index-elimination), `query expansion functions` and a [scoring and ranking module](#scoring-and-ranking).

Refer to the [references](#references) to learn more about information retrieval systems and the theory behind this library.

### Free Text Search Workflow

The free-text search workflow consists of:
* a [query phrase](#the-query-phrase) is presented to the search engine;
* the [query parser](#the-query-parser) splits the [query phrase](#the-query-phrase) into query terms, each with a modifier and position information. The [query parser](#the-query-phrase) applies `query expansion` techniques to add synonyms to the terms, apply a spell checker and compose phrases from adjacent terms;
* the `postings` in an inverted index is then queried, retrieving all postings for the terms (or phrases) in the query;
* if the number of returned postings is greater than required (e.g. the number of document summaries that can be displayed on a list of search results), a process of [index elimination](#index-elimination) culls the postings to the those most likely to match the query.
* the [scoring and ranking engine](#scoring-and-ranking) is now applied to the remaining postings candidates, returning a ranked and scored set of [query results](#query-results).


![Free text search overview](https://github.com/GM-Consult-Pty-Ltd/free_text_search/raw/main/dev/images/free_text_search.png?raw=true?raw=true "Free text search overview")


### The Query Phrase

A free-text query is usually a small number of key terms, possibly also including one or more query term modifiers. The objective is to find from the `corpus` a subset of documents that have the best match with the query. 

This library implements query term modifiers broadly consistent with those used in the [Google](https://support.google.com/websearch/answer/2466433?hl=en) the search engine:
* terms or phrases can be wrapped in double quotes to find an exact match;
* terms preceded by `"OR"` are alternatives to the preceding term;
* if terms are preceded by `"NOT" or "-"` documents including these terms are excluded from results; and
* query results that contain terms preceded by plus sign `"+"` or the upper-case word `"IMPORTANT"` are ranked higher.

### The Query Parser

The query parser converts a free-text query into a collection of [QueryTerm](#queryterm-class) objects, each with its term, position in the query phrase and any modifiers.

![Query Parser](https://github.com/GM-Consult-Pty-Ltd/free_text_search/raw/main/dev/images/query_parser.png?raw=true?raw=true "Query Parser")

The [term parser](#querytermparser-class) first:
* extracts any words or phrases in double quotes and adds them to the query terms collection at position 0; then
* replaces all modifier tokens and characters with special tokens; before 
* calling the the tokenizer for the index that is queried to tokenize the phrase; then
* iterates over the tokens to map terms to [QueryTerm](#queryterm-class)s each with a position and modifier. 
Phrases are composed using adjacent terms. The phrase length is limited to the phrase length limit of the index.

The search phrase and final query terms are used to return a [FreeTextQuery](#freetextquery-class).

An extension method on [Token](https://pub.dev/documentation/text_analysis/latest/text_analysis/Token-class.html), [Set<KGram> kGrams([int k = 3])](https://pub.dev/documentation/text_analysis/latest/text_analysis/KGramParserExtension/kGrams.html) is used to the `k-grams` in the query tokens.

If a query does not return the expected number of search results from the index (see [index elimination](#index-elimination)) the collection of query terms can be [expanded](#query-expansion).

### Query Expansion

If a query does not return the expected number of search results from the index (see [index elimination](#index-elimination)) the collection of query terms can be expanded:
* synonyms may be retrieved from a synonym index or a lexical (dictionary/thesaurus) service; and
* terms that are not found in the index can bassed to a spelling correction callback appropriate to the index. 

### Index Elimination

`Index elimination` is the process of extracting a subset of the index postings for the likely highest scoring documents against the query phrase (`inexact top K document retrieval`). In this library, `index elimination` is an iterative process:
* calculate the number of documents (`K`) that would return a set of search results with high precision while maintaining performance;
* query the index `postings` for all the terms in the [FreeTextQuery.queryTerms](#freetextquery-class);
* expand the collection of query terms if too few results are returned or important or exact terms return no results from the index;
* if the number of returned `postings` is less than K, return proceed to [scoring and ranking](#scoring-and-ranking); else
* iteratively create consecutive tiered indexes and add the postings for each tiered index to the results set until it has grown to K, or all steps have been completed.

The tiered indexes are created as follows:
* `exact terms index` contains only those postings for `"exact match"` modified query terms;
* `phrase index` contains only those postings for query sub-phrases (i.e. more than one word); and
* `champion lists` are postings for documents with the highest term frequencies for each term.

![Index Elimination](https://github.com/GM-Consult-Pty-Ltd/free_text_search/raw/main/dev/images/index_elimination.png?raw=true?raw=true "Index Elimination")

### Scoring and Ranking

#### Champion Lists

#### Static Quality Scoring

#### Impact Ordering

#### Vector Space Model

### Query Results








Usually the number of returned documents is limited to what can be displayed on one page of a list of search results, say in the range of 20 - 50.

The workflow for performing a free-text search implemented in this library has the following steps:
*


* parse a free-text phrase with [query modifiers](#querytermmodifier-enumeration) to a query; 
* retrieves `postings` for the query [terms](#queryterm-class) from an inverted index; 

* perform iterative scoring and ranking of the returned dictionary entries and postings; and 
* return ranked references to documents relevant to the search phrase.


### Scoring and Ranking



## Usage

In the `pubspec.yaml` of your flutter project, add the `free_text_search` dependency.

```yaml
dependencies:
  free_text_search: <latest version>
```

In your code file add the `free_text_search` import.

```dart
import 'package:free_text_search/free_text_search.dart';
```

To parse a phrase simply pass it to the `QueryParser.parse` method, including any [modifiers](#querytermmodifier-enumeration) as shown  in the snippet below. 

```dart
// A phrase with all the modifiers
  const phrase =
      '"athletics track" +surfaced arena OR stadium "Launceston" -hobart NOT help-me';

  // Pass the phrase to a QueryParser instance parse method
  final queryTerms = await QueryParser().parse(phrase);

  // The following terms and their `[MODIFIER]` properties are returned
        // "athletics track" [EXACT] 
        // "athletics" [OR] 
        // "track" [OR] 
        // "surfaced" [IMPORTANT] 
        // "arena" [AND] 
        // "stadium" [OR] 
        // "Launceston" [EXACT] 
        // "launceston" [OR] 
        // "hobart" [NOT] 
        // "help-me" [NOT] 
        // "help" [NOT]     

```

The [examples](https://pub.dev/packages/free_text_search/example) demonstrate the use of the [QueryParser](#queryparser-class) and [PersistedIndexer](#persistedindexer-class).

## API

To maximise performance, the API manipulates nested hashmaps of DART core types `int`, `double` and `String` rather than defining strongly typed object models. To improve code legibility and maintainability the API makes use of [type aliases](#type-aliases) throughout.

### Type Aliases

The following type definitions are defined in this library to complement the type definitions imported from the `text_analysis` and `text_indexing` packages.

* `ChampionList` is an alias for `Map<Term, List<Document>>`, a hashmap of `Term` to the list of `Document`s that contain that  term. The ordered set of `Document`s is in descending order of term frequency (`Ft`) and each document (`Document.docId`) can only occur once.;
* `ChampionListEntry` is an alias for `MapEntry<Term, List<Document>>`, an entry in a `ChampionList`;
* `` is an alias for ``, a ;

### FreeTextSearch class

The `FreeTextSearch` class exposes the `search` method that returns a list of [QuerySearchResult](#searchresult-class) instances in descending order of relevance.

The length of the returned collection of [QuerySearchResult](#searchresult-class) can be limited by passing a limit parameter to `search`. The default limit is 20.

After parsing the phrase to terms, the `PostingsMap` and `Dictionary` for the query terms are asynchronously retrieved from the index:
* `FreeTextSearch.dictionaryLoader` retrieves `Dictionary`; 
* `FreeTextSearch.postingsLoader` retrieves `PostingsMap`;
* `FreeTextSearch.configuration` is used to tokenize the query phrase (defaults to `English.configuration`); and
* provide a custom `tokenFilter` if you want to manipulate tokens or restrict tokenization to tokens that meet specific criteria (default is `TextAnalyzer.defaultTokenFilter`.
  
Ensure that the `FreeTextSearch.configuration` and `FreeTextSearch.tokenFilter` match the `TextAnalyzer` used to construct the index on the target collection that will be searched.

### FreeTextQuery class

The `FreeTextQuery` enumerates the properties of a text search query:
* `FreeTextQuery.phrase` is the unmodified search phrase, including all modifiers and tokens; and
* `FreeTextQuery.terms` is the ordered list of all terms extracted from the `phrase` used to look up results in an inverted index.

### QuerySearchResult class  

 The `QuerySearchResult` model represents a ranked search result of a query against a text index:
 * `QuerySearchResult.docId` is the unique identifier of the document result in the corpus; and
 * `QuerySearchResult.relevance` is the relevance score awarded to the document by the scoring and ranking  algorithm. Higher scores indicate increased relevance of the document.

### QueryTerm class

The `QueryTerm` object extends `Token`, and enumerates the properties of a term in a free text query phrase:
* `QueryTerm.term` is the term that will be looked up in the index;
* `QueryTerm.termPosition` is the zero-based position of the `term` in an ordered list of all the terms in the source text; and
* `FreeTextQuery.modifier` is the [QueryTermModifier](#querytermmodifier-enumeration) applied for this term. The default modifier` is `QueryTermModifier.AND`.

### QueryParser class

The `QueryParser` parses free text queries, returning a collection of [QueryTerm](#queryterm-class) objects that enumerate each term and its [QueryTermModifier](#querytermmodifier-enumeration).

The `QueryParser.configuration` and `QueryParser.tokenFilter` should match the `TextAnalyzer`used to construct the index on the target collection that will be searched.

The `QueryParser.parse` method parses a phrase to a collection of [QueryTerm](#queryterm-class)s that includes:
* all the original words in the phrase, except query modifiers ('AND', 'OR', '"', '+', '-', 'NOT);
* derived versions of all words returned by the `QueryParser.configuration.termFilter`, including child words and stems or lemmas of exact phrases; and

A [QueryTerm](#queryterm-class) for a derived version of a term always has its `QueryTerm.modifier` property set to `QueryTermModifier.OR`, unless the term was marked `QueryTermModifier.NOT` in the query phrase.

### QueryTermModifier enumeration

The phrase can include the following modifiers to guide the the search results scoring/ranking algorithm:
* terms or phrases wrapped in double quotes will be marked `QueryTermModifier.EXACT` (e.g.`"athletics track"`);
* terms preceded by `"OR"` are marked `QueryTermModifier.OR` and are alternatives to the preceding term;
* terms preceded by `"NOT" or "-"` are marked `QueryTermModifier.NOT` to rank results lower if they include these terms; 
* terms following the plus sign `"+"` are marked `QueryTermModifier.IMPORTANT` to rank results that include these terms higher; and
* all other terms are marked as `QueryTermModifier.AND`.


### QueryTermParser class


### QueryTermExpander class

## Definitions

The following definitions are used throughout the [documentation](https://pub.dev/documentation/free_text_search/latest/):

* `corpus`- the collection of `documents` for which an `index` is maintained.
* `dictionary` - is a hash of `terms` (`vocabulary`) to the frequency of occurence in the `corpus` documents.
* `document` - a record in the `corpus`, that has a unique identifier (`docId`) in the `corpus`'s primary key and that contains one or more text fields that are indexed.
* `index` - an [inverted index](https://en.wikipedia.org/wiki/Inverted_index) used to look up `document` references from the `corpus` against a `vocabulary` of `terms`. The implementation in this library relies on a positional inverted index, that also includes the positions of the indexed `term` in each `document`.
* `index-elimination` - extracting a subset of the index postings for the likely highest scoring documents against the query phrase (`inexact top K document retrieval`).
* `postings` - a separate index that records which `documents` the `vocabulary` occurs in. 
* `postings list` - a record of the positions of a `term` in a `document` and its fields. A position of a `term` refers to the index of the `term` in an array that contains all the `terms` in the `text`.
* `term` - a word or phrase that is indexed from the `corpus`. The `term` may differ from the actual word used in the corpus depending on the `tokenizer` used.
* `text` - the indexable content of a `document`.
* `token` - representation of a `term` in a text source returned by a `tokenizer`. The token may include information about the `term` such as its position(s) in the text or frequency of occurrence.
* `tokenizer` - a function that returns a collection of `token`s from `text`, after applying a character filter, `term` filter, [stemmer](https://en.wikipedia.org/wiki/Stemming) and / or [lemmatizer](https://en.wikipedia.org/wiki/Lemmatisation).
* `vocabulary` - the collection of `terms` indexed from the `corpus`.

## References

* [Manning, Raghavan and Schütze, "*Introduction to Information Retrieval*", Cambridge University Press, 2008](https://nlp.stanford.edu/IR-book/pdf/irbookprint.pdf)
* [University of Cambridge, 2016 "*Information Retrieval*", course notes, Dr Ronan Cummins, 2016](https://www.cl.cam.ac.uk/teaching/1516/InfoRtrv/)
* [Wikipedia (1), "*Inverted Index*", from Wikipedia, the free encyclopedia](https://en.wikipedia.org/wiki/Inverted_index)
* [Wikipedia (2), "*Lemmatisation*", from Wikipedia, the free encyclopedia](https://en.wikipedia.org/wiki/Lemmatisation)
* [Wikipedia (3), "*Stemming*", from Wikipedia, the free encyclopedia](https://en.wikipedia.org/wiki/Stemming)

## Issues

If you find a bug please fill an [issue](https://github.com/GM-Consult-Pty-Ltd/free_text_search/issues).  

This project is a supporting package for a revenue project that has priority call on resources, so please be patient if we don't respond immediately to issues or pull requests.


