class ApiConst {
  static const String baseUrl = "http://localhost:8080";

  // Product Endpoints
  static const String products = "$baseUrl/products";

  // Cart Endpoints
  static const String addToCart = "$baseUrl/cart";
  static const String updateCart = "$baseUrl/cart";
  static const String deleteCartItem = "$baseUrl/cart"; // Add productId as suffix
  static const String buy = "$baseUrl/buy";

  // Static Files
  static String staticFile(String fileName) => "$baseUrl/static/$fileName";
}
