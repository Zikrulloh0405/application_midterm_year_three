import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../model/product_model.dart';
import '../server/api_const.dart';

class RepositoryController {
  // Fetch Products
  Future<List<Product>> fetchProducts() async {
    log('Fetching products...');
    final response = await http.get(Uri.parse(ApiConst.products));
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

  // Add to Cart
  Future<void> addToCart(String productId) async {
    log('Adding product to cart: $productId');
    final response = await http.post(
      Uri.parse(ApiConst.addToCart),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'productId': productId}),
    );

    if (response.statusCode == 200) {
      log('Product added to cart successfully');
    } else {
      log('Failed to add product to cart: ${response.statusCode}');
      throw Exception('Failed to add to cart');
    }
  }

  // Remove from Cart (Decrement)
  Future<void> removeFromCart(String productId) async {
    log('Removing product from cart: $productId');
    final response = await http.put(
      Uri.parse(ApiConst.updateCart),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'productId': productId}),
    );

    if (response.statusCode == 200) {
      log('Product quantity decremented successfully');
    } else {
      log('Failed to remove product from cart: ${response.statusCode}');
      throw Exception('Failed to remove from cart');
    }
  }

  // Delete from Cart
  Future<void> deleteFromCart(String productId) async {
    log('Deleting product from cart: $productId');
    final response = await http.delete(
      Uri.parse("${ApiConst.deleteCartItem}/$productId"),
    );

    if (response.statusCode == 200) {
      log('Product deleted from cart successfully');
    } else {
      log('Failed to delete product from cart: ${response.statusCode}');
      throw Exception('Failed to delete from cart');
    }
  }

  // Buy Cart
  Future<void> buyCart() async {
    log('Processing purchase...');
    final response = await http.post(Uri.parse(ApiConst.buy));

    if (response.statusCode == 200) {
      log('Purchase successful');
    } else {
      log('Purchase failed: ${response.statusCode}');
      throw Exception('Purchase failed');
    }
  }
}
