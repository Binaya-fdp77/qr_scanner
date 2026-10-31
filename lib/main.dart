import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin_page.dart';
import 'feedback_page.dart';
import 'firebase_options.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ReckoApp());
}

class ReckoApp extends StatelessWidget {
  const ReckoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recko Restaurant',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Customers:  your-site/        Owner:  your-site/#/admin
      onGenerateRoute: (settings) {
        final isAdmin = (settings.name ?? '/').startsWith('/admin');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => isAdmin ? const AdminPage() : const FeedbackPage(),
        );
      },
    );
  }
}