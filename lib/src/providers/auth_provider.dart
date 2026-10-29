import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> checkLoginStatus() async {
    try {
      await _auth.authStateChanges().first;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) => _runAuth(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  Future<String?> register(String email, String password) => _runAuth(
        () => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  Future<String?> _runAuth(Future<UserCredential> Function() action) async {
    _isLoading = true;
    notifyListeners();
    try {
      await action();
      return null;
    } catch (error) {
      return _mapError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } catch (error) {
      return _mapError(error);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_items');
    notifyListeners();
  }

  String _mapError(Object error) {
    if (error is! FirebaseAuthException) {
      return 'No pudimos completar la solicitud. Revisa tu conexión.';
    }
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'El correo o la contraseña no son correctos.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'No hay conexión. Revisa tu internet e inténtalo de nuevo.';
      case 'operation-not-allowed':
        return 'Activa Email/contraseña en Firebase Authentication.';
      default:
        return 'Error de autenticación. Revisa los ajustes de Firebase.';
    }
  }
}
