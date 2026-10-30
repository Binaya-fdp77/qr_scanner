import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'generate_qr_code.dart';

enum _Step { choice, bad, thanks }

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  _Step step = _Step.choice;
  bool sending = false;

  final issues = <String>{};
  final commentController = TextEditingController();
  final phoneController = TextEditingController();

  static const options = [
    'Food',
    'Service',
    'Waiting time',
    'Cleanliness',
    'Price',
    'Other',
  ];

  @override
  void dispose() {
    commentController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  // One tap -> straight to the Google review page.
  Future<void> _goodReview() async {
    await launchUrl(
      Uri.parse(googleReviewUrl),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );
  }

  // One tap -> message is sent to the owner in the background.
  Future<void> _sendBad() async {
    if (issues.isEmpty && commentController.text.trim().isEmpty) {
      _snack('Please select what went wrong.');
      return;
    }
    setState(() => sending = true);
    try {
      final body = 'Issues: ${issues.isEmpty ? '-' : issues.join(', ')}\n'
          'Comment: ${commentController.text.trim().isEmpty ? '-' : commentController.text.trim()}\n'
          'Customer phone: ${phoneController.text.trim().isEmpty ? '-' : phoneController.text.trim()}';

      final res = await http.post(
        Uri.parse('https://api.web3forms.com/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_key': web3formsKey,
          'subject': 'Recko Restaurant - Bad Experience Feedback',
          'from_name': 'Recko Feedback',
          'message': body,
        }),
      );
      if (res.statusCode == 200) {
        if (mounted) setState(() => step = _Step.thanks);
      } else {
        _snack('Could not send. Please try again.');
      }
    } catch (_) {
      _snack('No internet connection. Please try again.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
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
                      switch (step) {
                        _Step.choice => _choice(),
                        _Step.bad => _bad(),
                        _Step.thanks => _thanks(),
                      },
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

  Widget _choice() => Column(children: [
        const Text('How was your visit?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        _bigButton('😊  Great!', const Color(0xFF16A34A), _goodReview),
        const SizedBox(height: 12),
        _bigButton('😞  Not good', const Color(0xFFDC2626),
            () => setState(() => step = _Step.bad)),
      ]);

  Widget _bad() => Column(children: [
        const Text("Sorry about that! What went wrong?",
            textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(o),
                selected: issues.contains(o),
                onSelected: (v) =>
                    setState(() => v ? issues.add(o) : issues.remove(o)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: commentController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Tell us more (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Your phone number (optional, if you want us to call)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _bigButton(sending ? 'Sending...' : 'Send',
            const Color(0xFFDC2626), sending ? null : _sendBad),
        TextButton(
          onPressed: () => setState(() => step = _Step.choice),
          child: const Text('Back'),
        ),
      ]);

  Widget _thanks() => const Column(children: [
        Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 64),
        SizedBox(height: 12),
        Text('Thank you!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text("We've received your feedback and will do better.",
            textAlign: TextAlign.center),
      ]);

  Widget _bigButton(String label, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}