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
