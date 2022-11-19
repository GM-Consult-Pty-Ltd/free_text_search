// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/src/_index.dart';

/// The weighting strategy is used in retrieving the top results from an
/// index.
abstract class WeightingStrategy {
  //

  /// Returns a [WeightingStrategy] with a simple linear implementation
  /// of [WeightingStrategy.getWeight], the default [modifierWeights] in
  /// [WeightingStrategy.kDefaultModifierWeights] and a [phraseLengthMultiplier]
  /// of 1.0.
  static const simple =
      _WeightingStrategyImpl(kDefaultModifierWeights, 1.0, null, null);

  /// A factory constructor that returns a [WeightingStrategy] implementation.
  /// - [modifierWeights] is a hashmap of [QueryTermModifier] to weighting
  ///   value. The default is [WeightingStrategy.kDefaultModifierWeights].
  ///   If [modifierWeights] does not include keys for all [QueryTermModifier]
  ///   values, the key will be looked up in
  ///   [WeightingStrategy.kDefaultModifierWeights].
  /// - [phraseLengthMultiplier] is a multiplier to apply to the phrase length
  ///   of a [QueryTerm]. The default is 1.0.
  ///
  /// The returned implementation class provides a simple linear implementation
  /// of [WeightingStrategy.getWeight] that computes the weight for a
  /// [QueryTerm] by adding the modifier weight (from [modifierWeights]) to the
  /// product of the phrase length and [phraseLengthMultiplier].
  /// [phraseLengthMultiplier].
  factory WeightingStrategy(
          {Map<QueryTermModifier, double> modifierWeights =
              kDefaultModifierWeights,
          double phraseLengthMultiplier = 1.0,
          Map<String, double>? zoneWeights,
          int? positionThreshold}) =>
      _WeightingStrategyImpl(modifierWeights, phraseLengthMultiplier,
          zoneWeights, positionThreshold);

  /// Default value for [WeightingStrategy.modifierWeights].
  static const kDefaultModifierWeights = {
    QueryTermModifier.NOT: -20.0,
    QueryTermModifier.AND: 1.0,
    QueryTermModifier.OR: 0.5,
    QueryTermModifier.IMPORTANT: 3.0,
    QueryTermModifier.EXACT: 4.0,
  };

  /// Apply a higher weight to terms that occur at the start of a posting.
  ///
  /// Postings that have a termPosition higher than [positionThreshold] will not
  /// be counted when calculating the document frequency of a term.
  ///
  /// If [positionThreshold] is null then all postings will have equal weight,
  /// regardless of term position.
  int? get positionThreshold;

  /// A hashmap of [QueryTermModifier] to weighting value.
  ///
  /// The [modifierWeights] map should include keys for all [QueryTermModifier]
  /// values. Alternaively, implement [getWeight] to use a default weight if
  /// the map does not contain a [QueryTermModifier] weight.
  Map<QueryTermModifier, double> get modifierWeights;

  /// A multiplier to apply to the phrase length of a [QueryTerm].
  double get phraseLengthMultiplier;

  /// A multiplier to apply to term frequencies in specific document
  /// zones/fields.
  ///
  /// If [zoneWeights] is null, all zones will be included with a weight of
  /// 1.0.
  Map<String, double>? get zoneWeights;

  /// Calculates a weight for the term based on its modifier and phrase length.
  double getWeight(QueryTerm queryTerm);
}

/// Mixin class that implements [WeightingStrategy.getWeight].
abstract class WeightingStrategyMixin implements WeightingStrategy {
  //

  /// A simple linear implementation of [WeightingStrategy.getWeight].
  ///
  /// Computes the weight for the [queryTerm] by adding the modifier
  /// weight (from [modifierWeights]) to the product of the phrase length and
  /// [phraseLengthMultiplier].
  @override
  double getWeight(QueryTerm queryTerm) {
    final modifierWeight = modifierWeights[queryTerm.modifier] ??
        WeightingStrategy.kDefaultModifierWeights[queryTerm.modifier] ??
        1.0;
    final phraseLengthWeight = queryTerm.n * phraseLengthMultiplier;
    return modifierWeight + phraseLengthWeight;
  }
}

/// Abstract base class implementation of [WeightingStrategy], mixes in
/// [WeightingStrategyMixin].
///
/// Provides a const default generative constructor for sub-classes.
abstract class WeightingStrategyBase with WeightingStrategyMixin {
  /// A const default generative constructor for sub-classes.
  const WeightingStrategyBase();
}

/// Implementation class for [WeightingStrategy] factory constructor.
class _WeightingStrategyImpl extends WeightingStrategyBase {
  //

  @override
  final Map<String, double>? zoneWeights;

  @override
  final Map<QueryTermModifier, double> modifierWeights;

  @override
  final double phraseLengthMultiplier;

  /// A const default generative constructor .
  const _WeightingStrategyImpl(this.modifierWeights,
      this.phraseLengthMultiplier, this.zoneWeights, this.positionThreshold);

  @override
  final int? positionThreshold;
}
