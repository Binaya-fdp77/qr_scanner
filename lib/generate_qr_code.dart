import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'config.dart';

/// Owner-only screen: shows the QR code to print for the table / counter.
/// Open it by long-pressing the "Recko Restaurant" title on the main page.
class GenerateQRCode extends StatefulWidget {
  const GenerateQRCode({super.key});

  @override
  State<GenerateQRCode> createState() => _GenerateQRCodeState();
}

class _GenerateQRCodeState extends State<GenerateQRCode> {
  late final TextEditingController controller =
      TextEditingController(text: hostedAppUrl);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recko QR Code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (controller.text.trim().isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(data: controller.text.trim(), size: 240),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Website address for the QR code',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              const Text(
                'Take a screenshot of the QR code to print it.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
