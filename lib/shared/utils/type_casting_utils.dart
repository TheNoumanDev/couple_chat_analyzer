// ============================================================================
// FILE: lib/shared/utils/type_casting_utils.dart
// Safe type casting utilities to handle Map<dynamic, dynamic> conversions
// ============================================================================

/// Utility class for safe type casting between dynamic and typed maps
class TypeCastingUtils {
  
  /// Safely cast Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> castToStringMap(dynamic input) {
    if (input == null) return <String, dynamic>{};
    
    if (input is Map<String, dynamic>) {
      return input;
    }
    
    if (input is Map<dynamic, dynamic>) {
      return _convertMapToStringKeys(input);
    }
    
    // Fallback for unexpected types
    return <String, dynamic>{};
  }

  /// Safely cast to List<dynamic> and handle nested maps
  static List<dynamic> castToList(dynamic input) {
    if (input == null) return <dynamic>[];
    
    if (input is List<dynamic>) {
      return _convertListItems(input);
    }
    
    if (input is List) {
      return _convertListItems(input.cast<dynamic>());
    }
    
    return <dynamic>[];
  }

  /// Recursively convert Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> _convertMapToStringKeys(Map<dynamic, dynamic> input) {
    final result = <String, dynamic>{};
    
    input.forEach((key, value) {
      final stringKey = key.toString();
      
      if (value is Map<dynamic, dynamic>) {
        result[stringKey] = _convertMapToStringKeys(value);
      } else if (value is List) {
        result[stringKey] = _convertListItems(value);
      } else {
        result[stringKey] = value;
      }
    });
    
    return result;
  }

  /// Convert list items, handling nested maps
  static List<dynamic> _convertListItems(List<dynamic> input) {
    return input.map((item) {
      if (item is Map<dynamic, dynamic>) {
        return _convertMapToStringKeys(item);
      } else if (item is List) {
        return _convertListItems(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Safe getter for map values with type conversion
  static T? safeGet<T>(Map<String, dynamic> map, String key, {T? fallback}) {
    try {
      final value = map[key];
      if (value == null) return fallback;
      
      // Handle specific type conversions
      if (T == String) {
        return value.toString() as T;
      } else if (T == int) {
        if (value is int) return value as T;
        if (value is double) return value.toInt() as T;
        if (value is String) return int.tryParse(value) as T?;
        return fallback;
      } else if (T == double) {
        if (value is double) return value as T;
        if (value is int) return value.toDouble() as T;
        if (value is String) return double.tryParse(value) as T?;
        return fallback;
      } else if (T == bool) {
        if (value is bool) return value as T;
        if (value is String) return (value.toLowerCase() == 'true') as T;
        return fallback;
      }
      
      return value as T?;
    } catch (e) {
      return fallback;
    }
  }

  /// Safe double getter - handles int to double conversion
  static double? safeGetDouble(Map<String, dynamic> map, String key, {double? fallback}) {
    try {
      final value = map[key];
      if (value == null) return fallback;
      
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      
      return fallback;
    } catch (e) {
      return fallback;
    }
  }

  /// Safe int getter - handles double to int conversion
  static int? safeGetInt(Map<String, dynamic> map, String key, {int? fallback}) {
    try {
      final value = map[key];
      if (value == null) return fallback;
      
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      
      return fallback;
    } catch (e) {
      return fallback;
    }
  }

  /// Extract data from analysis results with safe casting
  static Map<String, dynamic> extractAnalysisData(Map<String, dynamic> results, String key) {
    final data = results[key];
    
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map<dynamic, dynamic>) {
      return castToStringMap(data);
    }
    
    return <String, dynamic>{};
  }

  /// Extract list data from analysis results with safe casting
  static List<dynamic> extractAnalysisList(Map<String, dynamic> results, String key) {
    final data = results[key];
    return castToList(data);
  }
}