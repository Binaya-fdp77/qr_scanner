import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'theme.dart';

enum _Step { choice, private, thanks }

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  _Step step = _Step.choice;
  bool sending = false;
  bool leftContact = false;
  int rating = 0;
  final issues = <String>{};
  final comment = TextEditingController();
  final table = TextEditingController();
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
    table.dispose();
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
    if (rating == 0 && issues.isEmpty && comment.text.trim().isEmpty) {
      _snack('Please tell us a little about what happened.');
      return;
    }
    setState(() => sending = true);
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'issues': issues.toList(),
        'comment': comment.text.trim(),
        'contact': contact.text.trim(),
        if (rating > 0) 'rating': rating,
        if (table.text.trim().isNotEmpty) 'table': table.text.trim(),
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          leftContact = contact.text.trim().isNotEmpty;
          step = _Step.thanks;
        });
      }
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
      body: PageBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 64),
                    const SizedBox(height: 14),
                    Text('Recko Restaurant',
                        style: t.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 15, color: Brand.muted),
                        SizedBox(width: 4),
                        Text('Kattuwa, Negombo',
                            style:
                                TextStyle(color: Brand.muted, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey(step),
                          child: switch (step) {
                            _Step.choice => _choice(t),
                            _Step.private => _private(t),
                            _Step.thanks => _thanks(t),
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Takes less than a minute',
                        style: TextStyle(color: Brand.muted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Step 1: choose ----------
  Widget _choice(TextTheme t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How was your visit?',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Your feedback helps us serve you better.',
              style: TextStyle(color: Brand.muted, fontSize: 13.5)),
          const SizedBox(height: 18),
          _ChoiceTile(
            icon: Icons.star_rounded,
            color: Brand.star,
            title: 'I enjoyed my visit',
            subtitle: 'Share your experience on Google. It helps others '
                'find us and takes under a minute.',
            onTap: _openReview,
          ),
          const SizedBox(height: 10),
          _ChoiceTile(
            icon: Icons.mail_outline_rounded,
            color: Brand.ember,
            title: 'Something could be better',
            subtitle: 'Tell the owner directly. No name or contact needed.',
            tag: 'Anonymous',
            onTap: () => setState(() => step = _Step.private),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Brand.line),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 16, color: Brand.muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Every private message is read personally by the owner.',
                  style: TextStyle(
                      color: Brand.muted, fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      );

  // ---------- Step 2: private feedback ----------
  Widget _private(TextTheme t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => step = _Step.choice),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 8),
          Text('Tell us how we can improve',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.lock_outline_rounded,
                    size: 15, color: Brand.muted),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Anonymous by default. This goes straight to the owner and is never posted publicly.',
                  style: TextStyle(
                      color: Brand.muted, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _FieldLabel('Overall experience (optional)'),
          _StarPicker(
            value: rating,
            onChanged: (v) => setState(() => rating = v),
          ),
          const SizedBox(height: 22),
          const _FieldLabel('What was this about?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in options.entries)
                FilterChip(
                  showCheckmark: false,
                  avatar: Icon(e.value,
                      size: 16,
                      color: issues.contains(e.key)
                          ? Brand.ember
                          : Brand.muted),
                  label: Text(e.key, style: const TextStyle(fontSize: 13)),
                  selected: issues.contains(e.key),
                  selectedColor: Brand.ember.withValues(alpha: .10),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                      color:
                          issues.contains(e.key) ? Brand.ember : Brand.line),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onSelected: (v) => setState(
                      () => v ? issues.add(e.key) : issues.remove(e.key)),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const _FieldLabel('Details'),
          TextField(
            controller: comment,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Share as much or as little as you like',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: table,
            maxLength: 10,
            decoration: const InputDecoration(
              hintText: 'Table number (optional)',
              prefixIcon: Icon(Icons.table_restaurant_outlined, size: 20),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contact,
            keyboardType: TextInputType.emailAddress,
            maxLength: 60,
            decoration: const InputDecoration(
              hintText: 'Phone or email (optional)',
              helperText: 'Leave blank to stay anonymous. Add it only if you would like a reply.',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              counterText: '',
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: sending ? null : _send,
            child: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text('Send anonymously'),
          ),
          const SizedBox(height: 4),
          // Always leave the public route open - it is fairer to guests
          // and keeps the flow within Google's review policies.
          Center(
            child: TextButton(
              onPressed: _openReview,
              child: const Text('Prefer to share publicly? Review us on Google'),
            ),
          ),
        ],
      );

  // ---------- Step 3: thanks ----------
  Widget _thanks(TextTheme t) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Brand.green.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 30, color: Brand.green),
          ),
          const SizedBox(height: 16),
          Text('Thank you',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            leftContact
                ? 'Your message has reached the owner.\nWe will get back to you soon.'
                : 'Your message has reached the owner.\nWe will use it to improve.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Brand.muted, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 8),
        ],
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          InkResponse(
            radius: 24,
            // Tapping the current rating again clears it.
            onTap: () => onChanged(value == i ? 0 : i),
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 34,
                color: i <= value ? Brand.star : Brand.line,
              ),
            ),
          ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tag,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Brand.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        if (tag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Brand.tint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_outline_rounded,
                                    size: 11, color: Brand.muted),
                                const SizedBox(width: 3),
                                Text(tag!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Brand.muted)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: Brand.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Brand.muted),
            ],
          ),
        ),
      ),
    );
  }
}
