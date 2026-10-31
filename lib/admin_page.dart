import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'generate_qr_code.dart';
import 'theme.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: BrandBackground(
                child: Center(child: CircularProgressIndicator())),
          );
        }
        return snap.data == null ? const _LoginView() : const _Dashboard();
      },
    );
  }
}

// ======================= LOGIN =======================
class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool busy = false, hide = true;
  String? error;

  Future<void> _login() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: pass.text);
    } on FirebaseAuthException {
      if (mounted) setState(() => error = 'Incorrect email or password.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: BrandBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 88),
                  const SizedBox(height: 16),
                  Text('Owner Portal',
                      style: t.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700, color: Brand.deep)),
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: pass,
                          obscureText: hide,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(hide
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => hide = !hide),
                            ),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(error!,
                              style: const TextStyle(color: Brand.red)),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: busy ? null : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: Brand.ember,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white))
                                : const Text('Sign in',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================= DASHBOARD =======================
class _Dashboard extends StatefulWidget {
  const _Dashboard();

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  String filter = 'all';
  final stream = FirebaseFirestore.instance
      .collection('feedback')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No access. Please sign in with the owner account.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;

                  // ---- stats ----
                  final fresh =
                      docs.where((d) => d.data()['status'] == 'new').length;
                  final weekAgo =
                      DateTime.now().subtract(const Duration(days: 7));
                  final week = docs.where((d) {
                    final ts = (d.data()['createdAt'] as Timestamp?)?.toDate();
                    return ts != null && ts.isAfter(weekAgo);
                  }).length;
                  final counts = <String, int>{};
                  for (final d in docs) {
                    for (final i
                        in List<String>.from(d.data()['issues'] ?? const [])) {
                      counts[i] = (counts[i] ?? 0) + 1;
                    }
                  }
                  final top = counts.isEmpty
                      ? '–'
                      : (counts.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .first
                          .key;

                  final shown = docs.where((d) {
                    final s = d.data()['status'];
                    return filter == 'all' ||
                        (filter == 'new' && s == 'new') ||
                        (filter == 'resolved' && s != 'new');
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // header
                      Row(
                        children: [
                          const BrandLogo(size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Feedback Inbox',
                                    style: t.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Brand.deep)),
                                const Text('Recko Restaurant • Anonymous',
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'QR code',
                            icon: const Icon(Icons.qr_code_2_rounded),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const GenerateQRCode()),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sign out',
                            icon: const Icon(Icons.logout_rounded),
                            onPressed: () => FirebaseAuth.instance.signOut(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // stats
                      LayoutBuilder(builder: (context, box) {
                        final w = box.maxWidth >= 600
                            ? (box.maxWidth - 36) / 4
                            : (box.maxWidth - 12) / 2;
                        Widget s(String l, String v, IconData i, Color c) =>
                            SizedBox(
                                width: w, child: _StatCard(l, v, i, c));
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            s('Total', '${docs.length}', Icons.inbox_outlined,
                                Brand.deep),
                            s('New', '$fresh', Icons.mark_email_unread_outlined,
                                Brand.ember),
                            s('Last 7 days', '$week', Icons.date_range_outlined,
                                const Color(0xFF2563EB)),
                            s('Top issue', top, Icons.trending_up_rounded,
                                Brand.red),
                          ],
                        );
                      }),
                      const SizedBox(height: 22),

                      // filter
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(value: 'new', label: Text('New')),
                          ButtonSegment(
                              value: 'resolved', label: Text('Resolved')),
                        ],
                        selected: {filter},
                        onSelectionChanged: (s) =>
                            setState(() => filter = s.first),
                      ),
                      const SizedBox(height: 18),

                      if (shown.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 56, color: Colors.black26),
                              SizedBox(height: 10),
                              Text('Nothing here yet',
                                  style: TextStyle(color: Colors.black45)),
                            ],
                          ),
                        )
                      else
                        for (final d in shown) _FeedbackCard(d),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard(this.doc);
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  static String _fmt(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '${m[d.month - 1]} ${d.day}, ${d.year} • $h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this feedback?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Brand.red))),
        ],
      ),
    );
    if (ok == true) await doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final isNew = d['status'] == 'new';
    final issues = List<String>.from(d['issues'] ?? const []);
    final comment = (d['comment'] ?? '') as String;
    final contact = (d['contact'] ?? '') as String;
    final time = (d['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isNew ? Brand.ember.withValues(alpha: .4) : Colors.black12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Brand.cream,
                child: Icon(Icons.person_outline, color: Brand.ember),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Anonymous guest #${doc.id.substring(0, 4).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(time == null ? 'Just now' : _fmt(time),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              _Pill(isNew ? 'NEW' : 'RESOLVED',
                  isNew ? Brand.ember : Brand.green),
            ],
          ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in issues)
                  Chip(
                    label: Text(i, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Brand.cream,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment, style: const TextStyle(height: 1.5)),
          ],
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => launchUrl(Uri.parse('tel:$contact')),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 16, color: Brand.green),
                  const SizedBox(width: 6),
                  Text('Call back: $contact',
                      style: const TextStyle(
                          color: Brand.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => doc.reference
                    .update({'status': isNew ? 'resolved' : 'new'}),
                icon: Icon(
                    isNew ? Icons.check_circle_outline : Icons.undo_rounded,
                    size: 18),
                label: Text(isNew ? 'Mark resolved' : 'Reopen'),
              ),
              TextButton.icon(
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Brand.red),
                label:
                    const Text('Delete', style: TextStyle(color: Brand.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}