import 'package:flutter/material.dart';

class RiderDetailsScreen extends StatelessWidget {
  const RiderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;

    final riderName = args["riderName"];
    final riderRating = args["riderRating"];
    final riderBike = args["riderBike"];
    final eta = args["eta"];
    final pickup = args["pickup"];
    final destination = args["destination"];
    final package = args["package"];
    final price = args["price"];
    final weight = args["weight"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rider Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // RIDER CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(riderName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Rating: ⭐ $riderRating"),
                      Text("Bike: $riderBike"),
                      Text("ETA: $eta"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // TRIP INFO
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pickup:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(pickup),
                  const SizedBox(height: 12),
                  const Text("Destination:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(destination),
                  const SizedBox(height: 12),
                  const Text("Package:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(package),
                  const SizedBox(height: 12),
                  const Text("Weight:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${weight} kg"),
                  const SizedBox(height: 12),
                  const Text("Price:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("₦${price.toStringAsFixed(0)}"),
                ],
              ),
            ),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {},
              child: const Text("Start Delivery"),
            ),

            const SizedBox(height: 10),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.deepPurple),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
