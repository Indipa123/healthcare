import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/home.dart';
import 'package:my_app/Screens/prescriptionupload.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'all_products_screen.dart'; // Import the new screen

void main() {
  runApp(const PharmacyApp());
}

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PharmacyScreen(),
    );
  }
}

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  _PharmacyScreenState createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  late Future<List<Product>> popularProducts;
  late Future<List<Product>> onSaleProducts;

  @override
  void initState() {
    super.initState();
    popularProducts = fetchPopularProducts();
    onSaleProducts = fetchOnSaleProducts();
  }

  Future<List<Product>> fetchPopularProducts() async {
    final response =
        await http.get(Uri.parse('http://172.20.10.2:3000/api/products/popular'));

    if (response.statusCode == 200) {
      final List<dynamic> productJson = json.decode(response.body);
      return productJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> fetchOnSaleProducts() async {
    final response =
        await http.get(Uri.parse('http://172.20.10.2:3000/api/products/onsale'));

    if (response.statusCode == 200) {
      final List<dynamic> productJson = json.decode(response.body);
      return productJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          },
        ),
        title: const Center(
          child: Text(
            "Pharmacy",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search drugs, category...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            // Prescription Upload Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order quickly with Prescription',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      UploadPrescriptionScreen()),
                            );
                          },
                          child: const Text(
                            "Upload Prescription",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Image.asset(
                      'assets/images/tablet.png', // Replace with your asset image
                      height: 60,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Popular Product
            SectionHeader(
                title: "Popular Product",
                onSeeAllPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AllProductsScreen()),
                  );
                }),
            FutureBuilder<List<Product>>(
              future: popularProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No products available'));
                } else {
                  return ProductSection(products: snapshot.data!);
                }
              },
            ),

            // Product On Sale
            SectionHeader(
                title: "Product On Sale",
                onSeeAllPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AllProductsScreen()),
                  );
                }),
            FutureBuilder<List<Product>>(
              future: onSaleProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No products available'));
                } else {
                  return ProductSection(products: snapshot.data!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAllPressed;
  const SectionHeader(
      {super.key, required this.title, required this.onSeeAllPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
          ),
          GestureDetector(
            onTap: onSeeAllPressed,
            child: Text(
              'See all',
              style: TextStyle(color: Colors.blue.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductSection extends StatelessWidget {
  final List<Product> products;
  const ProductSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220, // Increase the height to avoid overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
}

class Product {
  final String name;
  final String size;
  final String price;
  final String? image;
  final bool requiresPrescription;

  Product({
    required this.name,
    required this.size,
    required this.price,
    this.image,
    required this.requiresPrescription,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] ?? '',
      size: json['size'] ?? '',
      price: json['price']?.toString() ?? '0',
      image: json['image'],
      requiresPrescription: json['prescription'] == 'need' ? true : false,
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  void showPrescriptionMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You need a prescription to purchase this.'),
      ),
    );
  }

  Future<void> addToCart(Product product, BuildContext context) async {
    if (product.requiresPrescription) {
      showPrescriptionMessage(context);
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    if (userEmail == null) {
      // Handle the case where userEmail is not found
      return;
    }

    final response = await http.post(
      Uri.parse('http://172.20.10.2:3000/api/products/cart/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userEmail': userEmail,
        'productName': product.name,
        'productSize': product.size,
        'productPrice': product.price,
        'productImage': product.image,
        'quantity': 1, // Always add one item at a time
      }),
    );

    if (response.statusCode == 201) {
      // Handle successful addition to cart
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item Added to cart'),
        ),
      );
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add item to cart'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade600, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            color: Colors.grey.shade100,
            child: Center(
              child: widget.product.image != null
                  ? Image.memory(base64Decode(widget.product.image!),
                      fit: BoxFit.cover)
                  : Icon(Icons.image, size: 40, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
          Text(
            widget.product.size,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            "Rs.${widget.product.price}",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () => addToCart(widget.product, context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade600,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
