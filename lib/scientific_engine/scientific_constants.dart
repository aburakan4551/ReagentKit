class ScientificConstants {
  // Algorithm & Versioning Details
  static const String algorithmVersion = '1.0.0';
  static const String datasetVersion = '1.0.0';

  // Confidence scoring thresholds
  static const double confidenceThresholdLow = 0.50;      // Below this is insufficient confidence
  static const double confidenceThresholdModerate = 0.75; // Between 0.50 and 0.75 is moderate
  static const double confidenceThresholdHigh = 0.90;     // Above 0.90 is high

  // Delta E (Color Difference) thresholds
  static const double deltaEPerfect = 2.0;       // Indistinguishable to human eye
  static const double deltaEGood = 5.0;          // Acceptable matching
  static const double deltaEAcceptable = 10.0;   // Noticeable difference but matching
  static const double deltaEMaxLimit = 15.0;     // Out of matching bounds

  // Lighting & Calibration standards
  static const double minAmbientBrightness = 0.3; // Scale of 0.0 to 1.0
  static const double maxCameraExposure = 0.8;    // Prevent overexposure
  static const double maxWhiteBalanceShift = 0.2; // Prevent color distortion

  // Safe limits
  static const int maxFreeTests = 3;
}
