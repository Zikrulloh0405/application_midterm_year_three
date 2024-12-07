import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'model/product_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Grid with End Drawer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _products;
  final Map<Product, int> _cart = {}; // Cart state: Product -> Quantity
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isBuying = false; // Track buy action
  String baseUrl = "http://localhost:8080";

  @override
  void initState() {
    super.initState();
    _products = fetchProducts();
  }

  Future<List<Product>> fetchProducts() async {
    log('Fetching products...');
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode == 200) {
      log('Products fetched successfully');
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.entries.map((entry) {
        final product = entry.value;
        return Product(
          id: entry.key,
          name: product['name'],
          price: product['price'],
          image: product['images'],
        );
      }).toList();
    } else {
      log('Failed to fetch products: ${response.statusCode}');
      throw Exception('Failed to load products');
    }
  }

  Future<void> _addToCart(Product product) async {
    log('Adding product to cart: ${product.name}');
    final response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'productId': product.id}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _cart[product] = (_cart[product] ?? 0) + 1;
      });
    }
  }

  Future<void> _removeFromCart(Product product) async {
    log('Removing product from cart: ${product.name}');
    final response = await http.put(
      Uri.parse('$baseUrl/cart'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'productId': product.id}),
    );

    if (response.statusCode == 200) {
      setState(() {
        if (_cart[product]! > 1) {
          _cart[product] = _cart[product]! - 1;
        } else {
          _cart.remove(product);
        }
      });
    }
  }

  Future<void> _deleteFromCart(Product product) async {
    log('Deleting product from cart: ${product.name}');
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/${product.id}'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _cart.remove(product);
      });
    }
  }

  Future<void> _buy() async {
    setState(() => _isBuying = true); // Show loading indicator
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading time

    final response = await http.post(Uri.parse('$baseUrl/buy'));
    if (response.statusCode == 200) {
      log('Purchase successful');
      setState(() {
        _cart.clear();
        _products = fetchProducts(); // Reload products
        _isBuying = false; // Hide loading indicator
      });
      _scaffoldKey.currentState?.closeEndDrawer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase successful!')),
      );
    } else {
      log('Purchase failed');
      setState(() => _isBuying = false); // Hide loading indicator
    }
  }

  double _calculateTotal() {
    return _cart.entries.fold<double>(
      0,
          (sum, entry) => sum + (entry.key.price * entry.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
            icon: const Icon(Icons.shopping_basket),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const Text(
                'Cart',
                style: TextStyle(fontSize: 24),
              ),
              Expanded(
                child: _cart.isEmpty
                    ? const Center(child: Text('Your cart is empty!'))
                    : ListView(
                  children: _cart.entries.map((entry) {
                    final product = entry.key;
                    final quantity = entry.value;
                    return ListTile(
                      leading: Image.network(
                        '$baseUrl/static/${product.image}',
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                      ),
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subtotal: \$${(product.price * quantity).toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (quantity > 0)
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _removeFromCart(product),
                                ) ,
                              Text('$quantity'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _addToCart(product),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteFromCart(product),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${_calculateTotal().toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    MaterialButton(
                      color: Colors.green,
                      onPressed: (_cart.isNotEmpty && !_isBuying)
                          ? _buy
                          : null, // Disable if empty or loading
                      child: _isBuying
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "Buy",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Product>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          final products = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3 / 4,
            ),
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Image.network(
                        '$baseUrl/static/${product.image}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if ((_cart[product] ?? 0) > 0)
                          IconButton(
                            onPressed: () => _removeFromCart(product),
                            icon: const Icon(Icons.remove),
                          ),
                        Text('${_cart[product] ?? 0}'),
                        IconButton(
                          onPressed: () => _addToCart(product),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}


