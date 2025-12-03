import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_schema_mapper/dynamic_schema_mapper.dart';

void main() {
  group('SchemaNode Tests', () {
    test('Parse primitive values', () {
      final stringNode = SchemaNode.primitive('hello');
      expect(stringNode.type, SchemaNodeType.string);
      expect(stringNode.rawValue, 'hello');

      final intNode = SchemaNode.primitive(42);
      expect(intNode.type, SchemaNodeType.integer);
      expect(intNode.rawValue, 42);

      final doubleNode = SchemaNode.primitive(3.14);
      expect(doubleNode.type, SchemaNodeType.double);
      expect(doubleNode.rawValue, 3.14);

      final boolNode = SchemaNode.primitive(true);
      expect(boolNode.type, SchemaNodeType.boolean);
      expect(boolNode.rawValue, true);

      final nullNode = SchemaNode.primitive(null);
      expect(nullNode.type, SchemaNodeType.nullValue);
      expect(nullNode.rawValue, null);
    });

    test('Parse object (Map)', () {
      final map = {'name': 'John', 'age': 30};
      final node = SchemaNode.object(map);

      expect(node.type, SchemaNodeType.object);
      expect(node.isMap, true);
      expect(node.keys.length, 2);
      expect(node.hasKey('name'), true);
      expect(node.hasKey('age'), true);
    });

    test('Parse list', () {
      final list = [1, 2, 3];
      final node = SchemaNode.list(list);

      expect(node.type, SchemaNodeType.list);
      expect(node.isList, true);
      expect(node.listItems.length, 3);
    });

    test('Safe getters return defaults for non-existent keys', () {
      final node = SchemaNode.object({'name': 'John'});

      expect(node.getString('missing'), '');
      expect(node.getString('missing', defaultValue: 'N/A'), 'N/A');
      expect(node.getInt('missing'), 0);
      expect(node.getInt('missing', defaultValue: 42), 42);
      expect(node.getDouble('missing'), 0.0);
      expect(node.getBool('missing'), false);
    });

    test('Safe getters handle type conversion', () {
      final node = SchemaNode.object({
        'stringNum': '42',
        'intToDouble': 10,
        'doubleToInt': 10.9,
        'boolString': 'true',
      });

      expect(node.getInt('stringNum'), 42);
      expect(node.getDouble('intToDouble'), 10.0);
      expect(node.getInt('doubleToInt'), 10);
      expect(node.getBool('boolString'), true);
    });
  });

  group('DynamicSchema Tests', () {
    test('Parse basic JSON', () {
      final json = {'id': 1, 'name': 'Test', 'active': true, 'price': 99.99};

      final schema = DynamicSchema.parse(json);

      expect(schema.getInt('id'), 1);
      expect(schema.getString('name'), 'Test');
      expect(schema.getBool('active'), true);
      expect(schema.getDouble('price'), 99.99);
    });

    test('Parse nested objects', () {
      final json = {
        'user': {
          'name': 'Alice',
          'contact': {'email': 'alice@example.com', 'phone': '123456'},
        },
      };

      final schema = DynamicSchema.parse(json);
      final user = schema.getNested('user');

      expect(user, isNotNull);
      expect(user!.getString('name'), 'Alice');

      final contact = user.getNested('contact');
      expect(contact, isNotNull);
      expect(contact!.getString('email'), 'alice@example.com');
      expect(contact.getString('phone'), '123456');
    });

    test('Parse and iterate lists', () {
      final json = {
        'items': [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
          {'id': 3, 'name': 'Item 3'},
        ],
      };

      final schema = DynamicSchema.parse(json);
      final items = schema.getList('items');

      expect(items.length, 3);
      expect(items[0].getInt('id'), 1);
      expect(items[0].getString('name'), 'Item 1');
      expect(items[2].getInt('id'), 3);
    });

    test('Get value at path', () {
      final json = {
        'user': {
          'profile': {
            'location': {'city': 'Portland', 'country': 'USA'},
          },
        },
      };

      final schema = DynamicSchema.parse(json);

      expect(schema.getValueAtPath('user.profile.location.city'), 'Portland');
      expect(schema.getValueAtPath('user.profile.location.country'), 'USA');
    });

    test('Get all paths', () {
      final json = {
        'name': 'Test',
        'nested': {'field1': 'value1', 'field2': 'value2'},
      };

      final schema = DynamicSchema.parse(json);
      final paths = schema.getAllPaths();

      expect(paths.contains('name'), true);
      expect(paths.contains('nested'), true);
      expect(paths.contains('nested.field1'), true);
      expect(paths.contains('nested.field2'), true);
    });

    test('Convert back to JSON string', () {
      final json = {'id': 1, 'name': 'Test', 'active': true};

      final schema = DynamicSchema.parse(json);
      final jsonString = schema.toJsonString();

      expect(jsonString.contains('"id":1'), true);
      expect(jsonString.contains('"name":"Test"'), true);
      expect(jsonString.contains('"active":true'), true);
    });

    test('Get schema structure', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'nested': {'value': 42},
      };

      final schema = DynamicSchema.parse(json);
      final structure = schema.getSchemaStructure();

      expect(structure['type'], 'object');
      expect(structure['properties'], isNotNull);

      final props = structure['properties'] as Map;
      expect(props['id']['type'], 'integer');
      expect(props['name']['type'], 'string');
      expect(props['nested']['type'], 'object');
    });
  });

  group('Schema Change Detection Tests', () {
    setUp(() {
      DynamicSchema.resetCache();
    });

    test('Detect added fields', () {
      List<SchemaChange>? detectedChanges;

      DynamicSchema.enableSchemaDetection((changes) {
        detectedChanges = changes;
      });

      // First schema
      DynamicSchema.parse({'id': 1, 'name': 'Test'});

      // Second schema with new field
      DynamicSchema.parse({
        'id': 2,
        'name': 'Test 2',
        'email': 'new@field.com', // Added
      });

      expect(detectedChanges, isNotNull);
      expect(detectedChanges!.length, 1);
      expect(detectedChanges!.first.type, ChangeType.fieldAdded);
      expect(detectedChanges!.first.path, 'email');
    });

    test('Detect removed fields', () {
      List<SchemaChange>? detectedChanges;

      DynamicSchema.enableSchemaDetection((changes) {
        detectedChanges = changes;
      });

      DynamicSchema.parse({'id': 1, 'name': 'Test', 'email': 'test@test.com'});

      DynamicSchema.parse({
        'id': 2,
        'name': 'Test 2',
        // 'email' removed
      });

      expect(detectedChanges, isNotNull);
      expect(
        detectedChanges!.any((c) => c.type == ChangeType.fieldRemoved),
        true,
      );
    });

    test('Detect type changes', () {
      List<SchemaChange>? detectedChanges;

      DynamicSchema.enableSchemaDetection((changes) {
        detectedChanges = changes;
      });

      DynamicSchema.parse({'id': 1, 'value': 'string value'});
      DynamicSchema.parse({'id': 2, 'value': 123}); // Changed to int

      expect(detectedChanges, isNotNull);
      expect(
        detectedChanges!.any((c) => c.type == ChangeType.typeChanged),
        true,
      );
    });

    test('No changes detected for same schema', () {
      List<SchemaChange>? detectedChanges;

      DynamicSchema.enableSchemaDetection((changes) {
        detectedChanges = changes;
      });

      DynamicSchema.parse({'id': 1, 'name': 'Test'});
      detectedChanges = null; // Reset

      DynamicSchema.parse({'id': 2, 'name': 'Test 2'}); // Same structure

      expect(detectedChanges, null); // No callback triggered
    });
  });

  group('SchemaDiff Tests', () {
    test('Compare two schemas directly', () {
      final oldSchema = DynamicSchema.parse({'id': 1, 'name': 'Old'});

      final newSchema = DynamicSchema.parse({
        'id': 1,
        'name': 'New',
        'email': 'new@example.com',
      });

      final changes = DynamicSchema.compareSchemas(oldSchema, newSchema);

      expect(changes.length, 1);
      expect(changes.first.type, ChangeType.fieldAdded);
      expect(changes.first.path, 'email');
    });

    test('Summarize changes', () {
      final changes = [
        SchemaChange(type: ChangeType.fieldAdded, path: 'email'),
        SchemaChange(type: ChangeType.fieldRemoved, path: 'phone'),
      ];

      final summary = SchemaDiff.summarize(changes);

      expect(summary.contains('Fields Added'), true);
      expect(summary.contains('email'), true);
      expect(summary.contains('Fields Removed'), true);
      expect(summary.contains('phone'), true);
    });

    test('Identify breaking changes', () {
      final changes = [
        SchemaChange(type: ChangeType.fieldAdded, path: 'newField'),
        SchemaChange(type: ChangeType.fieldRemoved, path: 'oldField'),
        SchemaChange(
          type: ChangeType.typeChanged,
          path: 'value',
          oldValue: 'string',
          newValue: 'integer',
        ),
      ];

      expect(SchemaDiff.hasBreakingChanges(changes), true);

      final breaking = SchemaDiff.getBreakingChanges(changes);
      expect(breaking.length, 2); // Removed + TypeChanged
    });
  });

  group('Edge Cases', () {
    test('Handle empty JSON object', () {
      final schema = DynamicSchema.parse({});
      expect(schema.keys.isEmpty, true);
    });

    test('Handle empty list', () {
      final schema = DynamicSchema.parse({'items': []});
      final items = schema.getList('items');
      expect(items.isEmpty, true);
    });

    test('Handle deeply nested structure', () {
      final json = {
        'level1': {
          'level2': {
            'level3': {
              'level4': {'value': 'deep'},
            },
          },
        },
      };

      final schema = DynamicSchema.parse(json);
      final value = schema.getValueAtPath('level1.level2.level3.level4.value');
      expect(value, 'deep');
    });

    test('Handle mixed list types', () {
      final json = {
        'mixed': [1, 'two', 3.0, true, null],
      };

      final schema = DynamicSchema.parse(json);
      final items = schema.getList('mixed');

      expect(items.length, 5);
      expect(items[0].rawValue, 1);
      expect(items[1].rawValue, 'two');
      expect(items[2].rawValue, 3.0);
      expect(items[3].rawValue, true);
      expect(items[4].rawValue, null);
    });
  });
}
