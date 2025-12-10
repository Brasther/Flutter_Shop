// lib/src/ui/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Las pantallas que vamos a mostrar
  final List<Widget> _screens = [
    const HomeScreen(),
    const CartScreen(), // Reutilizamos la que ya creamos
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Obtenemos la cantidad de items para el globito rojo (Badge)
    final cartItemCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      // IndexedStack mantiene el estado de las pantallas (no se recargan al cambiar)
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Tienda',
          ),
          
          // Icono del Carrito con Badge (Globito rojo)
          NavigationDestination(
            icon: cartItemCount > 0 
              ? Badge(label: Text('$cartItemCount'), child: const Icon(Icons.shopping_cart_outlined))
              : const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}