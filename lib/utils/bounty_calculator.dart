import 'constants.dart';

// ============================================================
// Ngam App — Algorithmic Bounty Matrix
// Enforces minimum task payouts based on category complexity
// ============================================================

class BountyCalculator {
  /// Minimum bounty amounts (RM) per category
  static final Map<String, double> _minimumBounty = {
    TaskCategory.food: 3.00,
    TaskCategory.shopping: 5.00,
    TaskCategory.print: 2.00,
    TaskCategory.heavy: 8.00,
    TaskCategory.parcel: 4.00,
    TaskCategory.cleaning: 15.00,
    TaskCategory.petCare: 10.00,
    TaskCategory.errands: 5.00,
    TaskCategory.automotive: 10.00,
    TaskCategory.others: 5.00,
  };

  /// Returns the minimum bounty for a given category
  static double getMinimum(String category) {
    return _minimumBounty[category] ?? 3.00;
  }

  /// Validates whether the offered bounty meets the minimum threshold
  static bool isValid(String category, double offeredAmount) {
    return offeredAmount >= getMinimum(category);
  }

  /// Returns a formatted error message if the bounty is too low
  static String? validate(String category, double offeredAmount) {
    final minimum = getMinimum(category);
    if (offeredAmount < minimum) {
      return 'Minimum bounty for $category is RM ${minimum.toStringAsFixed(2)}';
    }
    return null;
  }

  /// Returns a suggested bounty based on category (slightly above minimum)
  static double suggestedBounty(String category) {
    return getMinimum(category) + 1.00;
  }

  /// Returns all minimum bounties as a formatted map for display
  static Map<String, String> getAllMinimums() {
    return _minimumBounty.map(
      (key, value) => MapEntry(key, 'RM ${value.toStringAsFixed(2)}'),
    );
  }
}
