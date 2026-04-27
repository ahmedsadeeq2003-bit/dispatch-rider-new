// lib/screens/dispatch_order_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../utils/pricing_utils.dart';

class DispatchOrderScreen extends StatefulWidget {
  const DispatchOrderScreen({super.key});

  @override
  State<DispatchOrderScreen> createState() => _DispatchOrderScreenState();
}

class _DispatchOrderScreenState extends State<DispatchOrderScreen>
    with TickerProviderStateMixin {
  // Text controllers & focus nodes
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  // Debounce timers
  Timer? _debouncePickup;
  Timer? _debounceDest;

  // Suggestions lists
  List<PlaceSuggestion> _pickupSuggestions = [];
  List<PlaceSuggestion> _destSuggestions = [];

  // Whether a suggestion was selected (not just typed)
  bool _pickupSelected = false;
  bool _destSelected = false;

  // Selected coordinates
  double? _pickupLat;
  double? _pickupLon;
  double? _destLat;
  double? _destLon;

  // Package type (determined by weight) & price
  double _computedPrice = 0;

  // Weight input
  final TextEditingController _weightController =
      TextEditingController(text: '1.0');
  double _packageWeight = 1.0;

  // Getter for current package type based on weight
  String get _currentPackageType =>
      _packageWeight < 5.0 ? 'Small Package' : 'Large Package';

  // Draggable sheet controller
  late final DraggableScrollableController _sheetController;

  // Map controller
  late final MapController _mapController;

  // UI states
  bool _showConfirmBar = false;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destController.dispose();
    _pickupFocus.dispose();
    _destFocus.dispose();
    _debouncePickup?.cancel();
    _debounceDest?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  // -------------------------
// Places Autocomplete using Nominatim API
// -------------------------
  Future<List<PlaceSuggestion>> _placesAutocomplete(String input) async {
    if (input.trim().isEmpty || input.trim().length < 2) return [];

    try {
      // First try without forcing Nigeria to get more comprehensive results
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?'
          'q=$input&'
          'format=json&'
          'addressdetails=1&'
          'limit=10&'
          'countrycodes=NG&'
          'bounded=1&'
          'viewbox=6.0,7.0,14.0,11.0' // Bounding box covering Abuja, Kaduna, Adamawa
          );

      final response = await http.get(url, headers: {
        'User-Agent': 'DispatchRiderApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final suggestions = data.map((item) {
          final displayName = item['display_name'] as String;
          final placeId = item['place_id'].toString();
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          return PlaceSuggestion(
            placeId: placeId,
            description: displayName,
            lat: lat,
            lon: lon,
          );
        }).toList();

        // If API returns results, use them; otherwise fall back to local suggestions
        if (suggestions.isNotEmpty) {
          return suggestions;
        }
      }

      // If no results, try with Nigeria appended
      final fallbackUrl =
          Uri.parse('https://nominatim.openstreetmap.org/search?'
              'q=$input,Nigeria&'
              'format=json&'
              'addressdetails=1&'
              'limit=10&'
              'countrycodes=NG&'
              'bounded=1&'
              'viewbox=6.0,7.0,14.0,11.0');

      final fallbackResponse = await http.get(fallbackUrl, headers: {
        'User-Agent': 'DispatchRiderApp/1.0',
      });

      if (fallbackResponse.statusCode == 200) {
        final data = json.decode(fallbackResponse.body) as List;
        final suggestions = data.map((item) {
          final displayName = item['display_name'] as String;
          final placeId = item['place_id'].toString();
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          return PlaceSuggestion(
            placeId: placeId,
            description: displayName,
            lat: lat,
            lon: lon,
          );
        }).toList();

        if (suggestions.isNotEmpty) {
          return suggestions;
        }
      }

      // Fallback to local suggestions for Abuja, Kaduna, and Adamawa
      return _getFallbackSuggestions(input);
    } catch (e) {
      // Fallback suggestions
      return _getFallbackSuggestions(input);
    }
  }

  // Fallback suggestions for Abuja, Kaduna, and Adamawa areas
  List<PlaceSuggestion> _getFallbackSuggestions(String input) {
    final allLocations = [
      // Abuja locations
      'Gaduwa Estate, Abuja, Nigeria',
      'Idu Life Camp, Abuja, Nigeria',
      'Wuse II, Abuja, Nigeria',
      'Maitama, Abuja, Nigeria',
      'Asokoro, Abuja, Nigeria',
      'Garki, Abuja, Nigeria',
      'Kubwa, Abuja, Nigeria',
      'Lugbe, Abuja, Nigeria',
      'Mpape, Abuja, Nigeria',
      'Nyanya, Abuja, Nigeria',
      'Jahi, Abuja, Nigeria',
      'Karu, Abuja, Nigeria',
      'Abaji, Abuja, Nigeria',
      'Bwari, Abuja, Nigeria',
      'Gwagwalada, Abuja, Nigeria',
      // Kaduna locations
      'Kaduna Central, Kaduna, Nigeria',
      'Barnawa, Kaduna, Nigeria',
      'Sabon Gari, Kaduna, Nigeria',
      'Tudun Wada, Kaduna, Nigeria',
      'Ungwan Rimi, Kaduna, Nigeria',
      'Kawo, Kaduna, Nigeria',
      'Zaria Road, Kaduna, Nigeria',
      'Kafanchan, Kaduna, Nigeria',
      'Zaria, Kaduna, Nigeria',
      // Adamawa locations
      'Yola, Adamawa, Nigeria',
      'Jimeta, Adamawa, Nigeria',
      'Mubi, Adamawa, Nigeria',
      'Numan, Adamawa, Nigeria',
      'Ganye, Adamawa, Nigeria',
      'Song, Adamawa, Nigeria',
      'Maiha, Adamawa, Nigeria',
      'Hong, Adamawa, Nigeria',
      'Gombi, Adamawa, Nigeria',
    ];

    return allLocations
        .where(
            (location) => location.toLowerCase().contains(input.toLowerCase()))
        .take(8)
        .map((location) => PlaceSuggestion(
              placeId: location,
              description: location,
            ))
        .toList();
  }

  // -------------------------
  // Debounced typing handlers
  // -------------------------
  void _onPickupChanged(String v) {
    _pickupSelected = false;
    _showConfirmBar = false;
    _debouncePickup?.cancel();
    _debouncePickup = Timer(const Duration(milliseconds: 300), () async {
      final results = await _placesAutocomplete(_pickupController.text.trim());
      if (mounted) {
        setState(() => _pickupSuggestions = results);
      }
    });
  }

  void _onDestChanged(String v) {
    _destSelected = false;
    _showConfirmBar = false;
    _debounceDest?.cancel();
    _debounceDest = Timer(const Duration(milliseconds: 300), () async {
      final results = await _placesAutocomplete(_destController.text.trim());
      if (mounted) {
        setState(() => _destSuggestions = results);
      }
    });
  }

  // -------------------------
  // When user selects suggestion
  // -------------------------
  void _selectPickup(PlaceSuggestion s) {
    _pickupController.text = s.description;
    _pickupLat = s.lat;
    _pickupLon = s.lon;
    _pickupSuggestions = [];
    _pickupSelected = true;

    // DEBUG: Print coordinates when pickup is selected
    print('DEBUG: Pickup selected - Lat: ${s.lat}, Lon: ${s.lon}');

    if (mounted) {
      FocusScope.of(context).requestFocus(_destFocus);
    }
    _maybeShowConfirmPanel();
  }

  void _selectDest(PlaceSuggestion s) {
    _destController.text = s.description;
    _destLat = s.lat;
    _destLon = s.lon;
    _destSuggestions = [];
    _destSelected = true;

    // DEBUG: Print coordinates when destination is selected
    print('DEBUG: Destination selected - Lat: ${s.lat}, Lon: ${s.lon}');

    _destFocus.unfocus();
    _maybeShowConfirmPanel();
  }

  // -------------------------
  // Called when both pickup & dest are chosen
  // -------------------------
  void _maybeShowConfirmPanel() {
    final both = _pickupSelected && _destSelected;
    if (!both) {
      setState(() {
        _showConfirmBar = false;
      });
      return;
    }

    // compute price (mock calculation)
    _calculatePrice();

    setState(() {
      _showConfirmBar = true;
    });

    // expand the sheet to medium
    try {
      _sheetController.animateTo(0.45,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (_) {}
  }

  // -------------------------
// Price calculation using PricingUtils
  // -------------------------
  void _calculatePrice() {
    _computedPrice = PricingUtils.calculatePrice(
      pickupLocation: _pickupController.text,
      destinationLocation: _destController.text,
      pickupLat: _pickupLat,
      pickupLon: _pickupLon,
      destLat: _destLat,
      destLon: _destLon,
    );
  }

  // -------------------------
  // Actions
  // -------------------------
  void _confirmOrder() {
    if (mounted) {
      Navigator.pushNamed(context, '/confirmdelivery', arguments: {
        'pickup': _pickupController.text,
        'destination': _destController.text,
        'pickupLatLng': _pickupLat != null && _pickupLon != null
            ? LatLng(_pickupLat!, _pickupLon!)
            : null,
        'destinationLatLng': _destLat != null && _destLon != null
            ? LatLng(_destLat!, _destLon!)
            : null,
      });
    }
  }

  // -------------------------
  // Build UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          // OSM Map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter:
                  LatLng(9.5, 8.5), // Center point for Abuja, Kaduna, Adamawa
              initialZoom: 7.5, // Zoom level to show all three cities
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dispatch_rider_new',
              ),
            ],
          ),

          // Draggable bottom sheet (floating panel)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.18, // collapsed height
            minChildSize: 0.12,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Material(
                elevation: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // drag indicator
                        Container(
                            width: 40,
                            height: 6,
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 12),

                        // top input rows (pickup/dest)
                        _buildFloatingInput(
                          controller: _pickupController,
                          focusNode: _pickupFocus,
                          hint: 'Pickup Location',
                          icon: Icons.circle,
                          iconColor: Colors.black,
                          suggestions: _pickupSuggestions,
                          onChanged: _onPickupChanged,
                          onSelect: _selectPickup,
                        ),
                        const SizedBox(height: 8),
                        _buildFloatingInput(
                          controller: _destController,
                          focusNode: _destFocus,
                          hint: 'Destination',
                          icon: Icons.circle,
                          iconColor: Colors.red,
                          suggestions: _destSuggestions,
                          onChanged: _onDestChanged,
                          onSelect: _selectDest,
                        ),

                        const SizedBox(height: 12),

                        // confirm order button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _confirmOrder,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Confirm Order'),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // space at bottom so sheet can expand comfortably
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------
  // Floating panel sub-widgets
  // -------------------------
  Widget _buildFloatingInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required List<PlaceSuggestion> suggestions,
    required ValueChanged<String> onChanged,
    required ValueChanged<PlaceSuggestion> onSelect,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onSubmitted: (_) {
            // user pressed done — hide suggestions and try to show confirm if both selected
            if (controller == _pickupController) {
              _pickupSuggestions = [];
            }
            if (controller == _destController) {
              _destSuggestions = [];
            }
            setState(() {});
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor),
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: suggestions.map((s) {
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child:
                        const Icon(Icons.location_on, color: Colors.deepPurple),
                  ),
                  title: Text(s.description,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tap to select',
                      style: TextStyle(fontSize: 12)),
                  onTap: () => onSelect(s),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _packageTile(String name, String subtitle, double price) {
    final selected = _currentPackageType == name;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? Colors.deepPurple : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        selected ? Colors.deepPurple : Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// Simple data holder
class PlaceSuggestion {
  final String placeId;
  final String description;
  final double? lat;
  final double? lon;
  const PlaceSuggestion(
      {required this.placeId, required this.description, this.lat, this.lon});
}
