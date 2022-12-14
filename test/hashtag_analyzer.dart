// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'package:free_text_search/free_text_search.dart';
import 'package:hive_text_index/hive_text_index.dart';
// import 'package:text_indexing/text_indexing.dart';
import 'package:text_indexing/type_definitions.dart';
import 'package:text_indexing/extensions.dart';
import 'package:hive/hive.dart';
import 'package:gmconsult_dev/gmconsult_dev.dart';
import 'dart:io';

class HashTagQueryAnalyzer extends English {
  @override
  TermModifier get stemmer => (term) => term.toLowerCase();


  static WeightingStrategy kWeightingStrategy = WeightingStrategy(
      zoneWeights: {'name': 1.0, 'description': 1.0}, positionThreshold: 0);

  static Future<List<Token>> kFilterTokens(List<Token> tokens) async {
    final retVal = <Token>[];
    for (final token in tokens) {
      if (!kExcludedTerms.contains(token.term.toLowerCase())) {
        retVal.add(token);
      }
    }
    return retVal;
  }

  // @override
  // Map<String, String> get termExceptions => {
  //       // '': '',
  //       // '': '',
  //       // '': '',
  //       // '': '',
  //       // '': '',
  //       // '': '',
  //       'securities listed': '',
  //       'stock exchange': '',
  //       'dow jones': '',
  //       'dow': '',
  //       'new york stock exchange': '',
  //       'nasdaq': '',
  //       'listed': '',
  //       'sheets': '',
  //       'pink': '',
  //       'dollar': '',
  //       'exchange': '',
  //       'rate': '',
  //       'crypto exchange': '',
  //       'exchange rate': '',
  //       'securities': '',
  //       'pink sheets': '',
  //       'crypto': '',
  //       '-': '',
  //       '[erc20]': '',
  //       '[eth]': '',
  //       '[waves]': '',
  //       '1': '',
  //       '100': '',
  //       '101529"zone': '',
  //       '13': '',
  //       '2': '',
  //       '20': '',
  //       '2026': '',
  //       '2028': '',
  //       '2031': '',
  //       '2037': '',
  //       '2061': '',
  //       '21': '',
  //       '24': '',
  //       '3': '',
  //       '30': '',
  //       '4': '',
  //       '4125%': '',
  //       '425%': '',
  //       '5': '',
  //       '510%': '',
  //       '5125': '',
  //       '575%': '',
  //       '6': '',
  //       '600': '',
  //       '625%': '',
  //       '6375%': '',
  //       '650%': '',
  //       '66': '',
  //       '675%': '',
  //       '725%': '',
  //       '875%': '',
  //       '887': '',
  //       '900%': '',
  //       'a/s': '',
  //       'ab': '',
  //       'abp': '',
  //       'acb': '',
  //       'acquisi': '',
  //       'acquisitions': '',
  //       'agricolas': '',
  //       'akron': '',
  //       'aktien': '',
  //       'aktiengesellschaft': '',
  //       'allianceinc': '',
  //       'amer': '',
  //       'anonyme': '',
  //       'appomattox': '',
  //       'ariary': '',
  //       'as': '',
  //       'a-s': '',
  //       'association': '',
  //       'atom': '',
  //       'authority': '',
  //       'b2bcoin': '',
  //       'banccorp': '',
  //       'banc-corp': '',
  //       'bancompany': '',
  //       'bancorp-de': '',
  //       'bancorp-in': '',
  //       'bancorporation': '',
  //       'bancshares': '',
  //       'bank-ca': '',
  //       'bankers': '',
  //       'bankshares': '',
  //       'bank-the': '',
  //       'bceao': '',
  //       'beac': '',
  //       'bep2': '',
  //       'berhad': '',
  //       'bermuda': '',
  //       'biologics': '',
  //       'birr': '',
  //       'bits': '',
  //       'block': '',
  //       'blocks': '',
  //       'botetourt': '',
  //       'brands': '',
  //       'brivision': '',
  //       'buy-wr': '',
  //       'c': '',
  //       'caca': '',
  //       'calif': '',
  //       'car': '',
  //       'cash': '',
  //       'cedi': '',
  //       'cemetery': '',
  //       'certificates': '',
  //       'champcoin': '',
  //       'chile': '',
  //       'clarita': '',
  //       'classic': '',
  //       'cloud': '',
  //       'club': '',
  //       'co': '',
  //       'coins': '',
  //       'colon': '',
  //       'coltd': '',
  //       'commo': '',
  //       'commonwealth': '',
  //       'companies': '',
  //       'company': '',
  //       'coop': '',
  //       'cor': '',
  //       'corp': '',
  //       'corpbanca': '',
  //       'corp-de': '',
  //       'corp-ma': '',
  //       'corp-md': '',
  //       'corp-nv': '',
  //       'corp-ny': '',
  //       'corpo': '',
  //       'corpor': '',
  //       'corporat': '',
  //       'corporation': '',
  //       'corp-pa': '',
  //       'corp-taiwan': '',
  //       'corp-the': '',
  //       'corp-va': '',
  //       'corp-wa': '',
  //       'co-the': '',
  //       'crystals': '',
  //       'cypherfunks': '',
  //       'dalarnia': '',
  //       'dao': '',
  //       'dark': '',
  //       'datacoin': '',
  //       'de': '',
  //       'debentures': '',
  //       'decorum': '',
  //       'dep': '',
  //       'depo': '',
  //       'depos': '',
  //       'deposi': '',
  //       'deposita': '',
  //       'depositar': '',
  //       'depositary': '',
  //       'depositor': '',
  //       'dinar': '',
  //       'dirham': '',
  //       'distribuicao': '',
  //       'doctor': '',
  //       'dollars': '',
  //       'dram': '',
  //       'ecoin': '',
  //       'emark': '',
  //       'end': '',
  //       'energia': '',
  //       'engines': '',
  //       'enter': '',
  //       'enterprises': '',
  //       'erush': '',
  //       'escudo': '',
  //       'etf': '',
  //       'etn': '',
  //       'etns': '',
  //       'etn-ubs': '',
  //       'etp': '',
  //       'fcb': '',
  //       'ferry': '',
  //       'fixed-to-f': '',
  //       'floki': '',
  //       'florida': '',
  //       'franc': '',
  //       'fsb': '',
  //       'fund': '',
  //       'funding': '',
  //       'fund-the': '',
  //       'futures': '',
  //       'game': '',
  //       'gerais': '',
  //       'god': '',
  //       'governance': '',
  //       'gram': '',
  //       'graph': '',
  //       'guilder': '',
  //       'h': '',
  //       'hashgraph': '',
  //       'hertfordshire': '',
  //       'holding': '',
  //       'holdings': '',
  //       'i': '',
  //       'i-b': '',
  //       'ii': '',
  //       'iii': '',
  //       'imports': '',
  //       'inc': '',
  //       'inc-ar': '',
  //       'inc-ca': '',
  //       'inc-canada': '',
  //       'inc-china': '',
  //       'inc-co': '',
  //       'inc-de': '',
  //       'inc-fund': '',
  //       'inc-ga': '',
  //       'inc-il': '',
  //       'inc-in': '',
  //       'inc-ky': '',
  //       'inc-la': '',
  //       'inc-ma': '',
  //       'inc-md': '',
  //       'inc-me': '',
  //       'inc-mo': '',
  //       'inc-ny': '',
  //       'inc-oh': '',
  //       'inc-ok': '',
  //       'incorporated': '',
  //       'inc-the': '',
  //       'inc-tn': '',
  //       'inc-tx': '',
  //       'inc-wi': '',
  //       'inc-wv': '',
  //       'indiana': '',
  //       'industries': '',
  //       'initiative': '',
  //       'institutional': '',
  //       'interest': '',
  //       'intermediate': '',
  //       'internationalinc': '',
  //       'international-us': '',
  //       'inu': '',
  //       'iv': '',
  //       'jersey': '',
  //       'kgaa': '',
  //       'kip': '',
  //       'kk': '',
  //       'koin': '',
  //       'kolect': '',
  //       'kong': '',
  //       'koruna': '',
  //       'krona': '',
  //       'krone': '',
  //       'ks': '',
  //       'kwacha': '',
  //       'lab': '',
  //       'laboratories': '',
  //       'laboratories-adr': '',
  //       'ledger': '',
  //       'leisure': '',
  //       'leu': '',
  //       'lev': '',
  //       'limited': '',
  //       'lira': '',
  //       'lite': '',
  //       'llc': '',
  //       'l\'odet': '',
  //       'lp': '',
  //       'lp-ma': '',
  //       'lp-the': '',
  //       'ltd': '',
  //       'ltd-bermuda': '',
  //       'ltd-canada': '',
  //       'ltd-israel': '',
  //       'ltd-singapore': '',
  //       'ltd-the': '',
  //       'lyte': '',
  //       'ma': '',
  //       'mac': '',
  //       'machine': '',
  //       'mae': '',
  //       'maine': '',
  //       'management': '',
  //       'manat': '',
  //       'manda': '',
  //       'mandat': '',
  //       'mandatorily': '',
  //       'maria': '',
  //       'metical': '',
  //       'montreal': '',
  //       'múltiple': '',
  //       'municipals': '',
  //       'mwat': '',
  //       'na': '',
  //       'nc': '',
  //       'nev': '',
  //       'nj': '',
  //       'non-': '',
  //       'norte': '',
  //       'not': '',
  //       'notary': '',
  //       'note': '',
  //       'notes': '',
  //       'nv': '',
  //       'ny': '',
  //       'object': '',
  //       'omani': '',
  //       'oro': '',
  //       'otcm': '',
  //       'ounce': '',
  //       'oyj': '',
  //       'ozk': '',
  //       'p': '',
  //       'pai': '',
  //       'paulo': '',
  //       'pay': '',
  //       'pbc': '',
  //       'people': '',
  //       'pfd': '',
  //       'pharmaceuticals': '',
  //       'pjsc': '',
  //       'platform': '',
  //       'plc': '',
  //       'portfolio': '',
  //       'pos': '',
  //       'potion': '',
  //       'princeton-the': '',
  //       'properties': '',
  //       'protocol': '',
  //       'pyr': '',
  //       'rat': '',
  //       'reale': '',
  //       'reit': '',
  //       'reloaded': '',
  //       'renminbi': '',
  //       'rentcorp': '',
  //       'resettab': '',
  //       'residences': '',
  //       'residential': '',
  //       'return': '',
  //       'rico': '',
  //       'rights': '',
  //       'ringgit': '',
  //       'riyal': '',
  //       'rlc': '',
  //       'rtd': '',
  //       'ruble': '',
  //       'rupees': '',
  //       's': '',
  //       'sa': '',
  //       'saa': '',
  //       'sa-brazil': '',
  //       'sae': '',
  //       'sai': '',
  //       'sal': '',
  //       'sandbox': '',
  //       'santand': '',
  //       'sa-nv': '',
  //       'sas': '',
  //       'savings': '',
  //       'sciences': '',
  //       'scotia-the': '',
  //       'se': '',
  //       'ser': '',
  //       'seri': '',
  //       'serie': '',
  //       'series': '',
  //       'services': '',
  //       'sgps': '',
  //       'share': '',
  //       'shares': '',
  //       'sheqel': '',
  //       'siriusxm': '',
  //       'sirketi': '',
  //       'soberano': '',
  //       'societas': '',
  //       'spa': '',
  //       'spac': '',
  //       'spot': '',
  //       'stake': '',
  //       'states': '',
  //       'storage': '',
  //       'su': '',
  //       'subord': '',
  //       'subordinat': '',
  //       'subordinate': '',
  //       'sum': '',
  //       'sv': '',
  //       'system': '',
  //       'systems': '',
  //       'tas': '',
  //       'tbk': '',
  //       'tcpr': '',
  //       'technologies': '',
  //       'terrafina': '',
  //       'tex': '',
  //       'therapeutics': '',
  //       'tin': '',
  //       'token': '',
  //       'tokens': '',
  //       'tr': '',
  //       'trump': '',
  //       'trust-the': '',
  //       'units': '',
  //       'uruguayo': '',
  //       'ut': '',
  //       'utica': '',
  //       'v2': '',
  //       'va': '',
  //       'vaudoise': '',
  //       'ventures': '',
  //       'vi': '',
  //       'vii': '',
  //       'viii': '',
  //       'voltage': '',
  //       'vr': '',
  //       'when-issued': '',
  //       'works': '',
  //       'wyoming': '',
  //       'xiii': '',
  //       'xngs': '',
  //       'xnys': '',
  //       'y': '',
  //       'zedong': '',
  //       'all': '',
  //       'ang': '',
  //       'aoa': '',
  //       'bats': '',
  //       'bdt': '',
  //       'bitcny': '',
  //       'bzd': '',
  //       'cnh': '',
  //       'cup': '',
  //       'djf': '',
  //       'dop': '',
  //       'dzd': '',
  //       'etb': '',
  //       'gmd': '',
  //       'gnf': '',
  //       'gtq': '',
  //       'hnl': '',
  //       'hrk': '',
  //       'htg': '',
  //       'iexg': '',
  //       'jmd': '',
  //       'kes': '',
  //       'khr': '',
  //       'kmf': '',
  //       'lak': '',
  //       'lbp': '',
  //       'lkr': '',
  //       'lsl': '',
  //       'lyd': '',
  //       'mmk': '',
  //       'mnt': '',
  //       'mop': '',
  //       'mvr': '',
  //       'mwk': '',
  //       'mzn': '',
  //       'ngn': '',
  //       'npr': '',
  //       'pab': '',
  //       'pgk': '',
  //       'rsd': '',
  //       'rwf': '',
  //       'sdg': '',
  //       'std': '',
  //       'szl': '',
  //       'taud': '',
  //       'tzs': '',
  //       'ugx': '',
  //       'vuv': '',
  //       'xaf': '',
  //       'xbru': '',
  //       'xcd': '',
  //       'xof': '',
  //       'xpf': '',
  //       'yer': '',
  //       'zmw': '',
  //     };

