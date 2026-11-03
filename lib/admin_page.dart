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
            body: PageBackground(
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

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

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
      body: PageBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 64),
                  const SizedBox(height: 14),
                  Text('Owner Portal',
                      style:
                          t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Sign in to view guest feedback',
                      style: TextStyle(color: Brand.muted, fontSize: 13)),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: pass,
                          obscureText: hide,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  hide
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20),
                              onPressed: () => setState(() => hide = !hide),
                            ),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(error!,
                                style: const TextStyle(
                                    color: Brand.red, fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: busy ? null : _login,
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.2, color: Colors.white))
                              : const Text('Sign in'),
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
      body: PageBackground(
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
                  final ratings = docs
                      .map((d) => (d.data()['rating'] as num?)?.toDouble())
                      .whereType<double>()
                      .where((r) => r > 0)
                      .toList();
                  final avg = ratings.isEmpty
                      ? '–'
                      : (ratings.reduce((a, b) => a + b) / ratings.length)
                          .toStringAsFixed(1);
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
                          const BrandLogo(size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Feedback Inbox',
                                    style: t.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700)),
                                const Text('Recko Restaurant · Private feedback',
                                    style: TextStyle(
                                        color: Brand.muted, fontSize: 12)),
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
                        Widget s(String l, String v) =>
                            SizedBox(width: w, child: _StatCard(l, v));
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            s('Total', '${docs.length}'),
                            s('New', '$fresh'),
                            s('Avg. rating', avg),
                            s('Top issue', top),
                          ],
                        );
                      }),
                      const SizedBox(height: 22),

                      // filter
                      SegmentedButton<String>(
                        showSelectedIcon: false,
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
                      const SizedBox(height: 16),

                      if (shown.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 44, color: Brand.line),
                              SizedBox(height: 10),
                              Text('Nothing here yet',
                                  style: TextStyle(color: Brand.muted)),
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
  const _StatCard(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brand.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Brand.muted)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
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
    return '${m[d.month - 1]} ${d.day}, ${d.year} · $h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this feedback?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Brand.red))),
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
    final tableNo = (d['table'] ?? '') as String;
    final rating = (d['rating'] as num?)?.toInt() ?? 0;
    final time = (d['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isNew ? Brand.ember.withValues(alpha: .45) : Brand.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guest #${doc.id.substring(0, 4).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(time == null ? 'Just now' : _fmt(time),
                        style: const TextStyle(
                            fontSize: 12, color: Brand.muted)),
                  ],
                ),
              ),
              _Pill(isNew ? 'New' : 'Resolved',
                  isNew ? Brand.ember : Brand.green),
            ],
          ),
          if (rating > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 20,
                    color: i <= rating ? Brand.star : Brand.line,
                  ),
              ],
            ),
          ],
          if (issues.isNotEmpty || tableNo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in issues) _Tag(i),
                if (tableNo.isNotEmpty)
                  _Tag('Table $tableNo', icon: Icons.table_restaurant_outlined),
              ],
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment, style: const TextStyle(height: 1.5, fontSize: 14)),
          ],
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => launchUrl(Uri(
                  scheme: contact.contains('@') ? 'mailto' : 'tel',
                  path: contact)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      contact.contains('@')
                          ? Icons.mail_outline
                          : Icons.phone_outlined,
                      size: 16,
                      color: Brand.green),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Reply to: $contact',
                        style: const TextStyle(
                            color: Brand.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Brand.line),
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
                label: const Text('Delete', style: TextStyle(color: Brand.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Brand.tint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Brand.muted),
            const SizedBox(width: 4),
          ],
          Text(text, style: const TextStyle(fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}
