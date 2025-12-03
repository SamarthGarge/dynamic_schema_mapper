// Represents a node in the JSON schema tree.
// Can be a primitive value, object (Map), or list.
class SchemaNode {
  final dynamic value;
  final SchemaNodeType type;
  final Map<String, SchemaNode>? _children;
  final List<SchemaNode>? _listItems;

  SchemaNode._({
    required this.value,
    required this.type,
    Map<String, SchemaNode>? children,
    List<SchemaNode>? listItems,
  }) : _children = children,
       _listItems = listItems;

  // Creates a primitive node (string, int, double, bool, null)
  factory SchemaNode.primitive(dynamic value) {
    return SchemaNode._(value: value, type: _resolvePrimitiveType(value));
  }

  // Creates an object node from a Map
  factory SchemaNode.object(Map<String, dynamic> map) {
    final children = <String, SchemaNode>{};
    map.forEach((key, value) {
      children[key] = SchemaNode.fromDynamic(value);
    });
    return SchemaNode._(
      value: map,
      type: SchemaNodeType.object,
      children: children,
    );
  }

  // Creates a list node
  factory SchemaNode.list(List<dynamic> list) {
    final items = list.map((item) => SchemaNode.fromDynamic(item)).toList();
    return SchemaNode._(
      value: list,
      type: SchemaNodeType.list,
      listItems: items,
    );
  }

  // Creates a SchemaNode from any dynamic value
  factory SchemaNode.fromDynamic(dynamic value) {
    if (value == null) {
      return SchemaNode.primitive(null);
    } else if (value is Map) {
      return SchemaNode.object(Map<String, dynamic>.from(value));
    } else if (value is List) {
      return SchemaNode.list(value);
    } else {
      return SchemaNode.primitive(value);
    }
  }

  // Check if this node is a map/object
  bool get isMap => type == SchemaNodeType.object;

  // Check if this node is a list
  bool get isList => type == SchemaNodeType.list;

  // Check if this node is a primitive
  bool get isPrimitive =>
      type == SchemaNodeType.string ||
      type == SchemaNodeType.integer ||
      type == SchemaNodeType.double ||
      type == SchemaNodeType.boolean ||
      type == SchemaNodeType.nullValue;

  // ==================== Type-Safe Getters ====================

  // Safely get a String value with default fallback
  String getString(String key, {String defaultValue = ""}) {
    if (!isMap || _children == null) return defaultValue;
    final node = _children[key];
    if (node == null) return defaultValue;
    return node.value?.toString() ?? defaultValue;
  }

  // Safely get an int value with default fallback
  int getInt(String key, {int defaultValue = 0}) {
    if (!isMap || _children == null) return defaultValue;
    final node = _children[key];
    if (node == null) return defaultValue;

    if (node.value is int) return node.value;
    if (node.value is double) return (node.value as double).toInt();
    return int.tryParse(node.value.toString()) ?? defaultValue;
  }

  // Safely get a double value with default fallback
  double getDouble(String key, {double defaultValue = 0.0}) {
    if (!isMap || _children == null) return defaultValue;
    final node = _children[key];
    if (node == null) return defaultValue;

    if (node.value is double) return node.value;
    if (node.value is int) return (node.value as int).toDouble();
    return double.tryParse(node.value.toString()) ?? defaultValue;
  }

  // Safely get a bool value with default fallback
  bool getBool(String key, {bool defaultValue = false}) {
    if (!isMap || _children == null) return defaultValue;
    final node = _children[key];
    if (node == null) return defaultValue;

    if (node.value is bool) return node.value;
    final str = node.value.toString().toLowerCase();
    if (str == 'true' || str == '1') return true;
    if (str == 'false' || str == '0') return false;
    return defaultValue;
  }

  // Get a nested object as SchemaNode
  SchemaNode? getNested(String key) {
    if (!isMap || _children == null) return null;
    return _children[key];
  }

  // Get a list of SchemaNodes
  List<SchemaNode> getList(String key) {
    if (!isMap || _children == null) return [];
    final node = _children[key];
    if (node == null || !node.isList) return [];
    return node._listItems ?? [];
  }

  // Get all list items if this node is a list
  List<SchemaNode> get listItems => _listItems ?? [];

  // Get all keys if this is an object
  List<String> get keys => _children?.keys.toList() ?? [];

  // Check if a key exists
  bool hasKey(String key) => _children?.containsKey(key) ?? false;

  // Get the raw value
  dynamic get rawValue => value;

  // Convert to JSON-serializable Map
  Map<String, dynamic> toJson() {
    if (isMap && _children != null) {
      return _children.map((key, node) => MapEntry(key, node.toJson()));
    } else if (isList && _listItems != null) {
      return {'_list': _listItems.map((item) => item.toJson()).toList()};
    } else {
      return {'_value': value};
    }
  }

  @override
  String toString() {
    if (isPrimitive) return 'SchemaNode($type: $value)';
    if (isMap) return 'SchemaNode(object with ${keys.length} keys)';
    if (isList) return 'SchemaNode(list with ${listItems.length} items)';
    return 'SchemaNode(unknown)';
  }

  static SchemaNodeType _resolvePrimitiveType(dynamic value) {
    if (value == null) return SchemaNodeType.nullValue;
    if (value is String) return SchemaNodeType.string;
    if (value is int) return SchemaNodeType.integer;
    if (value is double) return SchemaNodeType.double;
    if (value is bool) return SchemaNodeType.boolean;
    return SchemaNodeType.unknown;
  }
}

// Enum representing the type of a SchemaNode
enum SchemaNodeType {
  string,
  integer,
  double,
  boolean,
  nullValue,
  object,
  list,
  unknown,
}
