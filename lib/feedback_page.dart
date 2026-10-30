import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'generate_qr_code.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  bool showBadForm = false;
  final nameController = TextEditingController();
  final messageController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _open(Uri uri) async {
    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );
      if (!ok && mounted) _snack('Could not open the link.');
    } catch (_) {
      if (mounted) _snack('Could not open the link.');
    }
  }

  String? _buildMessage() {
    final msg = messageController.text.trim();
    if (msg.isEmpty) {
      _snack('Please type your feedback first.');
      return null;
    }
    final name =
        nameController.text.trim().isEmpty ? 'Guest' : nameController.text.trim();
    return 'Recko Restaurant - Bad Experience Feedback\nName: $name\nMessage: $msg';
  }

  Future<void> _goodReview() => _open(Uri.parse(googleReviewUrl));

  Future<void> _sendWhatsApp() async {
    final text = _buildMessage();
    if (text == null) return;
    await _open(Uri.parse(
        'https://wa.me/$feedbackWhatsAppNumber?text=${Uri.encodeComponent(text)}'));
  }

  Future<void> _sendSms() async {
    final text = _buildMessage();
    if (text == null) return;
    await _open(Uri.parse(
        'sms:$feedbackSmsNumber?body=${Uri.encodeComponent(text)}'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        // Owner shortcut: long-press the title to open the
                        // QR code generator.
                        onLongPress: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GenerateQRCode()),
                        ),
                        child: const Text(
                          'Recko Restaurant',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Kattuwa, Negombo',
                          style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 24),
                      if (!showBadForm) ..._choiceView() else ..._badView(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _choiceView() => [
        const Text(
          'How was your experience with us?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 20),
        _bigButton('😊  I had a great experience', const Color(0xFF16A34A),
            _goodReview),
        const SizedBox(height: 12),
        _bigButton('😞  I had a bad experience', const Color(0xFFDC2626),
            () => setState(() => showBadForm = true)),
      ];

  List<Widget> _badView() => [
        const Text(
          "We're sorry! Tell us what went wrong.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Your name (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: messageController,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Your feedback',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _bigButton('Send via WhatsApp', const Color(0xFF25D366), _sendWhatsApp),
        const SizedBox(height: 10),
        _bigButton('Send as SMS', const Color(0xFF2563EB), _sendSms),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => showBadForm = false),
          child: const Text('Back'),
        ),
      ];

  Widget _bigButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