  static const kExcludedTerms = {
    'inc',
    'common',
    'common stock',
    'company',
    'stock',
    'corp',
    'trust',
    'limited',
    'dollar',
    'holdings',
    'international',
    'rises',
    'chip',
    'news',
    'replace',
    'forecast',
    'oil',
    'prominent',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'zero',
    'day',
    'week',
    'month',
    'request',
    'new',
    'development',
    'second',
    'first',
    'last',
    'third',
    'state',
    'us',
    'rose',
    'rise',
    'raise',
    'market',
    'dow',
    'nasdaq',
    'jones',
    'today',
    'yesterday',
    'tomorrow',
    'next',
    'previous',
    'consumer',
    'otc',
    'california',
    'site',
    'powell',
    'jay',
    'task',
    'best',
    'dividend',
    'bull',
    'bear',
    'maker',
    'rival',
    'dan',
    'growth',
    'target',
    'elon',
    'greater',
    'great',
    'super',
    'extreme',
    'billionaire',
    'times',
    'simple',
    'may',
    'china',
    'smooth',
    'executive',
    'run',
    'consensus',
    'factset',
    'holding',
    'wall',
    'street',
    'wall street',
    'turn',
    'sector',
    'well',
    'aware',
    'eyes',
    'model',
    'flagship',
    'flat',
    'macro',
    'version',
    'base',
    'big',
    'demand',
    'rising',
    'future',
    'past',
    'present',
    'cascade',
    'acquisition',
    'nice',
    'good',
    'beautiful',
    'paramount',
    'top',
    'brand',
    'brands',
    'pc',
    'advanced',
    'bounce',
    'battery',
    'giant',
    'enormous',
    'major',
    'minor',
    'right',
    'on',
    'daily',
    'chase',
    'hybrid',
    'bond',
    'pink',
    'plant',
    'build',
    'taiwan',
    'korea',
    'boost',
    'fund',
    'car',
    'universe',
    'plus',
    'minus',
    'level',
    'index',
    'cold',
    'hot',
    'mike',
    'consumers',
    'paid',
    'business',
    'labor',
    'running',
    'runner',
    'central',
    'team',
    'rally',
    'rallied',
    'start',
    'finish',
    'flexible',
    'genuine',
    'dependable',
    'ether',
    'relief',
    'enjoy',
    'chorus',
    'wins',
    'positive',
    'input',
    'range',
    'delivery',
    'reading',
    'balance',
    'british',
    'movement',
    'show',
    'milestone',
    'asia',
    'gulf',
    'shore',
    'help',
    'russian',
    'russia',
    'stress',
    'moving',
    'high',
    'high gain',
    'trio',
    'duo',
    'couple',
    'century',
    'millenium',
    'crypto',
    'landmark',
    'fresh',
    'fortress',
    'new york',
    'profit',
    'small business',
    'small',
    'lead',
    'german',
    'french',
    'italian',
    'holiday',
    'merit',
    'fuel',
    'energy',
    'plus products',
    'the',
    'group',
    'gold',
    'silver',
    'platinum',
    'euro',
    'healthcare',
    'customers',
    'sequential',
    'leading',
    'leading edge',
    'solid',
    'medical',
    'usd',
    'wrap',
    'track',
    'risk',
    'grow capital',
    'culp',
    'liquidity',
    'silicon',
    'able',
    'desert',
    'miners',
    'miners reward',
    'shift',
    'her',
    'bath',
    'information',
    'field trip',
    'field',
    'ev',
    'spree',
    'shockwave',
    'hope',
    'pressure',
    'surge',
    'storm',
    'half',
    'securities',
    'security',
    'merchant',
    'due',
    'supply',
    'focus',
    'agree',
    'tech',
    'healthy',
    'installed',
    'advantage',
    'mind',
    'investors',
    'wrapped',
    'view',
    'snap',
    'artificial',
    'intelligent',
    'intelligence',
    'ai',
    'software',
    'emerging',
    'standard',
    'cool',
    'grow',
    'americas',
    'founders',
    'point',
    'fang',
    'gas',
    'natural',
    'credit',
    'federal',
    'credits',
    'general',
    'parts',
    'bank',
    'giga',
    'texas',
    'line',
    '&',
    'mix',
    'technical',
    'industrial',
    'automotive',
    'far',
    'near',
    'deep',
    'lighting',
    'south',
    'north',
    'united',
    'states',
    'united states',
    'complete',
    'post',
    'progress',
    'progressive',
    'exchange',
    'white',
    'house',
    'black',
    'aim',
    'chain',
    'forward',
    'equity',
    'home',
    'trajectory',
    'electric',
    'reflect',
    'research',
    'interplay',
    'morgan',
    'ryan',
    'metals',
    'tailwind',
    'net',
    'booking',
    'par',
    'flow',
    'prime',
    'world',
    'face',
    'pace',
    'american',
    'hong',
    'hong kong',
    'sentiment',
    'global',
    'environment',
    'environmental',
    'waste',
    'products',
    'york',
    'city',
    'john',
    'works',
    'president',
    'commercial',
    'change',
    'public',
    'services',
    'public company',
    'cincinatti,',
    'children',
    'place',
    'fair'
  };
}

