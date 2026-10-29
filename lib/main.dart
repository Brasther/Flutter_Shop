// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'package:flutter_shop/src/ui/theme/app_theme.dart';
import 'package:flutter_shop/src/providers/cart_provider.dart';
import 'package:flutter_shop/src/providers/auth_provider.dart';
import 'package:flutter_shop/src/providers/orders_provider.dart';
import 'package:flutter_shop/src/providers/favorites_provider.dart';
import 'package:flutter_shop/src/services/stripe_service.dart';
import 'package:flutter_shop/src/ui/screens/splash_screen.dart';

// --- HANDLER DE FONDO (Background Handler) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Notificación en segundo plano: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (StripeService.isConfigured) {
    StripeService.init(
      publishableKey: const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY'),
    );
  }

  // Inicializar Firebase antes de registrar servicios que dependen de él.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Registrar el handler; el permiso se solicita desde un contexto de UI
  // cuando la app realmente necesite activar notificaciones.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const FlutterShopApp());
}

class FlutterShopApp extends StatelessWidget {
  const FlutterShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'FlutterShop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
