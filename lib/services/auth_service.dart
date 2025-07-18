import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Estado de autenticación como stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Registrar usuario con email y contraseña
  Future<User?> registerWithEmailAndPassword(
      String email, String password, Map<String, dynamic> userData) async {
    try {
      // Crear usuario en Authentication
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final User? user = result.user;

      if (user != null) {
        // Guardar datos adicionales en Realtime Database
        await _saveUserData(user.uid, userData);
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Guardar datos del usuario en Realtime Database
  Future<void> _saveUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _database.child('users').child(uid).set({
        ...userData,
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error al guardar datos del usuario: $e');
      throw Exception('Error al guardar datos del usuario');
    }
  }

  // Actualizar datos del usuario
  Future<void> updateUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _database.child('users').child(uid).update(userData);
    } catch (e) {
      print('Error al actualizar datos del usuario: $e');
      throw Exception('Error al actualizar datos del usuario');
    }
  }

  // Obtener datos del usuario
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final snapshot = await _database.child('users').child(uid).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      throw Exception('Error al obtener datos del usuario');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Manejar excepciones de autenticación
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe un usuario con este correo electrónico';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este correo electrónico ya está registrado';
      case 'weak-password':
        return 'La contraseña es demasiado débil';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido';
      case 'invalid-credential':
        return 'Credenciales inválidas, revisa tu correo y contraseña';
      case 'operation-not-allowed':
        return 'La operación no está permitida';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Inténtalo más tarde';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
