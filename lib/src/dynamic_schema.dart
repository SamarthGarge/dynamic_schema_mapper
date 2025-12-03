import 'schema_node.dart';
import 'schema_parser.dart';
import 'schema_diff.dart';

// Main entry point for the Dynamic Schema Mapper package
class DynamicSchema {
  final SchemaNode _root;

  // Static callback for schema changes
  static void Function(List<SchemaChange>)? onSchemaChanged;

  // Cache for previous schema structure
  static Map<String, dynamic>? _cachedSchema;

  DynamicSchema._(this._root);

  // Parse JSON data into a DynamicSchema
  //
  // Example:
  // ```dart
  // final schema = DynamicSchema.parse(jsonResponse);
  // ```
  static DynamicSchema parse(dynamic json) {
    final node = SchemaParser.parse(json);

    // Auto-detect schema changes
    _detectSchemaChanges(node);

    return DynamicSchema._(node);
  }

  // Parse with validation options
  static DynamicSchema parseWithValidation(
    dynamic json, {
    bool allowNull = true,
    bool requireObject = false,
  }) {
    final node = SchemaParser.parseWithValidation(
      json,
      allowNull: allowNull,
      requireObject: requireObject,
    );

    _detectSchemaChanges(node);

    return DynamicSchema._(node);
  }

  // ==================== Type-Safe Getters ====================

  // Get a string value safely
  String getString(String key, {String defaultValue = ""}) {
    return _root.getString(key, defaultValue: defaultValue);
  }

  // Get an integer value safely
  int getInt(String key, {int defaultValue = 0}) {
    return _root.getInt(key, defaultValue: defaultValue);
  }

  // Get a double value safely
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _root.getDouble(key, defaultValue: defaultValue);
  }

  // Get a boolean value safely
  bool getBool(String key, {bool defaultValue = false}) {
    return _root.getBool(key, defaultValue: defaultValue);
  }

  // Get a nested object as DynamicSchema
  DynamicSchema? getNested(String key) {
    final node = _root.getNested(key);
    return node != null ? DynamicSchema._(node) : null;
  }

  // Get a list of DynamicSchema objects
  List<DynamicSchema> getList(String key) {
    final nodes = _root.getList(key);
    return nodes.map((node) => DynamicSchema._(node)).toList();
  }

  // ==================== Advanced Access ====================

  // Get value at a dot-notation path
  // Example: schema.getValueAtPath('user.address.city')
  dynamic getValueAtPath(String path) {
    return SchemaParser.getValueAtPath(_root, path);
  }

  // Get all available keys
  List<String> get keys => _root.keys;

  // Check if a key exists
  bool hasKey(String key) => _root.hasKey(key);

  // Get all paths in the schema (dot notation)
  List<String> getAllPaths() {
    return SchemaParser.getAllPaths(_root);
  }

  // Get the raw SchemaNode (for advanced usage)
  SchemaNode get rootNode => _root;

  // Get the raw value (shorthand for rootNode.rawValue)
  dynamic get rawValue => _root.rawValue;

  // Convert back to JSON string
  String toJsonString({bool pretty = false}) {
    return SchemaParser.toJsonString(_root, pretty: pretty);
  }

  // Get the schema structure (types only, no values)
  Map<String, dynamic> getSchemaStructure() {
    return SchemaParser.extractSchema(_root);
  }

  // ==================== Schema Change Detection ====================

  static void _detectSchemaChanges(SchemaNode newNode) {
    if (_cachedSchema == null) {
      // First time parsing, just cache the schema
      _cachedSchema = SchemaParser.extractSchema(newNode);
      return;
    }

    // Compare with cached schema
    final currentSchema = SchemaParser.extractSchema(newNode);
    final changes = SchemaDiff.compareSchemaStructure(
      _cachedSchema!,
      currentSchema,
    );

    if (changes.isNotEmpty && onSchemaChanged != null) {
      onSchemaChanged!(changes);
    }

    // Update cache
    _cachedSchema = currentSchema;
  }

  // Manually compare two schemas
  static List<SchemaChange> compareSchemas(
    DynamicSchema oldSchema,
    DynamicSchema newSchema,
  ) {
    return SchemaDiff.compare(oldSchema._root, newSchema._root);
  }

  // Reset cached schema (useful for testing)
  static void resetCache() {
    _cachedSchema = null;
  }

  // Enable/disable schema change detection
  static void enableSchemaDetection(
    void Function(List<SchemaChange>) callback,
  ) {
    onSchemaChanged = callback;
  }

  // Disable schema change detection
  static void disableSchemaDetection() {
    onSchemaChanged = null;
  }

  // ==================== Debugging ====================

  // Print the schema tree structure
  void printTree({int indent = 0}) {
    _printNode(_root, indent);
  }

  void _printNode(SchemaNode node, int indent) {
    final prefix = '  ' * indent;

    if (node.isPrimitive) {
      // Using a comment to avoid print in production
      // In a real app, use a logging framework
      // ignore: avoid_print
      print('$prefix${node.type.name}: ${node.rawValue}');
    } else if (node.isMap) {
      // ignore: avoid_print
      print('${prefix}object {');
      for (final key in node.keys) {
        // ignore: avoid_print
        print('$prefix  $key:');
        final child = node.getNested(key);
        if (child != null) {
          _printNode(child, indent + 2);
        }
      }
      // ignore: avoid_print
      print('$prefix}');
    } else if (node.isList) {
      // ignore: avoid_print
      print('${prefix}list [');
      for (var i = 0; i < node.listItems.length; i++) {
        // ignore: avoid_print
        print('$prefix  [$i]:');
        _printNode(node.listItems[i], indent + 2);
      }
      // ignore: avoid_print
      print('$prefix]');
    }
  }

  @override
  String toString() {
    return 'DynamicSchema(keys: ${keys.length}, type: ${_root.type.name})';
  }
}

// Extension methods for easier access
extension DynamicSchemaExtension on DynamicSchema {
  // Shorthand for getString
  String operator [](String key) => getString(key);

  // Map-like access to nested objects
  DynamicSchema? call(String key) => getNested(key);
}
