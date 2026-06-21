import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:reagentkit/features/reagent_testing/data/services/unified_data_service.dart';
import 'package:reagentkit/features/reagent_testing/data/models/reagent_test_model.dart';
import 'package:reagentkit/scientific_engine/safe_parsers.dart';
import 'package:reagentkit/scientific_engine/validation_profile.dart';
import 'package:reagentkit/scientific_engine/dataset_parsing_exception.dart';

void main() {
  group('Dataset Resilience Parsing Isolate Tests', () {
    test('Parses a perfectly valid dataset list cleanly', () {
      final jsonStr = jsonEncode({
        'version': '2.0.1',
        'reagents': [
          {
            'id': 'test_reagent_1',
            'reagentName': 'Test Reagent 1',
            'reagentNameAr': 'كاشف تجريبي 1',
            'description': 'Description 1',
            'descriptionAr': 'الوصف 1',
            'safetyLevel': 'LOW',
            'safetyLevelAr': 'منخفض',
            'category': 'Screening',
            'testDuration': 10,
            'chemicals': ['Chemical A'],
            'testInstructions': [
              {'step': 1, 'instruction': 'Do A', 'instructionAr': 'افعل أ'}
            ],
            'reactionResults': [
              {'analyteName': 'Analyte X', 'color': '#FF0000', 'colorAr': 'أحمر'}
            ],
            'references': [
              'Auterhoff & Braun, Arch.Pharm. (1973)'
            ],
            'safety': {
              'requiredEquipment': ['Gloves'],
              'handlingProcedures': ['Ventilate'],
              'specificHazards': ['Flammable'],
              'storageRequirements': ['Cool room']
            }
          }
        ]
      });

      final output = parseScientificDatasetIsolate(ParseParams(jsonStr, ValidationProfile.balanced));

      expect(output.error, isEmpty);
      expect(output.version, '2.0.1');
      expect(output.parsedReagents.length, 1);
      expect(output.rawItemsCount, 1);
      expect(output.skippedItemsCount, 0);
      expect(output.invalidColorsCount, 0);
      expect(output.invalidReferencesCount, 0);

      // Verify model conversion
      final model = ReagentTestModel.fromJson(output.parsedReagents.first);
      expect(model.id, 'test_reagent_1');
      expect(model.reagentName, 'Test Reagent 1');
      expect(model.references.length, 1);
      expect(model.reactionResults.first.drugName, 'Analyte X');
    });

    test('Skips corrupted reagents and records diagnostics metrics', () {
      final jsonStr = jsonEncode({
        'schemaVersion': '3.0.0',
        'reagents': [
          // Valid item
          {
            'id': 'valid_item',
            'reagentName': 'Valid Item',
            'category': 'Test',
            'reactionResults': [
              {'analyteName': 'Test Substance', 'color': 'rgb(0, 255, 0)'}
            ]
          },
          // Corrupted item (raw string instead of Map)
          'corrupted_raw_string_item',
          // Item with invalid reference and color fallback
          {
            'id': 'invalid_refs_colors',
            'reagentName': 'Invalid Refs and Colors',
            'category': 'Test',
            'reactionResults': [
              {'analyteName': 'Substance', 'color': 'not-a-real-color'}
            ],
            'references': [
              '  ', // empty reference
              null // null reference
            ]
          }
        ]
      });

      final output = parseScientificDatasetIsolate(ParseParams(jsonStr, ValidationProfile.balanced));

      // Valid item and invalid_refs_colors should parse, but corrupted_item will be skipped
      expect(output.version, '3.0.0');
      expect(output.parsedReagents.length, 2);
      expect(output.rawItemsCount, 3);
      expect(output.skippedItemsCount, 1); // corrupted_item failed to parse and is skipped
      expect(output.invalidColorsCount, 1); // not-a-real-color falls back to grey (128,128,128)
      expect(output.invalidReferencesCount, 2); // 1 empty string, 1 null
    });

    test('Handles malformed JSON string FormatException safely', () {
      final output = parseScientificDatasetIsolate(ParseParams('{"reagents": [invalid JSON}', ValidationProfile.balanced));
      expect(output.parsedReagents, isEmpty);
      expect(output.error, contains('JSON decode FormatException'));
    });

    test('Deduplicates reagents by ID correctly', () {
      final list = [
        {
          'id': 'reagent_a',
          'reagentName': 'Reagent A',
          'category': 'Test',
        },
        {
          'id': 'reagent_a', // Duplicate ID
          'reagentName': 'Reagent A Duplicate',
          'category': 'Test',
        },
        {
          'id': 'reagent_b',
          'reagentName': 'Reagent B',
          'category': 'Test',
        }
      ];

      // Perform deduplication like UnifiedDataService.loadPipeline
      final unique = <String, ReagentTestModel>{};
      for (final reagentJson in list) {
        final reagent = ReagentTestModel.fromJson(reagentJson);
        unique[reagent.id] = reagent;
      }
      final reagentsList = unique.values.toList();

      expect(reagentsList.length, 2);
      expect(reagentsList[0].id, 'reagent_a');
      expect(reagentsList[0].reagentName, 'Reagent A Duplicate'); // Overwritten by last duplicate
      expect(reagentsList[1].id, 'reagent_b');
    });

    test('ValidationProfile.strict throws or skips on missing soft fields', () {
      final jsonNoInstructions = {
        'id': 'strict_test_reagent',
        'reagentName': 'Strict Test Reagent',
        'category': 'Screening',
        'testInstructions': <dynamic>[],
        'reactionResults': [
          {'analyteName': 'Analyte X', 'color': '#FF0000'}
        ],
        'references': ['Ref 1']
      };

      // 1. Direct Model instantiation with ValidationProfile.strict should throw DatasetParsingException
      expect(
        () => ReagentTestModel.fromJson(jsonNoInstructions, profile: ValidationProfile.strict),
        throwsA(isA<DatasetParsingException>()),
      );

      // 2. Direct Model instantiation with ValidationProfile.balanced should succeed (just logs warning)
      final model = ReagentTestModel.fromJson(jsonNoInstructions, profile: ValidationProfile.balanced);
      expect(model.id, 'strict_test_reagent');

      // 3. parseScientificDatasetIsolate with ValidationProfile.strict skips this reagent
      final datasetJson = jsonEncode({
        'version': '1.0.0',
        'reagents': [jsonNoInstructions]
      });

      final output = parseScientificDatasetIsolate(ParseParams(datasetJson, ValidationProfile.strict));
      expect(output.parsedReagents, isEmpty);
      expect(output.skippedItemsCount, 1);
    });

    test('Budgets: Payload size (>5MB), reagent count (>500), and reference count (>1000) are rejected', () {
      // 1. Payload size > 5MB
      final hugePayload = 'x' * (5 * 1024 * 1024 + 1);
      final sizeOutput = parseScientificDatasetIsolate(ParseParams(hugePayload, ValidationProfile.balanced));
      expect(sizeOutput.parsedReagents, isEmpty);
      expect(sizeOutput.error, contains('Payload size exceeds budget'));

      // 2. Reagent count > 500
      final manyReagents = List.generate(501, (index) => {
        'id': 'reagent_$index',
        'reagentName': 'Reagent $index',
        'category': 'Screening',
      });
      final countJson = jsonEncode({
        'version': '1.0.0',
        'reagents': manyReagents,
      });
      final countOutput = parseScientificDatasetIsolate(ParseParams(countJson, ValidationProfile.balanced));
      expect(countOutput.parsedReagents, isEmpty);
      expect(countOutput.error, contains('Reagent count exceeds budget'));

      // 3. Reference count > 1000
      final reagentWithManyRefs = {
        'id': 'reagent_many_refs',
        'reagentName': 'Reagent Many Refs',
        'category': 'Screening',
        'references': List.generate(1001, (index) => 'Ref $index'),
      };
      final refJson = jsonEncode({
        'version': '1.0.0',
        'reagents': [reagentWithManyRefs],
      });
      final refOutput = parseScientificDatasetIsolate(ParseParams(refJson, ValidationProfile.balanced));
      expect(refOutput.parsedReagents, isEmpty);
      expect(refOutput.error, contains('Total references exceed budget'));
    });

    test('Gzip compression and decompression round-trip', () {
      final service = UnifiedDataService();
      const originalText = '{"key": "value", "description": "some scientific text to compress"}';
      
      final compressed = service.compressGzip(originalText);
      expect(compressed, isNotEmpty);
      expect(compressed, isNot(equals(originalText)));

      final decompressed = service.decompressGzip(compressed);
      expect(decompressed, equals(originalText));
    });

    test('Sorts reagents alphabetically by ID deterministically', () {
      final list = [
        {
          'id': 'zeta_reagent',
          'reagentName': 'Zeta Reagent',
          'category': 'Test',
        },
        {
          'id': 'alpha_reagent',
          'reagentName': 'Alpha Reagent',
          'category': 'Test',
        },
        {
          'id': 'beta_reagent',
          'reagentName': 'Beta Reagent',
          'category': 'Test',
        }
      ];

      final reagents = list.map((e) => ReagentTestModel.fromJson(e, profile: ValidationProfile.permissive)).toList();
      expect(reagents[0].id, 'zeta_reagent');
      expect(reagents[1].id, 'alpha_reagent');
      expect(reagents[2].id, 'beta_reagent');

      // Sort alphabetically by ID
      reagents.sort((a, b) => a.id.compareTo(b.id));

      expect(reagents[0].id, 'alpha_reagent');
      expect(reagents[1].id, 'beta_reagent');
      expect(reagents[2].id, 'zeta_reagent');
    });
  });

  group('Safe Parsers Logic Tests', () {
    test('safeEnum parses values correctly, case insensitively, and handles nulls', () {
      final values = _TestEnum.values;

      expect(safeEnum(values, 'firstOption'), _TestEnum.firstOption);
      expect(safeEnum(values, 'SECONDOPTION'), _TestEnum.secondOption);
      expect(safeEnum(values, 'thirdOption'), _TestEnum.thirdOption);
      expect(safeEnum(values, 'nonExistent'), isNull);
      expect(safeEnum(values, null), isNull);
    });

    test('SafeColorParser supports various formats and fallback to grey on failure', () {
      // Hex formats
      final colorHex1 = SafeColorParser.parseRobustColor('#FF0000');
      expect(colorHex1.r, 255);
      expect(colorHex1.g, 0);
      expect(colorHex1.b, 0);

      final colorHex2 = SafeColorParser.parseRobustColor('FF0000');
      expect(colorHex2.r, 255);
      expect(colorHex2.g, 0);
      expect(colorHex2.b, 0);

      final colorHex3 = SafeColorParser.parseRobustColor('0xFFFF0000');
      expect(colorHex3.r, 255);
      expect(colorHex3.g, 0);
      expect(colorHex3.b, 0);

      // RGB Format
      final colorRgb1 = SafeColorParser.parseRobustColor('rgb(0, 255, 0)');
      expect(colorRgb1.r, 0);
      expect(colorRgb1.g, 255);
      expect(colorRgb1.b, 0);

      final colorRgb2 = SafeColorParser.parseRobustColor('rgb(  0  ,  255  ,  0  )');
      expect(colorRgb2.r, 0);
      expect(colorRgb2.g, 255);
      expect(colorRgb2.b, 0);

      // Color Matcher fallback
      final colorRed = SafeColorParser.parseRobustColor('red');
      expect(colorRed.r, 255);
      expect(colorRed.g, 0);
      expect(colorRed.b, 0);

      // Invalid input fallback to grey (128, 128, 128)
      final colorInvalid = SafeColorParser.parseRobustColor('invalid-color-value');
      expect(colorInvalid.r, 128);
      expect(colorInvalid.g, 128);
      expect(colorInvalid.b, 128);

      final colorEmpty = SafeColorParser.parseRobustColor('');
      expect(colorEmpty.r, 128);
      expect(colorEmpty.g, 128);
      expect(colorEmpty.b, 128);
    });

    test('SafeJsonParser coercion methods are resilient', () {
      expect(SafeJsonParser.safeString(123), '123');
      expect(SafeJsonParser.safeString(null, 'default'), 'default');

      expect(SafeJsonParser.safeInt('456'), 456);
      expect(SafeJsonParser.safeInt(null, 9), 9);
      expect(SafeJsonParser.safeInt('not-an-int', 10), 10);

      expect(SafeJsonParser.safeDouble('45.67'), 45.67);
      expect(SafeJsonParser.safeDouble(null, 1.2), 1.2);

      expect(SafeJsonParser.safeList<String>(['a', 'b']), ['a', 'b']);
      expect(SafeJsonParser.safeList<String>(null), isEmpty);
      // Handles list mapping when element types are mismatched
      expect(SafeJsonParser.safeList<String>([123, 456]), ['123', '456']);
    });
  });
}

enum _TestEnum { firstOption, secondOption, thirdOption }
