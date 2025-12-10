// lib/src/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- LIBRERÍA REAL
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  // Instancia oficial de Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Obtener el usuario actual (si existe)
  User? get currentUser => _auth.currentUser;

  // 1. Verificar sesión al iniciar la app
  Future<void> checkLoginStatus() async {
    // Firebase guarda la sesión automáticamente, pero esperamos un poco para el Splash
    await Future.delayed(const Duration(seconds: 1)); 
    notifyListeners();
  }

  // Helper para saber si está logueado
  bool get isAuthenticated => _auth.currentUser != null;

  // 2. INICIAR SESIÓN (LOGIN)
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim()
      );
      _isLoading = false;
      notifyListeners();
      return null; // Null significa "Sin errores"
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _mapFirebaseError(e); // Retornamos el error en español
    }
  }

  // 3. REGISTRARSE (SIGN UP)
  Future<String?> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim()
      );
      _isLoading = false;
      notifyListeners();
      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _mapFirebaseError(e);
    }
  }

  // 4. CERRAR SESIÓN
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpiamos datos locales también
    notifyListeners();
  }

  // Traducir errores de Firebase a Español
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe un usuario con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El formato del correo es inválido.';
      case 'weak-password':
        return 'La contraseña es muy débil (usa 6+ caracteres).';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}