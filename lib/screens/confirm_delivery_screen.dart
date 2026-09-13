import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/delivery_service.dart';
import '../utils/pricing_utils.dart';
import '../theme/app_theme.dart';

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
  Stream<Map<String, dynamic>?>? deliveryStream;

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
      final user = Supabase.instance.client.auth.currentUser;
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
      deliveryId = await DeliveryService.createDeliveryRequest(
        clientId: user.id,
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
      deliveryStream = DeliveryService.getDelivery(deliveryId!);

      deliveryStream!.listen((data) {
        if (data != null) {
          final status = data['status'];

          if (status == 'accepted' && mounted) {
            // Get rider details
            final riderId = data['rider_id'];
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Confirm Delivery")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text("Pickup:", style: AppText.h3),
            Text(pickup, style: AppText.body),
            const SizedBox(height: AppSpacing.md),
            Text("Destination:", style: AppText.h3),
            Text(destination, style: AppText.body),
            const SizedBox(height: AppSpacing.md),
            Text("Price:", style: AppText.h3),
            Text("₦${price.toStringAsFixed(0)}",
                style: AppText.h2.copyWith(color: AppColors.success)),
            const SizedBox(height: AppSpacing.md),
            Text("Payment Method:", style: AppText.h3),
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
            const SizedBox(height: AppSpacing.md),
            if (!searchingForRider)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: requestRider,
                  child: const Text("Confirm & Search for Rider"),
                ),
              ),
            if (searchingForRider)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.info),
                    const SizedBox(width: 12),
                    Text("Looking for rider...", style: AppText.h3),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
