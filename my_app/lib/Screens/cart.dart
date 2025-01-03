import 'package:flutter/material.dart';
import 'package:my_app/Screens/home.dart';
import 'package:my_app/Screens/presorder.dart';
import 'package:my_app/Screens/profile.dart';
import 'package:my_app/Screens/report.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/Screens/checkout.dart'
    as checkout; // Add this import with alias
import 'package:my_app/Models/cart_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CartPage(),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int _selectedIndex = 2;
  late Future<List<CartItem>> cartItems;

  @override
  void initState() {
    super.initState();
    cartItems = fetchCartItems();
  }

  Future<List<CartItem>> fetchCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    if (userEmail == null) {
      throw Exception('User email not found');
    }

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/api/products/cart?userEmail=$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> cartJson = json.decode(response.body);
        return cartJson.map((json) => CartItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cart items');
      }
    } catch (e) {
      throw Exception('Error fetching cart items: $e');
    }
  }

  Future<void> removeCartItem(String productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    if (userEmail == null) {
      throw Exception('User email not found');
    }

    try {
      final response = await http.delete(
        Uri.parse(
            'http://10.0.2.2:3000/api/products/del/cart?userEmail=$userEmail&product_id=$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          cartItems = fetchCartItems();
        });
      } else {
        throw Exception('Failed to remove cart item');
      }
    } catch (e) {
      throw Exception('Error removing cart item: $e');
    }
  }

  // Calculate the subtotal of selected items
  double calculateSubtotal(List<CartItem> items) {
    return items
        .where((item) => item.selected)
        .fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void updateQuantity(List<CartItem> items, int index, int delta) {
    setState(() {
      items[index].quantity = (items[index].quantity + delta).clamp(1, 999);
    });
  }

  void toggleAllSelection(List<CartItem> items, bool? value) {
    setState(() {
      for (var item in items) {
        item.selected = value ?? false;
      }
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Prevent redundant navigation

    setState(() {
      _selectedIndex = index;
    });

    switch (_selectedIndex) {
      case 0:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
        break;
      case 1:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const ReportPage()));
        break;
      case 2:
        // Stay on Cart
        break;
      case 3:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()));
        break;
    }
  }

  void _navigateToCheckout(
      BuildContext context, double subtotal, List<CartItem> items) {
    final selectedItems = items.where((item) => item.selected).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            checkout.CheckoutScreen(subtotal: subtotal, items: selectedItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back arrow
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('My Cart'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<CartItem>>(
              future: cartItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No items in cart'));
                }

                final items = snapshot.data!;

                return Column(
                  children: [
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CheckboxListTile(
                        title: const Text('Select All'),
                        value: items.every((item) => item.selected),
                        onChanged: (value) => toggleAllSelection(items, value),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: item.selected,
                                    onChanged: (value) {
                                      setState(() {
                                        item.selected = value ?? false;
                                      });
                                    },
                                  ),
                                  item.image.isNotEmpty
                                      ? Image.memory(
                                          base64Decode(item.image),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.image, size: 50),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${item.ml}ml - Rs.${item.price}'),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            updateQuantity(items, index, -1),
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        onPressed: () =>
                                            updateQuantity(items, index, 1),
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () => removeCartItem(item.id),
                                    icon: const Icon(Icons.delete),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          FutureBuilder<List<CartItem>>(
            future: cartItems,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final items = snapshot.data!;
                final subtotal = calculateSubtotal(items);
                return Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFEAF4FF),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal: Rs.$subtotal',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      ElevatedButton(
                        onPressed: () =>
                            _navigateToCheckout(context, subtotal, items),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Check Out',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrderStatusPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8), // Less rounded corners
                ),
              ),
              child: const Text('Move to Prescription order status',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: "Reports"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
