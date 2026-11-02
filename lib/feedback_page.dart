import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'theme.dart';

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
  final contact = TextEditingController();

  static const options = <String, IconData>{
    'Food': Icons.restaurant_menu,
    'Service': Icons.room_service_outlined,
    'Waiting time': Icons.timer_outlined,
    'Cleanliness': Icons.cleaning_services_outlined,
    'Price': Icons.payments_outlined,
    'Other': Icons.more_horiz,
  };

  @override
  void dispose() {
    comment.dispose();
    contact.dispose();
    super.dispose();
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _openReview() => launchUrl(
        Uri.parse(googleReviewUrl),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );

  Future<void> _send() async {
    if (issues.isEmpty && comment.text.trim().isEmpty) {
      _snack('Please select what went wrong.');
      return;
    }
    setState(() => sending = true);
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'issues': issues.toList(),
        'comment': comment.text.trim(),
        'contact': contact.text.trim(),
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
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
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 96),
                    const SizedBox(height: 16),
                    Text('Recko Restaurant',
                        style: t.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700, color: Brand.deep)),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 16, color: Brand.ember),
                        SizedBox(width: 4),
                        Text('Kattuwa, Negombo',
                            style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(
                                    begin: const Offset(0, .04),
                                    end: Offset.zero)
                                .animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(step),
                          child: switch (step) {
                            _Step.choice => _choice(t),
                            _Step.good => _good(t),
                            _Step.bad => _bad(t),
                            _Step.thanks => _thanks(t),
                          },
                        ),
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

  // ---------- Step 1 ----------
  Widget _choice(TextTheme t) => Column(
        children: [
          Text('How was your visit?',
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('It takes less than 30 seconds',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 22),
          _BigChoice(
            emoji: '😊',
            title: 'It was great!',
            subtitle: 'Rate us on Google',
            colors: const [Color(0xFF22C55E), Color(0xFF15803D)],
            onTap: _openReview,
          ),
          const SizedBox(height: 14),
          _BigChoice(
  emoji: '😞',
  title: 'Not so good',
  subtitle: '🔒 100% anonymous',
  colors: const [Color(0xFFF97316), Color(0xFFC2410C)],
  onTap: () => setState(() => step = _Step.bad),
),
        ],
      );

  // ---------- Good ----------
  Widget _good(TextTheme t) => Column(
        children: [
          Text('Thank you! 🎉',
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Share your experience on Google.\nIt takes just 10 seconds and means a lot to us.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 5; i++)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + i * 150),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: const Icon(Icons.star_rounded,
                      size: 44, color: Color(0xFFF59E0B)),
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _openReview,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Google Reviews'),
              style: FilledButton.styleFrom(
                backgroundColor: Brand.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => step = _Step.choice),
            child: const Text('Back'),
          ),
        ],
      );

  // ---------- Bad ----------
  Widget _bad(TextTheme t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text("We're sorry 💔",
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'What went wrong? Only our owner will see this.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Brand.green.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Brand.green),
                  SizedBox(width: 6),
                  Text(
                    'Your feedback is 100% anonymous',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Brand.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in options.entries)
                FilterChip(
                  showCheckmark: false,
                  avatar: Icon(e.value,
                      size: 18,
                      color: issues.contains(e.key)
                          ? Brand.ember
                          : Colors.black45),
                  label: Text(e.key),
                  selected: issues.contains(e.key),
                  selectedColor: Brand.ember.withValues(alpha: .14),
                  backgroundColor: const Color(0xFFFFFBF7),
                  side: BorderSide(
                      color: issues.contains(e.key)
                          ? Brand.ember
                          : const Color(0xFFE7E5E4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) => setState(
                      () => v ? issues.add(e.key) : issues.remove(e.key)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: comment,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Tell us more (optional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contact,
            keyboardType: TextInputType.phone,
            maxLength: 40,
            decoration: const InputDecoration(
              hintText: 'Phone – only if you want us to call you back',
              prefixIcon: Icon(Icons.phone_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: sending ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: Brand.ember,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              child: sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Send anonymously'),
                      ],
                    ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => setState(() => step = _Step.choice),
              child: const Text('Back'),
            ),
          ),
        ],
      );

  // ---------- Thanks ----------
  Widget _thanks(TextTheme t) => Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: const Icon(Icons.check_circle_rounded,
                size: 84, color: Brand.green),
          ),
          const SizedBox(height: 14),
          Text('Message sent',
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            "Thank you for telling us.\nWe'll use it to make things right.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.5),
          ),
        ],
      );
}

class _BigChoice extends StatelessWidget {
  const _BigChoice({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });
  final String emoji, title, subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: .35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}