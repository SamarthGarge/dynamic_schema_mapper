// Dynamic Backend Schema Mapper
//
// A Flutter/Dart package that automatically adapts to evolving backend JSON
// structures without requiring manual model class updates.
//
// Features:
// - Zero model classes needed
// - Type-safe access to JSON fields
// - Automatic schema change detection
// - Support for nested objects and lists
// - Optional local schema caching
//
// Example:
// ```dart
// final schema = DynamicSchema.parse(jsonResponse);
// final name = schema.getString('name');
// final age = schema.getInt('age');
//
// // Access nested data
// final address = schema.getNested('address');
// final city = address?.getString('city');
//
// // Access lists
// final items = schema.getList('items');
// for (final item in items) {
//   print(item.getString('name'));
// }
// ```

// Core exports
export 'src/dynamic_schema.dart';
export 'src/schema_node.dart';
export 'src/schema_parser.dart';
export 'src/schema_diff.dart';

// Optional exports
export 'src/cache_manager.dart';
