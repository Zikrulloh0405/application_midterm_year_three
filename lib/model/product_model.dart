// Product Model
class Product {
  final String id;
  final String name;
  final double price;
  final String image;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  @override
  bool operator ==(Object other) => other is Product && id == other.id;

  @override
  int get hashCode => id.hashCode;
}