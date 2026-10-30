import 'package:flutter/material.dart';

import 'feedback_page.dart';

void main() {
  runApp(const ReckoApp());
}

class ReckoApp extends StatelessWidget {
  const ReckoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recko Restaurant – Feedback',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC2410C)),
      ),
      home: const FeedbackPage(),
    );
  }
}
