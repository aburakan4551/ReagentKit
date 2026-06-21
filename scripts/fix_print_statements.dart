#!/usr/bin/env dart

import 'dart:io';

void main() async {
  final files = [
    'lib/core/services/firestore_service.dart',
    'lib/core/services/auth_service.dart',
    'lib/features/auth/presentation/controllers/auth_controller.dart',
    'lib/features/auth/presentation/views/firestore_debug_page.dart',
    'lib/features/reagent_testing/data/repositories/test_result_history_repository.dart',
    'lib/features/reagent_testing/data/services/json_data_service.dart',
    'lib/features/reagent_testing/data/services/remote_config_service.dart',
    'lib/features/reagent_testing/presentation/providers/reagent_testing_providers.dart',
    'lib/features/reagent_testing/presentation/controllers/test_result_history_controller.dart',
  ];

  for (final filePath in files) {
    await fixPrintStatements(filePath);
  }
}

Future<void> fixPrintStatements(String filePath) async {
  try {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('File not found: $filePath');
      return;
    }

    String content = await file.readAsString();

    // Add Logger import if not present
    if (!content.contains("import '../../core/utils/logger.dart'") &&
        !content.contains("import '../../../core/utils/logger.dart'") &&
        !content.contains("import '../../../../core/utils/logger.dart'")) {
      // Find the right import path based on file location
      String importPath;
      if (filePath.contains('lib/core/')) {
        importPath = "import '../utils/logger.dart';";
      } else if (filePath.contains('lib/features/')) {
        final depth = filePath.split('/').length - 2; // lib + features = 2
        final backPath = '../' * (depth - 2);
        importPath = "import '${backPath}core/utils/logger.dart';";
      } else {
        importPath = "import '../../core/utils/logger.dart';";
      }

      // Add import after other imports
      final lines = content.split('\n');
      int insertIndex = 0;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('import ') ||
            lines[i].startsWith("import '") ||
            lines[i].startsWith('import "')) {
          insertIndex = i + 1;
        } else if (lines[i].trim().isEmpty && insertIndex > 0) {
          break;
        }
      }

      lines.insert(insertIndex, importPath);
      content = lines.join('\n');
    }

    // Replace print statements with Logger calls
    content = content.replaceAllMapped(
      RegExp(r"print\('([^']*(?:\\'[^']*)*)'\);"),
      (match) {
        final message = match.group(1)!;
        if (message.startsWith('❌') ||
            message.contains('Error') ||
            message.contains('Failed')) {
          return "Logger.error('$message');";
        } else if (message.startsWith('⚠️') || message.contains('Warning')) {
          return "Logger.warning('$message');";
        } else if (message.startsWith('🔧') || message.contains('Debug')) {
          return "Logger.debug('$message');";
        } else {
          return "Logger.info('$message');";
        }
      },
    );

    // Handle double-quoted print statements
    content = content.replaceAllMapped(
      RegExp(r'print\("([^"]*(?:\\"[^"]*)*)"\);'),
      (match) {
        final message = match.group(1)!;
        if (message.startsWith('❌') ||
            message.contains('Error') ||
            message.contains('Failed')) {
          return 'Logger.error("$message");';
        } else if (message.startsWith('⚠️') || message.contains('Warning')) {
          return 'Logger.warning("$message");';
        } else if (message.startsWith('🔧') || message.contains('Debug')) {
          return 'Logger.debug("$message");';
        } else {
          return 'Logger.info("$message");';
        }
      },
    );

    // Handle print statements with variables
    content = content.replaceAllMapped(RegExp(r"print\('([^']*\$[^']*)'\);"), (
      match,
    ) {
      final message = match.group(1)!;
      if (message.startsWith('❌') ||
          message.contains('Error') ||
          message.contains('Failed')) {
        return "Logger.error('$message');";
      } else if (message.startsWith('⚠️') || message.contains('Warning')) {
        return "Logger.warning('$message');";
      } else if (message.startsWith('🔧') || message.contains('Debug')) {
        return "Logger.debug('$message');";
      } else {
        return "Logger.info('$message');";
      }
    });

    await file.writeAsString(content);
    print('✅ Fixed print statements in: $filePath');
  } catch (e) {
    print('❌ Error processing $filePath: $e');
  }
}
