import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoading && !_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                auth.isAuthenticated ? const MainScreen() : const LoginScreen(),
          ),
        );
      });
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: const Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag, size: 96, color: Colors.white),
          SizedBox(height: 20),
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text('Cargando tu tienda…',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      )),
    );
  }
}
