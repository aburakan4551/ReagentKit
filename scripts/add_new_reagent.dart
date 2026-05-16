import 'dart:convert';
import 'dart:io';

/// Script to add a new reagent to the Remote Config data
/// Usage: dart add_new_reagent.dart reagent_file.json
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: dart add_new_reagent.dart <reagent_file.json>');
    print('Example: dart add_new_reagent.dart benedict_reagent.json');
    return;
  }

  final newReagentFile = args[0];
  print('🚀 Adding new reagent from: $newReagentFile');

  // Read the new reagent file
  final reagentFile = File(newReagentFile);
  if (!await reagentFile.exists()) {
    print('❌ Reagent file not found: $newReagentFile');
    return;
  }

  try {
    // Parse new reagent
    final newReagentContent = await reagentFile.readAsString();
    final newReagentJson =
        jsonDecode(newReagentContent) as Map<String, dynamic>;
    final reagentName = newReagentJson['reagentName'] as String;

    print('✅ Parsed new reagent: $reagentName');

    // Read existing Remote Config data
    final existingDataFile = File('remote_config_output/reagent_data.json');
    final existingAvailableFile = File(
      'remote_config_output/available_reagents.json',
    );

    if (!await existingDataFile.exists() ||
        !await existingAvailableFile.exists()) {
      print(
        '❌ Remote Config files not found. Run upload_reagents_to_remote_config.dart first.',
      );
      return;
    }

    // Update reagent data
    final existingDataContent = await existingDataFile.readAsString();
    final existingData =
        jsonDecode(existingDataContent) as Map<String, dynamic>;

    // Add new reagent
    existingData[reagentName] = newReagentJson;

    // Update available reagents list
    final existingAvailableContent = await existingAvailableFile.readAsString();
    final availableReagents = List<String>.from(
      jsonDecode(existingAvailableContent),
    );

    if (!availableReagents.contains(reagentName)) {
      availableReagents.add(reagentName);
      availableReagents.sort(); // Keep alphabetical order
    }

    // Write updated files
    await existingDataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(existingData),
    );

    await existingAvailableFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(availableReagents),
    );

    // Update version
    final versionFile = File('remote_config_output/reagent_version.json');
    final currentVersion = await versionFile.readAsString();
    final versionParts = currentVersion.trim().split('.');
    final newMinorVersion = int.parse(versionParts[1]) + 1;
    final newVersion = '${versionParts[0]}.$newMinorVersion.${versionParts[2]}';

    await versionFile.writeAsString(newVersion);

    print('\n🎉 Successfully added reagent: $reagentName');
    print('📊 Updated files:');
    print('   - reagent_data.json (${existingData.length} reagents)');
    print(
      '   - available_reagents.json (${availableReagents.length} reagents)',
    );
    print('   - reagent_version.json ($newVersion)');

    print('\n📋 Next steps:');
    print('1. Copy updated content from remote_config_output/ files');
    print('2. Update Firebase Console Remote Config parameters');
    print('3. Publish changes in Firebase Console');
    print('4. New reagent will appear in your app automatically!');

    // Create a summary file for easy copying
    final summaryFile = File('remote_config_output/update_summary.txt');
    await summaryFile.writeAsString('''
🎉 REAGENT ADDED: $reagentName

📋 FIREBASE CONSOLE UPDATES NEEDED:

1. reagent_data parameter:
   - Copy content from: remote_config_output/reagent_data.json
   
2. available_reagents parameter:
   - Copy content from: remote_config_output/available_reagents.json
   
3. reagent_version parameter:
   - Update to: $newVersion

4. Click "Publish changes" in Firebase Console

✅ Total reagents: ${availableReagents.length}
✅ New version: $newVersion
✅ Added: $reagentName
''');

    print('\n📄 Summary saved to: remote_config_output/update_summary.txt');
  } catch (e) {
    print('❌ Error adding reagent: $e');
  }
}
