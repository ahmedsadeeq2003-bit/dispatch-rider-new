import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/delivery_service.dart';
import '../utils/pricing_utils.dart';
import '../services/tenant_service.dart';

class ConfirmDeliveryScreen extends StatefulWidget {
  const ConfirmDeliveryScreen({Key? key}) : super(key: key);

  @override
  _ConfirmDeliveryScreenState createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends State<ConfirmDeliveryScreen> {
  String pickup = "";
  String destination = "";
  LatLng? pickupLatLng;
  LatLng? destinationLatLng;
  double price = 0.0;
  String paymentMethod = 'cash';
  double weight = 1.0;
  String package = "Package";

  bool searchingForRider = false;
  String? deliveryId;
  Stream<DocumentSnapshot>? deliveryStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments as Map;

    pickup = args["pickup"];
    destination = args["destination"];
    pickupLatLng = args["pickupLatLng"];
    destinationLatLng = args["destinationLatLng"];

    // Calculate price based on locations
    price = PricingUtils.calculatePrice(
      pickupLocation: pickup,
      destinationLocation: destination,
      pickupLat: pickupLatLng?.latitude,
      pickupLon: pickupLatLng?.longitude,
      destLat: destinationLatLng?.latitude,
      destLon: destinationLatLng?.longitude,
    );
  }

  void requestRider() async {
    setState(() {
      searchingForRider = true;
    });

    try {
      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to continue')),
        );
        setState(() {
          searchingForRider = false;
        });
        return;
      }

      // Create delivery request and notify riders
      final companyId = await TenantService.requireCurrentCompanyId();

      deliveryId = await DeliveryService.createDeliveryRequest(
        clientId: user.uid,
        companyId: companyId,
        pickupLocation: pickup,
        destination: destination,
        weight: weight,
        packageType: package,
        price: price,
        paymentMethod: paymentMethod,
        pickupLat: pickupLatLng?.latitude,
        pickupLon: pickupLatLng?.longitude,
        destLat: destinationLatLng?.latitude,
        destLon: destinationLatLng?.longitude,
      );

      // Set up stream to listen for delivery status changes
      deliveryStream = FirebaseFirestore.instance
          .collection('deliveries')
          .doc(deliveryId)
          .snapshots();

      deliveryStream!.listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final status = data['status'];

          if (status == 'accepted' && mounted) {
            // Get rider details
            final riderId = data['riderId'];
            // Navigate to rider details screen
            Navigator.pushReplacementNamed(context, '/riderdetails',
                arguments: {
                  'riderId': riderId,
                  'pickup': pickup,
                  'destination': destination,
                  'package': package,
                  'price': price,
                  'weight': weight,
                });
          }
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Delivery request sent! Waiting for rider to accept...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating delivery request: $e')),
      );
      setState(() {
        searchingForRider = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Delivery"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text("Pickup:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(pickup, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text("Destination:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(destination, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text("Price:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("₦${price.toStringAsFixed(0)}",
                style: TextStyle(fontSize: 16, color: Colors.blue)),
            const SizedBox(height: 20),
            Text("Payment Method:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Cash'),
                  value: 'cash',
                  groupValue: paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      paymentMethod = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Card'),
                  value: 'card',
                  groupValue: paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      paymentMethod = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!searchingForRider)
              Center(
                child: ElevatedButton(
                  onPressed: requestRider,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                  ),
                  child: const Text(
                    "Confirm & Search for Rider",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            if (searchingForRider)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(width: 12),
                    Text(
                      "Looking for rider...",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
