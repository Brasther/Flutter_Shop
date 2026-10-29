import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

/// Payment Sheet client. A trusted backend must create PaymentIntents and
/// provide the client secret; secret API keys must never be stored in the app.
class StripeService {
  static void init({required String publishableKey}) {
    Stripe.publishableKey = publishableKey;
  }

  /// Presents Stripe's Payment Sheet for a PaymentIntent created by a backend.
  /// Returns false only when the user cancels; other failures are surfaced.
  static Future<bool> presentPaymentSheet({
    required String paymentIntentClientSecret,
    String merchantDisplayName = 'Flutter Shop',
  }) async {
    if (paymentIntentClientSecret.trim().isEmpty) {
      throw ArgumentError.value(
        paymentIntentClientSecret,
        'paymentIntentClientSecret',
        'Debe provenir de un backend seguro.',
      );
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.system,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) return false;
      rethrow;
    }
  }

  static bool get isConfigured =>
      const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY').startsWith('pk_');

  static Future<String?> checkout({
    required List<Map<String, dynamic>> items,
    required String fullName,
    required String address,
    String couponCode = '',
  }) async {
    if (!isConfigured) {
      throw StateError('Falta STRIPE_PUBLISHABLE_KEY para activar los pagos.');
    }
    final response = await FirebaseFunctions.instance
        .httpsCallable('createPaymentIntent')
        .call({
      'items': items,
      'shipping': {'fullName': fullName, 'address': address},
      'couponCode': couponCode,
    });
    final payload = Map<String, dynamic>.from(response.data as Map);
    final clientSecret = payload['clientSecret'] as String?;
    final paymentIntentId = payload['paymentIntentId'] as String?;
    if (clientSecret == null || paymentIntentId == null) {
      throw StateError('El servidor devolvió una sesión de pago incompleta.');
    }

    final paid = await presentPaymentSheet(
      paymentIntentClientSecret: clientSecret,
    );
    if (!paid) return null;

    final confirmation = await FirebaseFunctions.instance
        .httpsCallable('confirmPayment')
        .call({'paymentIntentId': paymentIntentId});
    return (confirmation.data as Map)['orderId'] as String?;
  }
}
