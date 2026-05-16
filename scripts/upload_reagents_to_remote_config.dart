import 'dart:convert';
import 'dart:io';

/// Script to upload reagent data to Firebase Remote Config
///
/// This script reads all reagent JSON files and creates the proper
/// Remote Config parameters for uploading via Firebase Console
Future<void> main() async {
  print('🚀 Starting reagent data upload preparation...');

  final reagentDirectory = Directory('../assets/data/reagents');
  final reagentFiles = reagentDirectory
      .listSync()
      .where((file) => file.path.endsWith('_reagent.json'))
      .cast<File>()
      .toList();

  if (reagentFiles.isEmpty) {
    print('❌ No reagent files found in ${reagentDirectory.path}');
    return;
  }

  print('📁 Found ${reagentFiles.length} reagent files');

  final Map<String, dynamic> reagentData = {};
  final List<String> availableReagents = [];

  // Process each reagent file
  for (final file in reagentFiles) {
    try {
      final content = await file.readAsString();
      final reagentJson = jsonDecode(content) as Map<String, dynamic>;
      final reagentName = reagentJson['reagentName'] as String;

      reagentData[reagentName] = reagentJson;
      availableReagents.add(reagentName);

      print('✅ Processed: $reagentName');
    } catch (e) {
      print('❌ Error processing ${file.path}: $e');
    }
  }

  // Sort reagents alphabetically
  availableReagents.sort();

  // Create Remote Config parameters
  final remoteConfigData = {
    'reagent_data': jsonEncode(reagentData),
    'available_reagents': jsonEncode(availableReagents),
    'reagent_version': '1.0.0',
  };

  // Write to output file for Firebase Console upload
  final outputFile = File('remote_config_parameters.json');
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(remoteConfigData),
  );

  print('\n🎉 Remote Config data prepared successfully!');
  print('📄 Output file: ${outputFile.absolute.path}');
  print('\n📋 Next steps:');
  print('1. Go to Firebase Console > Remote Config');
  print('2. Create these parameters:');
  print('   - reagent_data (JSON)');
  print('   - available_reagents (JSON)');
  print('   - reagent_version (String)');
  print('3. Copy values from remote_config_parameters.json');
  print('4. Publish the configuration');

  print('\n📊 Summary:');
  print('   - Total reagents: ${availableReagents.length}');
  print('   - Reagents: ${availableReagents.join(', ')}');
  print(
    '   - Data size: ${(jsonEncode(reagentData).length / 1024).toStringAsFixed(1)} KB',
  );

  // Create individual parameter files for easier copying
  await _createIndividualParameterFiles(remoteConfigData);

  print('\n✅ Individual parameter files created for easy copying!');
}

/// Create individual files for each Remote Config parameter
Future<void> _createIndividualParameterFiles(Map<String, dynamic> data) async {
  final outputDir = Directory('remote_config_output');
  if (!await outputDir.exists()) {
    await outputDir.create();
  }

  for (final entry in data.entries) {
    final file = File('${outputDir.path}/${entry.key}.json');

    if (entry.value is String) {
      // For JSON strings, write them as formatted JSON
      if (entry.key == 'reagent_data' || entry.key == 'available_reagents') {
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
}
