class CartItem {
  String id;
  String name;
  int quantity;
  double price;
  int ml;
  String image;
  bool selected;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.ml,
    required this.image,
    this.selected = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '', // Default to 'unknown' if null
      name: json['product_name'] ?? 'Unnamed Product', // Default name
      quantity: json['quantity'] ?? 1, // Default to 1 if null
      price: double.tryParse(json['product_price']?.toString() ?? '0') ??
          0.0, // Safely parse price
      ml: _parseSize(
          json['product_size']?.toString() ?? '0'), // Handle size parsing
      image: json['product_image'] ?? '', // Default to empty string
    );
  }

  static int _parseSize(String size) {
    final regex = RegExp(r'(\d+)([a-zA-Z]*)');
    final match = regex.firstMatch(size);
    if (match != null) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2);
      if (unit != null && unit.isNotEmpty) {
        switch (unit.toLowerCase()) {
          case 'mg':
          case 'g':
            return value; // Assuming you want to keep the value as is for mg and g
          default:
            return value; // Default case for unknown units
        }
      }
      return value; // No unit, just return the value
    }
    throw Exception('Invalid size format');
  }
}
