// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Importamos el servicio de Stripe
import 'package:flutter_shop/src/services/stripe_service.dart'; // <--- NUEVO IMPORT

import 'package:flutter_shop/src/ui/theme/app_theme.dart';
import 'package:flutter_shop/src/providers/cart_provider.dart';
import 'package:flutter_shop/src/providers/auth_provider.dart';
import 'package:flutter_shop/src/providers/orders_provider.dart';
import 'package:flutter_shop/src/ui/screens/splash_screen.dart';

// --- HANDLER DE FONDO (Background Handler) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Notificación en Segundo Plano recibida: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INICIALIZAR STRIPE (ANTES DE ARRANCAR)
  StripeService.init(); // <--- AQUÍ CONFIGURAMOS LA CLAVE PÚBLICA

  // 2. Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Configurar el sistema de mensajería (FCM)
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // A. Pedir permiso
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('Permiso de notificaciones: ${settings.authorizationStatus}');

  // B. Registrar el handler de fondo
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // C. Escuchar mensajes en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Mensaje recibido en primer plano!');
    print('Título: ${message.notification?.title}');
    print('Cuerpo: ${message.notification?.body}');
  });

  // D. Obtener el Token del dispositivo
  try {
    final fcmToken = await messaging.getToken();
    
    if (fcmToken != null) {
      print('==================================================');
      print('TOKEN FCM DEL DISPOSITIVO:');
      print(fcmToken);
      print('==================================================');
    } else {
      print('El token vino nulo. Intenta reiniciar la app o revisar Google Play Services.');
    }
  } catch (e) {
    print('ERROR CRÍTICO AL OBTENER TOKEN:');
    print(e);
  }

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