// lib/src/ui/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Para volver al login
import 'package:provider/provider.dart'; // <--- IMPORTANTE
import '../../providers/auth_provider.dart'; // <--- IMPORTANTE
import 'orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Usuario Demo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text('usuario@fluttershop.com'),
            const SizedBox(height: 32),
              // NUEVO BOTÓN
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Mis Pedidos'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrdersScreen()),
                  );
                },
              ),
              const Divider(),
            // Botón de Cerrar Sesión
            OutlinedButton.icon(
              // En profile_screen.dart -> Botón Logout
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
            )
          ],
        ),
      ),
    );
  }
}