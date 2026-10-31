import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'config.dart';
import 'theme.dart';

/// Owner-only: shows the QR code to print. Opened from the admin dashboard.
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
      appBar: AppBar(
        title: const Text('Recko QR Code'),
        backgroundColor: Colors.transparent,
      ),
      body: BrandBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.text.trim().isNotEmpty)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: controller.text.trim(),
                          size: 240,
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Website address for the QR code',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Screenshot this QR code to print it.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}