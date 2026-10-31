import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'brand.dart';
import 'generate_qr_code.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data == null ? const _Login() : const _Dashboard();
      },
    );
  }
}

// ---------------- LOGIN ----------------
class _Login extends StatefulWidget {
  const _Login();
  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool busy = false;
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
      setState(() => error = 'Wrong email or password.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Brand.gradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: GlassCard(
              maxWidth: 400,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const BrandLogo(),
                const SizedBox(height: 14),
                const Text('Owner Dashboard',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Brand.dark)),
                const SizedBox(height: 22),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined),
                      labelText: 'Email',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pass,
                  obscureText: true,
                  onSubmitted: (_) => _login(),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline),
                      labelText: 'Password',
                      border: OutlineInputBorder()),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: Brand.red)),
                ],
                const SizedBox(height: 18),
                BigButton(
                    label: busy ? 'Signing in...' : 'Sign in',
                    color: Brand.primary,
                    onPressed: busy ? null : _login),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- DASHBOARD ----------------
class _Dashboard extends StatefulWidget {
  const _Dashboard();
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  String filter = 'all'; // all | new | resolved

  String _fmt(Timestamp? t) {
    if (t == null) return 'Just now';
    final d = t.toDate();
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '${m[d.month - 1]} ${d.day}, ${d.year}  •  $h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 16,
        title: const Row(children: [
          BrandLogo(size: 40),
          SizedBox(width: 12),
          Text('Recko Feedback',
              style: TextStyle(fontWeight: FontWeight.w700, color: Brand.dark)),
        ]),
        actions: [
          IconButton(
            tooltip: 'QR code',
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GenerateQRCode())),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
                child: Text('No permission. Is this the owner account?'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!.docs;
          final newCount = all.where((d) => d['status'] == 'new').length;
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          final week = all.where((d) {
            final t = d['createdAt'] as Timestamp?;
            return t == null || t.toDate().isAfter(weekAgo);
          }).length;

          final counts = <String, int>{};
          for (final d in all) {
            for (final i in List<String>.from(d['issues'] ?? [])) {
              counts[i] = (counts[i] ?? 0) + 1;
            }
          }
          final top = counts.entries.isEmpty
              ? '-'
              : (counts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .first
                  .key;

          final shown = all
              .where((d) => filter == 'all' || d['status'] == filter)
              .toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    _stat('Total', '${all.length}', Icons.forum, Brand.primary),
                    _stat('New', '$newCount', Icons.mark_email_unread, Brand.red),
                    _stat('This week', '$week', Icons.date_range, Colors.blue),
                    _stat('Top issue', top, Icons.trending_up, Colors.purple),
                  ]),
                  const SizedBox(height: 20),
                  Wrap(spacing: 8, children: [
                    for (final f in const ['all', 'new', 'resolved'])
                      ChoiceChip(
                        label: Text(f[0].toUpperCase() + f.substring(1)),
                        selected: filter == f,
                        onSelected: (_) => setState(() => filter = f),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(50),
                      child: Center(
                          child: Text('No feedback here yet 🎉',
                              style: TextStyle(color: Colors.black54))),
                    ),
                  for (final d in shown) _card(d),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color c) {
    return Container(
      width: 205,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14)
        ],
      ),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: c.withOpacity(.12),
            child: Icon(icon, color: c)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _card(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final isNew = data['status'] == 'new';
    final issues = List<String>.from(data['issues'] ?? []);
    final comment = (data['comment'] ?? '') as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
            left: BorderSide(
                color: isNew ? Brand.red : Brand.green, width: 5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person_off_outlined, size: 18, color: Colors.black45),
          const SizedBox(width: 6),
          const Text('Anonymous',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(_fmt(data['createdAt'] as Timestamp?),
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final i in issues)
            Chip(
              label: Text(i, style: const TextStyle(fontSize: 12)),
              backgroundColor: const Color(0xFFFFEDD5),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
        ]),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(comment, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(
            icon: Icon(isNew ? Icons.check : Icons.undo, size: 18),
            label: Text(isNew ? 'Mark resolved' : 'Reopen'),
            onPressed: () =>
                d.reference.update({'status': isNew ? 'resolved' : 'new'}),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            style: TextButton.styleFrom(foregroundColor: Brand.red),
            label: const Text('Delete'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete this feedback?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) d.reference.delete();
            },
          ),
        ]),
      ]),
    );
  }
}