class HashTagAnalyzer extends English {
  //

  static Future<List<Token>> kFilterTokens(List<Token> tokens) async {
    final retVal = <Token>[];
    for (final token in tokens) {
      final symbol = getSymbolFromTicker(token.term);
      if (symbol != null) {
        retVal.add(Token(
            symbol.toLowerCase(), token.n, 0, token.zone));
      } else {
        retVal.add(token);
      }
    }
    return retVal;
  }

  static String? getSymbolFromTicker(String term) {
    final matches = RegExp(r'\w+[:/]\w+').allMatches(term);
    if (matches.length == 1) {
      return term.split(RegExp(r'(?<=\w)[:\/](?=\w)')).first;
    }
    return null;
  }

  bool isHashTag(String term) =>
      RegExp(r'(?<=^)[#@]\w+(?=$)').allMatches(term).length == 1;

  @override
  AsyncTermModifier get termFilter => (term, [zone]) async {
        String? retval;
        term = term.removePossessives();
        switch (zone) {
          case 'name':
            term = term.toLowerCase();
            retval = (English.kStopWords.contains(term)) ? null : term;
            break;
          case 'description':
            retval =
                (English.kStopWords.contains(term)) ? null : term.toLowerCase();
            break;
          case 'hashTag':
            retval = term.toLowerCase();
            break;
          default:
            return null;
        }
        return retval;
      };

