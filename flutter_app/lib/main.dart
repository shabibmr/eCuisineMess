import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/counter_provider.dart';
import 'screens/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterProvider()),
      ],
      child: const ECuisineMessApp(),
    ),
  );
}

class ECuisineMessApp extends StatelessWidget {
  const ECuisineMessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eCuisine Mess Module',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}
