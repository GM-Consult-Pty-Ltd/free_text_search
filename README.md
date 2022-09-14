<!-- 
BSD 3-Clause License
Copyright (c) 2022, GM Consult Pty Ltd
All rights reserved. 
-->

# free_text_search

Search a inverted positional index and return ranked references to documents relevant to the search phrase.

*THIS PACKAGE IS IN BETA DEVELOPMENT AND SUBJECT TO DAILY BREAKING CHANGES.*

Skip to section:
- [Overview](#overview)
- [Usage](#usage)
- [API](#api)
- [Definitions](#definitions)
- [References](#references)
- [Issues](#issues)


## Overview

The components of this library:
* parse a free-text phrase to a query; 
* search the `dictionary` and `postings` of a text `index` for the query `terms`; 
* perform iterative scoring and ranking of the returned dictionary entries and postings; and 
* return ranked references to documents relevant to the search phrase.

Query phrases can include [modifiers](#query-modifiers) broadly consistent with Google search modifiers. 

![Free text search overview](https://github.com/GM-Consult-Pty-Ltd/free_text_search/raw/main/assets/images/free_text_search.png?raw=true?raw=true "Free text search overview")

Refer to the [references](#references) to learn more about information retrieval systems and the theory behind this library.

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

To parse a phrase simply pass it to the `QueryParser.parse` method, including any [modifiers](#query-modifiers) as shown  in the snippet below. 

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

### `FreeTextQuery` class

`TODO: README for FreeTextQuery class`

### `QueryParser` class

`QueryParser` parses free text queries, returning a collection of `QueryTerm` objects that enumerate each term and its `QueryTermModifier`.

The `QueryParser.configuration` and `QueryParser.tokenFilter` should match the `TextAnalyzer`used to construct the index on the target collection that will be searched.

#### Query modifiers

The phrase can include the following modifiers to guide the the search results scoring/ranking algorithm:
* terms or phrases wrapped in double quotes will be marked `QueryTermModifier.EXACT` (e.g.`"athletics track"`);
* terms preceded by `"OR"` are marked `QueryTermModifier.OR` and are alternatives to the preceding term;
* terms can be preceded by `"NOT" or "-"` are marked `QueryTermModifier.NOT` to rank results lower if they include these terms; 
* terms following the plus sign `"+"` are marked `QueryTermModifier.IMPORTANT` to rank results that include these terms higher; and
* all other terms are marked as `QueryTermModifier.AND`.

The `QueryParser.parse` method parses a phrase to a collection of `QueryTerm`s that includes:
- all the original words in the phrase, except query modifiers ('AND', 'OR', '"', '-', 'NOT);
- derived versions of all words returned by the `QueryParser.configuration.termFilter`, including child words of exact hrases; and
- derived versions of all words always have the `QueryTermModifier.OR` unless they are already marked `QueryTermModifier.NOT`.

## Definitions

The following definitions are used throughout the [documentation](https://pub.dev/documentation/free_text_search/latest/):

* `corpus`- the collection of `documents` for which an `index` is maintained.
* `dictionary` - is a hash of `terms` (`vocabulary`) to the frequency of occurence in the `corpus` documents.
* `document` - a record in the `corpus`, that has a unique identifier (`docId`) in the `corpus`'s primary key and that contains one or more text fields that are indexed.
* `index` - an [inverted index](https://en.wikipedia.org/wiki/Inverted_index) used to look up `document` references from the `corpus` against a `vocabulary` of `terms`. The implementation in this package builds and maintains a positional inverted index, that also includes the positions of the indexed `term` in each `document`.
* `postings` - a separate index that records which `documents` the `vocabulary` occurs in. In this implementation we also record the positions of each `term` in the `text` to create a positional inverted `index`.
* `postings list` - a record of the positions of a `term` in a `document`. A position of a `term` refers to the index of the `term` in an array that contains all the `terms` in the `text`.
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


