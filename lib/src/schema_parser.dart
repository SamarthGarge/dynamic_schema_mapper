import 'dart:convert';
import 'schema_node.dart';

// Parses JSON data into SchemaNode tree structure
class SchemaParser {
  // Parse JSON string or object into SchemaNode
  static SchemaNode parse(dynamic input) {
    dynamic json = input;

    // If input is a string, decode it first
    if (input is String) {
      try {
        json = jsonDecode(input);
      } catch (e) {
        throw SchemaParserException('Invalid JSON string: $e');
      }
    }

    // Create SchemaNode from the decoded JSON
    return SchemaNode.fromDynamic(json);
  }

  // Parse with validation
  static SchemaNode parseWithValidation(
    dynamic input, {
    bool allowNull = true,
    bool requireObject = false,
  }) {
    final node = parse(input);

    if (!allowNull && node.type == SchemaNodeType.nullValue) {
      throw SchemaParserException('Null values are not allowed');
    }

    if (requireObject && !node.isMap) {
      throw SchemaParserException('Root must be an object/map');
    }

    return node;
  }

  // Extract schema structure (type information only, no values)
  static Map<String, dynamic> extractSchema(SchemaNode node) {
    if (node.isPrimitive) {
      return {'type': node.type.name};
    } else if (node.isMap) {
      final schema = <String, dynamic>{};
      for (final key in node.keys) {
        final childNode = node.getNested(key);
        if (childNode != null) {
          schema[key] = extractSchema(childNode);
        }
      }
      return {'type': 'object', 'properties': schema};
    } else if (node.isList) {
      if (node.listItems.isEmpty) {
        return {
          'type': 'list',
          'items': {'type': 'unknown'},
        };
      }
      // Use first item as schema template
      return {'type': 'list', 'items': extractSchema(node.listItems.first)};
    }
    return {'type': 'unknown'};
  }

  // Convert schema back to JSON string
  static String toJsonString(SchemaNode node, {bool pretty = false}) {
    final encoder = pretty ? JsonEncoder.withIndent('  ') : JsonEncoder();
    return encoder.convert(_nodeToJson(node));
  }

  static dynamic _nodeToJson(SchemaNode node) {
    if (node.isPrimitive) {
      return node.rawValue;
    } else if (node.isMap) {
      final map = <String, dynamic>{};
      for (final key in node.keys) {
        final childNode = node.getNested(key);
        if (childNode != null) {
          map[key] = _nodeToJson(childNode);
        }
      }
      return map;
    } else if (node.isList) {
      return node.listItems.map((item) => _nodeToJson(item)).toList();
    }
    return null;
  }

  // Get all paths in the schema (dot notation)
  static List<String> getAllPaths(SchemaNode node, {String prefix = ''}) {
    final paths = <String>[];

    if (node.isMap) {
      for (final key in node.keys) {
        final fullPath = prefix.isEmpty ? key : '$prefix.$key';
        paths.add(fullPath);

        final childNode = node.getNested(key);
        if (childNode != null && (childNode.isMap || childNode.isList)) {
          paths.addAll(getAllPaths(childNode, prefix: fullPath));
        }
      }
    } else if (node.isList && node.listItems.isNotEmpty) {
      final firstItem = node.listItems.first;
      if (firstItem.isMap || firstItem.isList) {
        paths.addAll(getAllPaths(firstItem, prefix: '$prefix[0]'));
      }
    }

    return paths;
  }

  // Get value at a dot-notation path
  static dynamic getValueAtPath(SchemaNode node, String path) {
    final parts = path.split('.');
    SchemaNode? current = node;

    for (final part in parts) {
      if (current == null) return null;

      // Handle array access like "items[0]"
      final arrayMatch = RegExp(r'(\w+)\[(\d+)\]').firstMatch(part);
      if (arrayMatch != null) {
        final key = arrayMatch.group(1)!;
        final index = int.parse(arrayMatch.group(2)!);
        final listNode = current.getNested(key);
        if (listNode != null && listNode.isList) {
          if (index < listNode.listItems.length) {
            current = listNode.listItems[index];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        current = current.getNested(part);
      }
    }

    return current?.rawValue;
  }
}

// Custom exception for schema parsing errors
class SchemaParserException implements Exception {
  final String message;
  SchemaParserException(this.message);

  @override
  String toString() => 'SchemaParserException: $message';
}
