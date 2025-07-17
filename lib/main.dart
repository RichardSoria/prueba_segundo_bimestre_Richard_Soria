import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mi_supabase_flutter/tabs/publicador_tabs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Inicializa Supabase
    await Supabase.initialize(
      url: 'https://jqoabinjonqgedgbrryi.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impxb2FiaW5qb25xZ2VkZ2JycnlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0NTkzNDAsImV4cCI6MjA2NDAzNTM0MH0.Ixtfn8U6F8gC-g5zS9w2V2tqvRZwrnojoJSLcG5P2LU',
    );
  } catch (e) {
    print(e);
  }

  try {
    // Inicializa Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBWJiYEAKabqS5IbNh2FQSdXAiqg48TO5k",
        authDomain: "flutter-firebase-2e515.firebaseapp.com",
        projectId: "flutter-firebase-2e515",
        storageBucket: "flutter-firebase-2e515.appspot.com",
        messagingSenderId: "31816417250",
        appId: "1:31816417250:web:a37f2d45b25ae07ebfc3bb",
        measurementId: "G-JYG08PBL2Q",
      ),
    );
  } catch (e) {
    print(e);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'El Búho Turismo',
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();

    // Escucha cambios de sesión (por ejemplo, después de registrarse o iniciar sesión manualmente)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _navegarAlHome();
      }
    });
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 500)); // para UX

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      _navegarAlHome();
    } else {
      if (mounted) {
        setState(() {
          _checkingSession = false;
        });
        FlutterNativeSplash.remove();
      }
    }
  }

  void _navegarAlHome() {
    if (!mounted) return;

    FlutterNativeSplash.remove();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const PublicadorTabs(),
      ), // o VisitanteTabs()
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8AD25)),
          ),
        ),
      );
    }

    return const LoginPage();
  }
}
