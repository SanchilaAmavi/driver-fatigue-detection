import 'package:flutter/material.dart';
import '../widgets/map_widget.dart';

class FullMapScreen extends StatelessWidget {
  const FullMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Trip Map',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: const SafeArea(
        child: MapWidget(),
      ),
    );
  }
}