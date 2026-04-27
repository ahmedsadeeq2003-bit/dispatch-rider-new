import 'package:flutter/material.dart';

class CompletedDeliveriesScreen extends StatelessWidget {
  const CompletedDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for completed deliveries
    final completedDeliveries = [
      {
        'id': 'ORD001',
        'pickup': 'Lagos Island',
        'destination': 'Victoria Island',
        'distance': 5.2,
        'weight': 2.5,
        'packageType': 'Small Package',
        'price': 1500,
        'rating': 5.0,
        'completedAt': '2024-01-15 14:30',
        'customerFeedback': 'Great service!',
      },
      {
        'id': 'ORD002',
        'pickup': 'Ikeja',
        'destination': 'Surulere',
        'distance': 8.1,
        'weight': 6.0,
        'packageType': 'Large Package',
        'price': 3200,
        'rating': 4.8,
        'completedAt': '2024-01-15 12:15',
        'customerFeedback': 'Package arrived on time',
      },
      {
        'id': 'ORD003',
        'pickup': 'Abuja Central',
        'destination': 'Wuse',
        'distance': 3.8,
        'weight': 1.2,
        'packageType': 'Small Package',
        'price': 1200,
        'rating': 4.9,
        'completedAt': '2024-01-15 10:45',
        'customerFeedback': 'Excellent rider!',
      },
      {
        'id': 'ORD004',
        'pickup': 'Port Harcourt',
        'destination': 'GRA Phase 2',
        'distance': 12.5,
        'weight': 4.0,
        'packageType': 'Small Package',
        'price': 2800,
        'rating': 5.0,
        'completedAt': '2024-01-14 16:20',
        'customerFeedback': 'Very professional',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Deliveries'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: completedDeliveries.length,
        itemBuilder: (context, index) {
          final delivery = completedDeliveries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order ${delivery['id']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pickup: ${delivery['pickup']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Destination: ${delivery['destination']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${delivery['distance']} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${delivery['weight']} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${delivery['packageType']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₦${delivery['price']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${delivery['rating']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completed: ${delivery['completedAt']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '"${delivery['customerFeedback']}"',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
