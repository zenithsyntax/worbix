import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/ui/splash_screen.dart';

class WorbixApp extends StatelessWidget {
  const WorbixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Worbix',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Comic Neue',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange, 
          primary: Colors.orange,
          secondary: Colors.lightBlueAccent,
          tertiary: Colors.greenAccent,
          surface: Colors.orange.shade50,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Comic Neue',
          bodyColor: Colors.brown.shade900,
          displayColor: Colors.deepOrange,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontFamily: 'Comic Neue', fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          centerTitle: true,
          titleTextStyle: TextStyle(fontFamily: 'Comic Neue', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
        )
      ),
      home: const SplashScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
    );
  }
}
