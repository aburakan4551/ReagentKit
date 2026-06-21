import 'dart:convert';
import 'dart:io';

/// Script to upload reorganized reagent data to Firebase Remote Config
///
/// This script uploads the new structure with separate safety instructions
Future<void> main() async {
  print('🚀 Starting reagent data upload preparation with new structure...');

  // Read the updated reagent data (without safety fields)
  final reagentDataFile = File(
    'remote_config_output/reagent_data_updated.json',
  );
  final safetyInstructionsFile = File(
    'remote_config_output/safety_instructions.json',
  );
  final availableReagentsFile = File(
    'remote_config_output/available_reagents.json',
  );

  if (!await reagentDataFile.exists()) {
    print('❌ reagent_data_updated.json not found');
    return;
  }

  if (!await safetyInstructionsFile.exists()) {
    print('❌ safety_instructions.json not found');
    return;
  }

  try {
    // Read all data files
    final reagentDataContent = await reagentDataFile.readAsString();
    final safetyInstructionsContent = await safetyInstructionsFile
        .readAsString();

    final reagentData = jsonDecode(reagentDataContent) as Map<String, dynamic>;
    final safetyInstructions =
        jsonDecode(safetyInstructionsContent) as Map<String, dynamic>;

    // Read available reagents
    List<String> availableReagents = [];
    if (await availableReagentsFile.exists()) {
      final availableReagentsContent = await availableReagentsFile
          .readAsString();
      availableReagents = List<String>.from(
        jsonDecode(availableReagentsContent),
      );
    } else {
      // Generate from reagent data
      availableReagents = reagentData.keys.toList()..sort();
    }

    print('✅ Loaded ${reagentData.length} reagents');
    print(
      '✅ Loaded safety instructions for ${safetyInstructions.length} reagents',
    );

    // Create Remote Config parameters
    final remoteConfigData = {
      'reagent_data': jsonEncode(reagentData),
      'safety_instructions': jsonEncode(safetyInstructions),
      'available_reagents': jsonEncode(availableReagents),
      'reagent_version': '2.0.0', // Updated version for new structure
    };

    // Write to output file for Firebase Console upload
    final outputFile = File('remote_config_parameters_new.json');
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(remoteConfigData),
    );

    print('\n🎉 Remote Config data prepared successfully!');
    print('📄 Output file: ${outputFile.absolute.path}');
    print('\n📋 Next steps:');
    print('1. Go to Firebase Console > Remote Config');
    print('2. Update these parameters:');
    print('   - reagent_data (JSON) - Updated without safety fields');
    print(
      '   - safety_instructions (JSON) - NEW parameter with Arabic translations',
    );
    print('   - available_reagents (JSON) - Unchanged');
    print('   - reagent_version (String) - Update to 2.0.0');
    print('3. Copy values from remote_config_parameters_new.json');
    print('4. Publish the configuration');

    print('\n📊 Summary:');
    print('   - Total reagents: ${availableReagents.length}');
    print('   - Reagents: ${availableReagents.join(', ')}');
    print(
      '   - Reagent data size: ${(jsonEncode(reagentData).length / 1024).toStringAsFixed(1)} KB',
    );
    print(
      '   - Safety data size: ${(jsonEncode(safetyInstructions).length / 1024).toStringAsFixed(1)} KB',
    );
    print(
      '   - Total size: ${((jsonEncode(reagentData).length + jsonEncode(safetyInstructions).length) / 1024).toStringAsFixed(1)} KB',
    );

    // Create individual parameter files for easier copying
    await _createIndividualParameterFiles(remoteConfigData);

    print('\n✅ Individual parameter files created for easy copying!');
    print('\n🔄 Migration Notes:');
    print('   - Safety fields removed from reagent_data');
    print('   - All safety information moved to safety_instructions parameter');
    print('   - Arabic translations added for all safety fields');
    print('   - Version bumped to 2.0.0 to indicate breaking change');
  } catch (e) {
    print('❌ Error processing files: $e');
  }
}

/// Create individual files for each Remote Config parameter
Future<void> _createIndividualParameterFiles(Map<String, dynamic> data) async {
  final outputDir = Directory('remote_config_output');
  if (!await outputDir.exists()) {
    await outputDir.create();
  }

  for (final entry in data.entries) {
    final fileName = '${entry.key}_new.json';
    final file = File('${outputDir.path}/$fileName');

    if (entry.value is String) {
      // For JSON strings, write them as formatted JSON
      if (entry.key == 'reagent_data' ||
          entry.key == 'available_reagents' ||
          entry.key == 'safety_instructions') {
        final decodedJson = jsonDecode(entry.value as String);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(decodedJson),
        );
      } else {
        // For simple strings
        await file.writeAsString(entry.value as String);
      }
    } else {
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(entry.value),
      );
    }

    print('📄 Created: ${file.path}');
  }

  // Also create a comparison summary
  final summaryFile = File('${outputDir.path}/migration_summary.md');
  await summaryFile.writeAsString(_createMigrationSummary());
  print('📄 Created migration summary: ${summaryFile.path}');
}

String _createMigrationSummary() {
  return '''
# Remote Config Migration Summary

## Changes Made

### 1. Data Structure Reorganization
- **Before**: All data including safety information in `reagent_data` parameter
- **After**: Safety information separated into `safety_instructions` parameter

### 2. New Parameters
- `safety_instructions` - Contains all safety-related fields with Arabic translations
  - equipment / equipment_ar
  - handlingProcedures / handlingProcedures_ar
  - specificHazards / specificHazards_ar
  - storage / storage_ar
  - instructions / instructions_ar

### 3. Updated Parameters
- `reagent_data` - Now contains only core reagent information (name, description, chemicals, drugResults, etc.)
- `reagent_version` - Bumped to 2.0.0

### 4. Arabic Localization
- All safety fields now have Arabic translations
- Field naming convention: `fieldName` and `fieldName_ar`

## Firebase Console Steps

1. Go to Firebase Console > Remote Config
2. Add new parameter: `safety_instructions` (JSON type)
3. Update existing parameter: `reagent_data` (remove safety fields)
4. Update `reagent_version` to "2.0.0"
5. Publish changes

## App Code Updates Required

The app will need to be updated to:
1. Fetch safety instructions from the new `safety_instructions` parameter
2. Handle the new Arabic translation fields
3. Update version checking logic for 2.0.0

## Benefits

- Cleaner separation of concerns
- Full Arabic localization support
- Better maintainability
- Reduced size of main reagent data parameter
''';
}
