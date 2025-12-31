// Simple utility class - most logic moved to the main engine
class FeatureProcessor {
  static double normalizeValue(double value, double maxValue) {
    return value.clamp(0.0, maxValue) / maxValue;
  }

  static double calculateSimilarity(double value1, double value2, double range) {
    final difference = (value1 - value2).abs();
    return 1.0 - (difference / range);
  }

  static String getCarTypeFromLabel(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('hatchback')) return 'hatchback';
    if (lowerLabel.contains('suv')) return 'suv';
    if (lowerLabel.contains('sedan')) return 'sedan';
    if (lowerLabel.contains('luxury')) return 'luxury';
    if (lowerLabel.contains('sports')) return 'sports';
    return 'standard';
  }
}