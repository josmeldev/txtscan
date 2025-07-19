import 'dart:async';
import 'package:flutter/material.dart';
import '../auth_state_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Timer para navegar a AuthStateWrapper después de 3 segundos
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthStateWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2A),
      body: Center(
        child: Image.asset(
          'assets/images/txtscan-logo.png',
          width: 250,
          height: 180,
        ),
      ),
    );
  }
}
