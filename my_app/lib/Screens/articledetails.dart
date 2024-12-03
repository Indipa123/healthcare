import 'package:flutter/material.dart';

class ArticleDetailPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String date;
  final String readTime;

  const ArticleDetailPage({
    super.key,
    required this.imagePath,
    required this.title,
    required this.date,
    required this.readTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Article Detail",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Displaying the article image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              // Displaying title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // Displaying date and read time
              Text(
                "$date · $readTime",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              // Displaying article description
              const Text(
                "Fruits are nature’s sweet treats, packed with vitamins, antioxidants, and fibre, making them a vital part of a healthy diet. Here’s a list of the 25 healthiest fruits that you should consider adding to your daily meals, as recommended by nutritionists.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              // List of fruits
              ..._buildFruitList(),
              const SizedBox(height: 20),
              // Final paragraph
              const Text(
                "Including a variety of these fruits in your diet can help provide essential nutrients that support overall health and well-being. Whether you enjoy them fresh, in smoothies, or as part of salads, fruits are a delicious way to nourish your body naturally.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to create a list of fruits
  List<Widget> _buildFruitList() {
    final fruits = [
      {
        "name": "Blueberries",
        "description":
            "Rich in antioxidants, particularly anthocyanins, they help reduce inflammation and support brain health."
      },
      {
        "name": "Apples",
        "description":
            "A great source of fibre and vitamin C, apples promote gut health and lower the risk of heart disease."
      },
      {
        "name": "Bananas",
        "description":
            "Loaded with potassium, bananas help maintain normal blood pressure and heart function."
      },
      {
        "name": "Oranges",
        "description":
            "High in vitamin C, they boost the immune system and support skin health."
      },
      {
        "name": "Strawberries",
        "description":
            "Packed with antioxidants, vitamin C, and manganese, strawberries help protect the heart and control blood sugar."
      },
      {
        "name": "Avocados",
        "description":
            "Rich in heart-healthy fats, they also provide fiber, potassium, and vitamins C, E, and K."
      },
      {
        "name": "Pomegranates",
        "description":
            "Known for their anti-inflammatory properties, they support heart health and reduce cancer risk."
      },
      {
        "name": "Grapes",
        "description":
            "Full of antioxidants like resveratrol, grapes help protect the heart and brain."
      },
      {
        "name": "Cherries",
        "description":
            "High in antioxidants and anti-inflammatory compounds, cherries aid in sleep and muscle recovery."
      },
      {
        "name": "Pineapple",
        "description":
            "Rich in bromelain, an enzyme that aids digestion and has anti-inflammatory properties."
      },
      {
        "name": "Mangoes",
        "description":
            "A tropical favorite, they’re loaded with vitamins A and C, promoting eye and skin health."
      },
      {
        "name": "Watermelon",
        "description":
            "Hydrating and full of lycopene, watermelon supports heart health and lowers inflammation."
      },
      {
        "name": "Kiwi",
        "description":
            "Packed with vitamin C and fibre, kiwi boosts immune health and aids digestion."
      },
      {
        "name": "Papaya",
        "description":
            "Rich in digestive enzymes and vitamin C, papaya supports digestive health and skin care."
      },
      {
        "name": "Cranberries",
        "description":
            "Known for their role in preventing urinary tract infections, cranberries are also packed with antioxidants."
      },
      {
        "name": "Pears",
        "description":
            "With their high fibre content, pears help promote digestion and prevent constipation."
      },
      {
        "name": "Raspberries",
        "description":
            "These tiny berries are high in fibre and vitamin C, promoting heart health and improving digestion."
      },
      {
        "name": "Guava",
        "description":
            "A tropical fruit rich in fibre and vitamin C, guava helps maintain healthy blood sugar and cholesterol levels."
      },
    ];

    return fruits
        .map((fruit) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(
                      text: "${fruits.indexOf(fruit) + 1}. ${fruit['name']} : ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: fruit['description']),
                  ],
                ),
              ),
            ))
        .toList();
  }
}
