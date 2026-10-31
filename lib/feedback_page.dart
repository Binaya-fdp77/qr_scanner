import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'brand.dart';
import 'config.dart';

enum _Step { choice, good, bad, thanks }

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  _Step step = _Step.choice;
  bool sending = false;
  final issues = <String>{};
  final comment = TextEditingController();

  static const options = {
    'Food': Icons.restaurant_menu,
    'Service': Icons.room_service,
    'Waiting time': Icons.timer,
    'Cleanliness': Icons.cleaning_services,
    'Price': Icons.payments,
    'Other': Icons.more_horiz,
  };

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _openGoogle() => launchUrl(
        Uri.parse(googleReviewUrl),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );

  Future<void> _sendBad() async {
    if (issues.isEmpty && comment.text.trim().isEmpty) {
      _snack('Please select what went wrong.');
      return;
    }
    setState(() => sending = true);
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'issues': issues.toList(),
        'comment': comment.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      }).timeout(const Duration(seconds: 15));
      if (mounted) setState(() => step = _Step.thanks);
    } catch (_) {
      _snack('Could not send. Please check your internet and try again.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Brand.gradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(),
                    const SizedBox(height: 14),
                    const Text('Recko Restaurant',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Brand.dark)),
                    const SizedBox(height: 2),
                    const Text('Kattuwa, Negombo',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 26),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(step),
                        child: switch (step) {
                          _Step.choice => _choice(),
                          _Step.good => _good(),
                          _Step.bad => _bad(),
                          _Step.thanks => _thanks(),
                        },
                      ),
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

  Widget _choice() => Column(children: [
        const Text('How was your visit?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Your feedback helps us improve',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 22),
        BigButton(
            label: 'Loved it!',
            icon: Icons.sentiment_very_satisfied,
            color: Brand.green,
            onPressed: () => setState(() => step = _Step.good)),
        const SizedBox(height: 12),
        BigButton(
            label: 'Not so good',
            icon: Icons.sentiment_dissatisfied,
            color: Brand.red,
            onPressed: () => setState(() => step = _Step.bad)),
      ]);

  Widget _good() => Column(children: [
        const Text('Thank you! 🎉',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const Text('On the next page, tap the 5th star and press Post.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
        const SizedBox(height: 14),
        const Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 20),
        BigButton(
            label: 'Open Google Reviews',
            icon: Icons.open_in_new,
            color: Brand.green,
            onPressed: _openGoogle),
        TextButton(
            onPressed: () => setState(() => step = _Step.choice),
            child: const Text('Back')),
      ]);

  Widget _bad() => Column(children: [
        const Text("We're sorry! What went wrong?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock, size: 14, color: Colors.black45),
          SizedBox(width: 4),
          Text('100% anonymous. Only the owner sees this.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final e in options.entries)
              FilterChip(
                avatar: Icon(e.value, size: 18),
                label: Text(e.key),
                selected: issues.contains(e.key),
                selectedColor: const Color(0xFFFED7AA),
                onSelected: (v) => setState(
                    () => v ? issues.add(e.key) : issues.remove(e.key)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: comment,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: 'Tell us more (optional)',
            filled: true,
            fillColor: const Color(0xFFFFF7ED),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        BigButton(
            label: sending ? 'Sending...' : 'Send anonymously',
            icon: Icons.send,
            color: Brand.red,
            onPressed: sending ? null : _sendBad),
        TextButton(
            onPressed: () => setState(() => step = _Step.choice),
            child: const Text('Back')),
      ]);

  Widget _thanks() => const Column(children: [
        Icon(Icons.check_circle, color: Brand.green, size: 70),
        SizedBox(height: 12),
        Text('Message sent ✓',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text("Thank you for telling us. We'll make it right.",
            textAlign: TextAlign.center),
      ]);
}