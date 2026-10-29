import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'login_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.person,
                  size: 42, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(user?.displayName ?? (user == null ? 'Modo invitado' : 'Hola'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            Text(user?.email ?? 'Inicia sesión para consultar tus pedidos',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (user == null)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Iniciar sesión o crear cuenta'),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Mis pedidos'),
              subtitle: const Text('Consulta el estado y los detalles'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen())),
            ),
            FutureBuilder<bool>(
              future: _isAdmin(),
              builder: (context, snapshot) => snapshot.data == true
                  ? Column(children: [
                      ListTile(
                        leading: const Icon(Icons.dashboard_outlined),
                        title: const Text('Panel de administración'),
                        subtitle: const Text('Ventas, pedidos e inventario'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminDashboardScreen()),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: const Text('Administrar pedidos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminOrdersScreen()),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Administrar catálogo'),
                        subtitle:
                            const Text('Crear, editar y eliminar productos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminProductsScreen()),
                        ),
                      ),
                    ])
                  : const SizedBox.shrink(),
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                final cart = context.read<CartProvider>();
                final auth = context.read<AuthProvider>();
                await cart.clear();
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ]),
    );
  }
}
