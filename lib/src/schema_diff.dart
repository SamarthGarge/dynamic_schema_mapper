import 'schema_node.dart';

// Detects differences between two schemas
class SchemaDiff {
  // Compare two schemas and return list of changes
  static List<SchemaChange> compare(
    SchemaNode oldSchema,
    SchemaNode newSchema,
  ) {
    final changes = <SchemaChange>[];

    _compareNodes(oldSchema, newSchema, '', changes);

    return changes;
  }

  // Compare two schema maps extracted from SchemaNodes
  static List<SchemaChange> compareSchemaStructure(
    Map<String, dynamic> oldSchema,
    Map<String, dynamic> newSchema,
  ) {
    final changes = <SchemaChange>[];

    _compareSchemaStructure(oldSchema, newSchema, '', changes);

    return changes;
  }

  static void _compareNodes(
    SchemaNode oldNode,
    SchemaNode newNode,
    String path,
    List<SchemaChange> changes,
  ) {
    // Type changed
    if (oldNode.type != newNode.type) {
      changes.add(
        SchemaChange(
          type: ChangeType.typeChanged,
          path: path,
          oldValue: oldNode.type.name,
          newValue: newNode.type.name,
        ),
      );
      return; // Don't continue comparing if types differ
    }

    if (oldNode.isMap && newNode.isMap) {
      final oldKeys = oldNode.keys.toSet();
      final newKeys = newNode.keys.toSet();

      // Added keys
      for (final key in newKeys.difference(oldKeys)) {
        final fullPath = path.isEmpty ? key : '$path.$key';
        final newChild = newNode.getNested(key);
        changes.add(
          SchemaChange(
            type: ChangeType.fieldAdded,
            path: fullPath,
            newValue: newChild?.type.name,
          ),
        );
      }

      // Removed keys
      for (final key in oldKeys.difference(newKeys)) {
        final fullPath = path.isEmpty ? key : '$path.$key';
        final oldChild = oldNode.getNested(key);
        changes.add(
          SchemaChange(
            type: ChangeType.fieldRemoved,
            path: fullPath,
            oldValue: oldChild?.type.name,
          ),
        );
      }

      // Compare common keys
      for (final key in oldKeys.intersection(newKeys)) {
        final fullPath = path.isEmpty ? key : '$path.$key';
        final oldChild = oldNode.getNested(key);
        final newChild = newNode.getNested(key);
        if (oldChild != null && newChild != null) {
          _compareNodes(oldChild, newChild, fullPath, changes);
        }
      }
    } else if (oldNode.isList && newNode.isList) {
      // Compare list item schemas if both have items
      if (oldNode.listItems.isNotEmpty && newNode.listItems.isNotEmpty) {
        _compareNodes(
          oldNode.listItems.first,
          newNode.listItems.first,
          '$path[*]',
          changes,
        );
      }
    }
  }

  static void _compareSchemaStructure(
    Map<String, dynamic> oldSchema,
    Map<String, dynamic> newSchema,
    String path,
    List<SchemaChange> changes,
  ) {
    // If both are objects with properties
    if (oldSchema['type'] == 'object' && newSchema['type'] == 'object') {
      final oldProps = oldSchema['properties'] as Map<String, dynamic>? ?? {};
      final newProps = newSchema['properties'] as Map<String, dynamic>? ?? {};

      final oldKeys = oldProps.keys.toSet();
      final newKeys = newProps.keys.toSet();

      // Added fields
      for (final key in newKeys.difference(oldKeys)) {
        final fullPath = path.isEmpty ? key : '$path.$key';
        changes.add(
          SchemaChange(
            type: ChangeType.fieldAdded,
            path: fullPath,
            newValue: newProps[key]['type'],
          ),
        );
      }

      // Removed fields
      for (final key in oldKeys.difference(newKeys)) {
        final fullPath = path.isEmpty ? key : '$path.$key';
        changes.add(
          SchemaChange(
            type: ChangeType.fieldRemoved,
            path: fullPath,
            oldValue: oldProps[key]['type'],
          ),
        );
      }

      // Compare common fields
      for (final key in oldKeys.intersection(newKeys)) {
        final fullPath = path.isEmpty ? key : '$path.$key';
        _compareSchemaStructure(
          oldProps[key],
          newProps[key],
          fullPath,
          changes,
        );
      }
    } else if (oldSchema['type'] != newSchema['type']) {
      // Type changed
      changes.add(
        SchemaChange(
          type: ChangeType.typeChanged,
          path: path,
          oldValue: oldSchema['type'],
          newValue: newSchema['type'],
        ),
      );
    }
  }

  // Generate a human-readable summary of changes
  static String summarize(List<SchemaChange> changes) {
    if (changes.isEmpty) {
      return 'No schema changes detected';
    }

    final buffer = StringBuffer();
    buffer.writeln('Schema Changes Detected (${changes.length} total):');
    buffer.writeln();

    final grouped = <ChangeType, List<SchemaChange>>{};
    for (final change in changes) {
      grouped.putIfAbsent(change.type, () => []).add(change);
    }

    for (final entry in grouped.entries) {
      buffer.writeln('${entry.key.displayName}:');
      for (final change in entry.value) {
        buffer.writeln('  • ${change.path}');
        if (change.oldValue != null && change.newValue != null) {
          buffer.writeln('    ${change.oldValue} → ${change.newValue}');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  // Check if changes are breaking (might cause crashes)
  static bool hasBreakingChanges(List<SchemaChange> changes) {
    return changes.any(
      (change) =>
          change.type == ChangeType.fieldRemoved ||
          change.type == ChangeType.typeChanged,
    );
  }

  // Filter only breaking changes
  static List<SchemaChange> getBreakingChanges(List<SchemaChange> changes) {
    return changes
        .where(
          (change) =>
              change.type == ChangeType.fieldRemoved ||
              change.type == ChangeType.typeChanged,
        )
        .toList();
  }
}

// Represents a single schema change
class SchemaChange {
  final ChangeType type;
  final String path;
  final String? oldValue;
  final String? newValue;

  SchemaChange({
    required this.type,
    required this.path,
    this.oldValue,
    this.newValue,
  });

  @override
  String toString() {
    final buffer = StringBuffer('${type.displayName}: $path');
    if (oldValue != null && newValue != null) {
      buffer.write(' ($oldValue → $newValue)');
    } else if (oldValue != null) {
      buffer.write(' (was: $oldValue)');
    } else if (newValue != null) {
      buffer.write(' (now: $newValue)');
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'path': path,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
    };
  }
}

// Types of schema changes
enum ChangeType { fieldAdded, fieldRemoved, typeChanged }

extension ChangeTypeExtension on ChangeType {
  String get displayName {
    switch (this) {
      case ChangeType.fieldAdded:
        return 'Fields Added';
      case ChangeType.fieldRemoved:
        return 'Fields Removed';
      case ChangeType.typeChanged:
        return 'Type Changed';
    }
  }
}
