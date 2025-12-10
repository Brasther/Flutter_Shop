// lib/src/ui/screens/splash_screen.dart
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
  @override
  void initState() {
    super.initState();
    // Apenas carga la pantalla, le decimos al AuthProvider que verifique
    // Usamos addPostFrameCallback para asegurar que el contexto esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios del AuthProvider
    final auth = context.watch<AuthProvider>();

    // Si terminó de cargar, decidimos a dónde ir
    if (!auth.isLoading) {
      // Truco: Usamos un Future microtask para navegar apenas se pueda
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => 
                auth.isAuthenticated ? const MainScreen() : const LoginScreen(),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 100, color: Colors.white),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Cargando tu tienda...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            )
          ],
        ),
      ),
    );
  }
}