  static const kStopWords = <String>{};
}

/// Hydrates a [JsonDataService] with a large dataset of securities.
Future<JsonDataService<Box<String>>> get _hashtagsService async {
  final Box<String> dataStore = await Hive.openBox('hashtags');
  return HiveJsonService(dataStore);
}

class HashTagIndex extends HiveTextIndexBase {
  //

  static String get kPath => '${Directory.current.path}\\dev\\data';

  static const kZones = {'name': 1.0, 'hashTag': 1.0};

  static const kK = 3;

  @override
  NGramRange? get nGramRange => NGramRange(1, 2);

  @override
  TextAnalyzer get analyzer => HashTagAnalyzer();

  @override
  final CollectionSizeCallback collectionSizeLoader;

  @override
  int get k => kK;

  @override
  ZoneWeightMap get zones => kZones;

  static Future<void> buildIndex() async {
    Hive.init(kPath);
    final service = await _hashtagsService;
    final index = await HashTagIndex.hydrate();
    await index.clear();
    final iMindex = InMemoryIndex(
        collectionSize: service.dataStore.length,
        analyzer: index.analyzer,
        nGramRange: index.nGramRange,
        k: index.k,
        zones: index.zones);

    // final indexer = TextIndexer(iMindex);
    final keys = service.dataStore.keys.map((e) => e.toString()).toList();
    var i = 0;
    final start = DateTime.now();
    // keys = keys.sublist(16600);
    // PostingsMap lastPostingsMap = {};
    await Future.forEach(keys, (String key) async {
      final json = await service.read(key);
      if (json != null) {
        final name = json['name'].toString().toLowerCase();
        if (name.startsWith('apple inc')) {
          print(json);
        }
        await iMindex.indexJson(key, json,
            tokenFilter: HashTagAnalyzer.kFilterTokens);
        if (name.contains('apple inc')) {
          print(iMindex.postings.getPostings(['apple', 'inc', 'apple inc']));
          // print(lastPostingsMap.keys);
        }
      }
      final l = await iMindex.vocabularyLength;

      i++;
      if (i.remainder(100) == 0) {
        final dT = DateTime.now().difference(start).inSeconds;
        print('Indexed $i hashTags in ${dT.toStringAsFixed(0)} seconds. '
            'Found $l terms.');
        // print(lastPostingsMap.keys);
      }
    });

    await index.upsertDictionary(iMindex.dictionary);
    await index.upsertPostings(iMindex.postings);
    await index.upsertKGramIndex(iMindex.kGramIndex);
    await index.upsertKeywordPostings(iMindex.keywordPostings);
    await service.close();

    await index.dispose();
  }

  static Future<HashTagIndex> hydrate() async {
    final service = await _hashtagsService;
    Future<int> collectionSizeLoader() async => service.dataStore.length;
    final retVal = HashTagIndex._(collectionSizeLoader);
    await retVal.init('hashtags');
    return retVal;
  }

  /// Default constructor
  HashTagIndex._(this.collectionSizeLoader);
}
