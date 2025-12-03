import 'package:flutter/material.dart';
import 'package:dynamic_schema_mapper/dynamic_schema_mapper.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Schema Mapper Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Schema Mapper Examples'),
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            'Basic Usage',
            'Simple JSON parsing with type-safe getters',
            Icons.code,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BasicUsageScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Nested Objects',
            'Access deeply nested JSON structures',
            Icons.account_tree,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NestedObjectsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Lists & Arrays',
            'Working with lists of objects',
            Icons.list,
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Schema Detection',
            'Detect backend schema changes',
            Icons.notifications_active,
            Colors.red,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchemaDetectionScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Real-World Example',
            'E-commerce product listing',
            Icons.shopping_cart,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductListingScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'User Dashboard',
            'Complex multi-source data',
            Icons.dashboard,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Basic Usage Screen ====================
class BasicUsageScreen extends StatelessWidget {
  const BasicUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulate API response
    final jsonResponse = {
      'id': 123,
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'age': 30,
      'isPremium': true,
      'balance': 1250.50,
      'lastLogin': '2024-03-15T10:30:00Z',
    };

    final schema = DynamicSchema.parse(jsonResponse);

    return Scaffold(
      appBar: AppBar(title: const Text('Basic Usage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('JSON Response', jsonEncode(jsonResponse)),
          const SizedBox(height: 24),
          _buildSection('Parsed Data', null),
          _buildDataRow('ID', schema.getInt('id').toString()),
          _buildDataRow('Name', schema.getString('name')),
          _buildDataRow('Email', schema.getString('email')),
          _buildDataRow('Age', schema.getInt('age').toString()),
          _buildDataRow('Premium', schema.getBool('isPremium') ? 'Yes' : 'No'),
          _buildDataRow('Balance', '\$${schema.getDouble('balance')}'),
          _buildDataRow('Last Login', schema.getString('lastLogin')),
          const SizedBox(height: 24),
          _buildSection('Default Values Demo', null),
          _buildDataRow(
            'Phone (not in JSON)',
            schema.getString('phone', defaultValue: 'Not provided'),
          ),
          _buildDataRow(
            'Score (not in JSON)',
            schema.getInt('score', defaultValue: 0).toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (content != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ==================== Nested Objects Screen ====================
class NestedObjectsScreen extends StatelessWidget {
  const NestedObjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jsonResponse = {
      'user': {
        'id': 1,
        'name': 'Alice Johnson',
        'contact': {
          'email': 'alice@example.com',
          'phone': '+1-555-0123',
          'address': {
            'street': '123 Main Street',
            'city': 'Springfield',
            'state': 'IL',
            'zipcode': 62701,
            'coordinates': {'lat': 39.7817, 'lng': -89.6501},
          },
        },
      },
    };

    final schema = DynamicSchema.parse(jsonResponse);
    final user = schema.getNested('user');
    final contact = user?.getNested('contact');
    final address = contact?.getNested('address');
    final coords = address?.getNested('coordinates');

    return Scaffold(
      appBar: AppBar(title: const Text('Nested Objects')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('ID', user?.getInt('id').toString() ?? 'N/A'),
                  _buildInfoRow('Name', user?.getString('name') ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('Email', contact?.getString('email') ?? 'N/A'),
                  _buildInfoRow('Phone', contact?.getString('phone') ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Street',
                    address?.getString('street') ?? 'N/A',
                  ),
                  _buildInfoRow('City', address?.getString('city') ?? 'N/A'),
                  _buildInfoRow('State', address?.getString('state') ?? 'N/A'),
                  _buildInfoRow(
                    'Zipcode',
                    address?.getInt('zipcode').toString() ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coordinates',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Latitude',
                    coords?.getDouble('lat').toString() ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Longitude',
                    coords?.getDouble('lng').toString() ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Using Path Access:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'City: ${schema.getValueAtPath('user.contact.address.city')}',
                ),
                Text(
                  'Lat: ${schema.getValueAtPath('user.contact.address.coordinates.lat')}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Lists Screen ====================
class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jsonResponse = {
      'store': 'Tech World',
      'products': [
        {
          'id': 1,
          'name': 'Laptop',
          'price': 999.99,
          'inStock': true,
          'category': 'Electronics',
        },
        {
          'id': 2,
          'name': 'Wireless Mouse',
          'price': 29.99,
          'inStock': true,
          'category': 'Accessories',
        },
        {
          'id': 3,
          'name': 'Mechanical Keyboard',
          'price': 129.99,
          'inStock': false,
          'category': 'Accessories',
        },
        {
          'id': 4,
          'name': 'Monitor',
          'price': 299.99,
          'inStock': true,
          'category': 'Electronics',
        },
      ],
    };

    final schema = DynamicSchema.parse(jsonResponse);
    final products = schema.getList('products');

    return Scaffold(
      appBar: AppBar(title: const Text('Lists & Arrays')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schema.getString('store'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${products.length} products available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: product.getBool('inStock')
                          ? Colors.green
                          : Colors.red,
                      child: Text(
                        '${product.getInt('id')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      product.getString('name'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(product.getString('category')),
                        Text(
                          product.getBool('inStock')
                              ? 'In Stock'
                              : 'Out of Stock',
                          style: TextStyle(
                            color: product.getBool('inStock')
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '\$${product.getDouble('price').toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Schema Detection Screen ====================
class SchemaDetectionScreen extends StatefulWidget {
  const SchemaDetectionScreen({super.key});

  @override
  State<SchemaDetectionScreen> createState() => _SchemaDetectionScreenState();
}

class _SchemaDetectionScreenState extends State<SchemaDetectionScreen> {
  final List<String> _logs = [];
  // int _version = 1;

  @override
  void initState() {
    super.initState();
    DynamicSchema.resetCache();
    DynamicSchema.enableSchemaDetection((changes) {
      setState(() {
        _logs.add('⚠️ Schema changed! Detected ${changes.length} changes:');
        for (final change in changes) {
          _logs.add('  • $change');
        }
        _logs.add('');
      });
    });
  }

  @override
  void dispose() {
    DynamicSchema.disableSchemaDetection();
    super.dispose();
  }

  void _simulateApiCall(int version) {
    setState(() {
      // _version = version;
      _logs.add('--- API Call Version $version ---');
    });

    Map<String, dynamic> json;

    switch (version) {
      case 1:
        json = {'id': 1, 'name': 'Product A', 'price': 99.99};
        _logs.add('Original schema: id, name, price');
        break;
      case 2:
        json = {'id': 2, 'name': 'Product B', 'price': 149.99};
        _logs.add('Same schema (no changes expected)');
        break;
      case 3:
        json = {
          'id': 3,
          'name': 'Product C',
          'price': 199.99,
          'category': 'Electronics',
          'inStock': true,
        };
        _logs.add('Added: category, inStock');
        break;
      case 4:
        json = {
          'id': 4,
          'name': 'Product D',
          'category': 'Electronics',
          'inStock': false,
        };
        _logs.add('Removed: price');
        break;
      default:
        json = {'id': 5, 'name': 'Product E', 'price': 'free'};
        _logs.add('Type changed: price (double → string)');
    }

    DynamicSchema.parse(json);
    _logs.add('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schema Detection')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulate API Evolution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Click buttons to simulate different API responses and watch schema changes being detected automatically.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _simulateApiCall(1),
                  child: const Text('V1: Original'),
                ),
                ElevatedButton(
                  onPressed: () => _simulateApiCall(2),
                  child: const Text('V2: Same Schema'),
                ),
                ElevatedButton(
                  onPressed: () => _simulateApiCall(3),
                  child: const Text('V3: Fields Added'),
                ),
                ElevatedButton(
                  onPressed: () => _simulateApiCall(4),
                  child: const Text('V4: Field Removed'),
                ),
                ElevatedButton(
                  onPressed: () => _simulateApiCall(5),
                  child: const Text('V5: Type Changed'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                      DynamicSchema.resetCache();
                      _logs.add('Cache reset. Ready for new detection.\n');
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Click buttons above to see schema detection in action',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: log.contains('⚠️')
                                ? Colors.orange
                                : log.startsWith('---')
                                ? Colors.blue
                                : Colors.black,
                            fontWeight:
                                log.contains('⚠️') || log.startsWith('---')
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== Product Listing Screen ====================
class ProductListingScreen extends StatelessWidget {
  const ProductListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiResponse = {
      'store': {'name': 'TechHub Store', 'rating': 4.8, 'totalProducts': 150},
      'categories': ['Electronics', 'Accessories', 'Software'],
      'featured': [
        {
          'id': 'PROD-001',
          'name': 'Premium Wireless Headphones',
          'description': 'Noise-cancelling, 30hr battery',
          'price': 299.99,
          'originalPrice': 399.99,
          'discount': 25.0,
          'rating': 4.7,
          'reviews': 1234,
          'inStock': true,
          'images': ['url1', 'url2'],
          'badge': 'Best Seller',
        },
        {
          'id': 'PROD-002',
          'name': 'Ultra HD Gaming Monitor',
          'description': '27" 4K, 144Hz refresh rate',
          'price': 549.99,
          'originalPrice': 549.99,
          'discount': 0.0,
          'rating': 4.9,
          'reviews': 856,
          'inStock': true,
          'images': ['url1'],
          'badge': 'New Arrival',
        },
        {
          'id': 'PROD-003',
          'name': 'Mechanical Gaming Keyboard',
          'description': 'RGB backlit, Cherry MX switches',
          'price': 179.99,
          'originalPrice': 229.99,
          'discount': 22.0,
          'rating': 4.6,
          'reviews': 567,
          'inStock': false,
          'images': ['url1', 'url2', 'url3'],
          'badge': 'Hot Deal',
        },
      ],
    };

    final schema = DynamicSchema.parse(apiResponse);
    final store = schema.getNested('store');
    final products = schema.getList('featured');

    return Scaffold(
      appBar: AppBar(
        title: Text(store?.getString('name') ?? 'Store'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  store?.getDouble('rating').toString() ?? '0.0',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final hasDiscount = product.getDouble('discount') > 0;
          final originalPrice = product.getDouble('originalPrice');
          final price = product.getDouble('price');
          final savings = originalPrice - price;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.getString('badge'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.getString('name'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.getString('description'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${product.getDouble('rating')} (${product.getInt('reviews')} reviews)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 8),
                            Text(
                              '\$${originalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Save \$${savings.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: product.getBool('inStock')
                                  ? () {}
                                  : null,
                              icon: Icon(
                                product.getBool('inStock')
                                    ? Icons.shopping_cart
                                    : Icons.block,
                              ),
                              label: Text(
                                product.getBool('inStock')
                                    ? 'Add to Cart'
                                    : 'Out of Stock',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.favorite_border),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================== User Dashboard Screen ====================
class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardData = {
      'user': {
        'id': 'USR-789',
        'name': 'Sarah Williams',
        'avatar': 'https://example.com/avatar.jpg',
        'memberSince': '2023-01-15',
        'tier': 'Gold',
      },
      'stats': {
        'totalOrders': 45,
        'totalSpent': 3456.78,
        'pointsEarned': 8920,
        'activeSavings': 234.50,
      },
      'recentOrders': [
        {
          'orderId': 'ORD-2024-123',
          'date': '2024-03-15',
          'status': 'Delivered',
          'total': 299.99,
          'items': 3,
        },
        {
          'orderId': 'ORD-2024-122',
          'date': '2024-03-10',
          'status': 'In Transit',
          'total': 149.50,
          'items': 2,
        },
      ],
      'notifications': [
        {'type': 'promotion', 'message': 'Flash sale starts in 2 hours!'},
        {'type': 'order', 'message': 'Your order has been shipped'},
      ],
    };

    final schema = DynamicSchema.parse(dashboardData);
    final user = schema.getNested('user');
    final stats = schema.getNested('stats');
    final orders = schema.getList('recentOrders');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[200],
                    child: Text(
                      user?.getString('name').substring(0, 1) ?? 'U',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.getString('name') ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${user?.getString('tier')} Member',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Member since ${user?.getString('memberSince')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  stats?.getInt('totalOrders').toString() ?? '0',
                  Icons.shopping_bag,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Spent',
                  '\$${stats?.getDouble('totalSpent').toStringAsFixed(2) ?? '0'}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Points',
                  stats?.getInt('pointsEarned').toString() ?? '0',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Savings',
                  '\$${stats?.getDouble('activeSavings').toStringAsFixed(2) ?? '0'}',
                  Icons.savings,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Orders
          const Text(
            'Recent Orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...orders.map((order) {
            final status = order.getString('status');
            Color statusColor;
            switch (status) {
              case 'Delivered':
                statusColor = Colors.green;
                break;
              case 'In Transit':
                statusColor = Colors.orange;
                break;
              default:
                statusColor = Colors.grey;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shopping_bag, color: statusColor),
                ),
                title: Text(
                  order.getString('orderId'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${order.getString('date')} • ${order.getInt('items')} items',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${order.getDouble('total').toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
