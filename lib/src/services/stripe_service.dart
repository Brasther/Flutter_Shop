// lib/src/services/stripe_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  // TUS CLAVES REALES (¡Cuidado con espacios extra!)
  static const String _publishableKey = '';
  static const String _secretKey = '';

  // Inicializamos Stripe
  static void init() {
    // CORRECCIÓN: Así se asigna la clave pública en las versiones nuevas
    Stripe.publishableKey = _publishableKey;
  }

  // --- FLUJO PRINCIPAL DE PAGO ---
  static Future<bool> makePayment(String amount, String currency) async {
    try {
      // 1. Pedirle a Stripe que prepare el cobro (Payment Intent)
      final paymentIntent = await _createPaymentIntent(amount, currency);
      if (paymentIntent == null) return false;

      // 2. Configurar la hoja de pago visual
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Mi Tienda Flutter',
          style: ThemeMode.system,
        ),
      );

      // 3. Mostrar la hoja de pago al usuario
      await Stripe.instance.presentPaymentSheet();
      
      // Si llegamos aquí sin errores, el pago fue exitoso
      return true; 

    } catch (e) {
      print('Error procesando el pago: $e');
      if (e is StripeException) {
        print('Error de Stripe: ${e.error.localizedMessage}');
      }
      return false;
    }
  }

  // --- SIMULACIÓN DE BACKEND ---
  static Future<Map<String, dynamic>?> _createPaymentIntent(String amount, String currency) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount,
          'currency': currency,
          // 'payment_method_types[]': 'card', // Ya no es necesario enviarlo así en versiones nuevas
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error de API Stripe: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de conexión con Stripe: $e');
      return null;
    }
  }
}