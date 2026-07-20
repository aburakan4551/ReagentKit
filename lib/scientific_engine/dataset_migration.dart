import 'dart:developer' as developer;

class DatasetLineage {
  final String parentDataset;
  final List<String> migrationsApplied;

  const DatasetLineage({
    required this.parentDataset,
    required this.migrationsApplied,
  });

  Map<String, dynamic> toJson() => {
        'parentDataset': parentDataset,
        'migrationsApplied': migrationsApplied,
      };

  @override
  String toString() {
    return 'DatasetLineage(parent: $parentDataset, migrations: $migrationsApplied)';
  }
}

abstract class DatasetMigration {
  bool canMigrate(String version);
  Map<String, dynamic> migrate(Map<String, dynamic> json);
}

class DatasetMigrator {
  final List<DatasetMigration> migrations;
  const DatasetMigrator(this.migrations);

  /// Performs sequential migrations and returns the migrated Map along with migration names applied.
  (Map<String, dynamic>, List<String>) migrate(Map<String, dynamic> json) {
    var currentJson = Map<String, dynamic>.from(json);
    var version = _getVersion(currentJson);
    final List<String> applied = [];

    for (final migration in migrations) {
      if (migration.canMigrate(version)) {
        final migrationName = migration.runtimeType.toString();
        developer.log('Applying dataset migration: $migrationName from version $version', name: 'DatasetMigrator');
        currentJson = migration.migrate(currentJson);
        applied.add(migrationName);
        version = _getVersion(currentJson);
      }
    }
    return (currentJson, applied);
  }

  static String _getVersion(Map<String, dynamic> json) {
    return (json['dataset_version'] ??
            json['schemaVersion'] ??
            json['databaseVersion'] ??
            json['version'] ??
            'unknown')
        .toString();
  }
}

class LegacyToV1Migration implements DatasetMigration {
  const LegacyToV1Migration();

  @override
  bool canMigrate(String version) =>
      version == 'unknown' || version.isEmpty || version == '0.0.1' || version == '0.1.0';

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    // Standardize version tags to 'version'
    copy['version'] = '1.0.0';
    copy['dataset_version'] = '1.0.0';
    
    // Perform safety structural standardizations if any keys are missing.
    // If there is no top-level 'reagents' key, the JSON is flat format:
    // every top-level key IS a reagent. Wrap them into the 'reagents' map.
    if (!copy.containsKey('reagents')) {
      // Collect all known non-reagent metadata keys to skip
      const metaKeys = {
        'version', 'dataset_version', 'schemaVersion', 'databaseVersion',
        'author', 'generatedAt', 'scientificRevision', 'expiresAt',
        'description', 'license',
      };
      final reagentsMap = <String, dynamic>{};
      for (final key in copy.keys) {
        if (!metaKeys.contains(key) && copy[key] is Map<String, dynamic>) {
          reagentsMap[key] = copy[key];
        }
      }
      // Remove all reagent keys from root and nest them under 'reagents'
      for (final key in reagentsMap.keys) {
        copy.remove(key);
      }
      copy['reagents'] = reagentsMap;
    }
    return copy;
  }
}
