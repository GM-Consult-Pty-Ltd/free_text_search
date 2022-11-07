// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

/// Search an inverted positional index and return ranked references to documents relevant to the search phrase.
library free_text_search;

/// Export of barrel file in the /src folder.
export 'src/_index.dart'
    show
        WeightingStrategy,
        WeightingStrategyBase,
        WeightingStrategyMixin,
        QueryParser,
        QueryParserBase,
        QueryParserMixin,
        QuerySearchResult,
        QuerySearchResultBase,
        QuerySearchResultMixin,
        QuerySearch,
        QuerySearchBase,
        QuerySearchMixin,
        StartsWithSearch,
        StartsWithSearchMixin,
        StartsWithSearchBase,
        FreeTextSearch,
        FreeTextSearchBase,
        FreeTextSearchMixin,
        FreeTextQuery,
        FreeTextQueryBase,
        FreeTextQueryMixin,
        QueryTerm,
        QueryTermModifier;

export 'package:text_indexing/text_indexing.dart';
