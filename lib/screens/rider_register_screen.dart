import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';

class RiderRegisterScreen extends StatefulWidget {
  const RiderRegisterScreen({super.key});

  @override
  State<RiderRegisterScreen> createState() => _RiderRegisterScreenState();
}

class _RiderRegisterScreenState extends State<RiderRegisterScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _register() async {
    setState(() => _loading = true);
    final error = await _authService.registerRider(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      context: context,
    );
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            // 🎞️ Lottie animation
            Lottie.asset('assets/animations/Delivery Riding.json', height: 180),
            const SizedBox(height: 20),

            const Text(
              "Rider Registration",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Join as a rider and start accepting delivery orders!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // 🧍 Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),

            // 📧 Email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),

            // 🔒 Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),

            // 🚀 Register Button
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            // 🔁 Login Redirect
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/rider-login'),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
