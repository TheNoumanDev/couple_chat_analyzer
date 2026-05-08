import 'package:flutter/foundation.dart';

/// Helper class for safe type conversions.
/// Used across insight widgets to safely convert dynamic data types.
class SafeTypeConverter {
  /// Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> convertToStringMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        final result = <String, dynamic>{};
        data.forEach((key, value) {
          final stringKey = key.toString();
          // Recursively convert nested maps
          if (value is Map && value is! Map<String, dynamic>) {
            result[stringKey] = convertToStringMap(value);
          } else if (value is List) {
            result[stringKey] = convertList(value);
          } else {
            result[stringKey] = value;
          }
        });
        return result;
      } catch (e) {
        debugPrint('SafeTypeConverter: Error converting map: $e');
        return {};
      }
    }
    debugPrint('SafeTypeConverter: Data is not a map, type: ${data.runtimeType}');
    return {};
  }

  /// Safely convert List with nested maps
  static List<dynamic> convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map && item is! Map<String, dynamic>) {
        return convertToStringMap(item);
      }
      return item;
    }).toList();
  }

  /// Safe integer extraction
  static int safeInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safe string extraction
  static String safeString(dynamic value, {String defaultValue = ''}) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return defaultValue;
  }

  /// Safe list extraction
  static List<dynamic> safeList(dynamic value) {
    if (value is List) return value;
    if (value == null) return [];
    return [value]; // Wrap single item in list
  }
}
