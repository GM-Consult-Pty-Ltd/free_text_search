<!-- 
BSD 3-Clause License
Copyright (c) 2022, GM Consult Pty Ltd
All rights reserved. 
-->

### 0.0.1-beta.6 

Added:
- `ChampionList` definition and extensions.
- scoring extension `Ft Postings.cFt(term)`;
- scoring extension `Ft Postings.dFt(term)`; and
- scoring extension `Ft DocumentPostingsEntry.tfIdf(idFt)`.

Updated dependencies, tests, examples and documentation.

### 0.0.1-beta.5

Added:
- interface `Document`.
- `Ft Postings.tFt(Term)` and `Ft Postings.dFt(Term)` methods.
- `Ft DocumentPostingsEntry.tFt` getter.

Updated dependencies, tests, examples and documentation.

### 0.0.1-beta.4

Updated documentation.

### 0.0.1-beta.3

Testing of `QueryParser` passed.

Updated dependencies, tests, examples and documentation.

### 0.0.1-beta.2

Added:
- object model class `FreeTextQuery`.
- interface class `FreeTextSearch`.
- private implementation class `_FreeTextSearchImpl`.
- enum `QueryTermModifier`.
- class `QueryParser`.
- stub for class `SearchResultScorer`.
- object model class `SearchResult`.
- stub for class `VectorSpaceModel`.

Updated dependencies, tests, examples and documentation.

### 0.0.1-beta.1
- Initial version.