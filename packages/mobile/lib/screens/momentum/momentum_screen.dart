import 'package:flutter/material.dart';

class MomentumScreen extends StatelessWidget {
  const MomentumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1% Better Momentum'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Momentum Score',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Coming Soon'),
          ],
        ),
      ),
    );
  }
}

