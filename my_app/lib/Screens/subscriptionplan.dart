import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SubscriptionScreen(),
    );
  }
}

class SubscriptionScreen extends StatelessWidget {
  final List<String> features = [
    "Unlimited access to licensed therapists",
    "Secure, private and confidential",
    "Easy and convenient"
  ];

  final List<SubscriptionPlan> plans = [
    SubscriptionPlan('One Month', '2000', '/month'),
    SubscriptionPlan('Three Months', '6000', '/3 month'),
    SubscriptionPlan('Annual', '18000', '/year'),
  ];

  SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Handle close button action
          },
        ),
        title: const Text(
          'Choose a plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your subscription helps us keep the lights on and improve our products.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Column(
              children: features
                  .map((feature) => FeatureTile(feature: feature))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Column(
              children: plans
                  .map((plan) => SubscriptionPlanTile(
                        plan: plan,
                        onTap: () {
                          // Handle plan selection
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final String feature;

  const FeatureTile({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionPlan {
  final String name;
  final String price;
  final String period;

  SubscriptionPlan(this.name, this.price, this.period);
}

class SubscriptionPlanTile extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onTap;

  const SubscriptionPlanTile(
      {super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Rs ${plan.price}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  plan.period,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
