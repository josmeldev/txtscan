import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Método para enviar correo de recuperación
  Future<void> _resetPassword() async {
    // Validar email
    if (_emailController.text.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Por favor, ingresa tu correo electrónico';
        });
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _successMessage = '';
      });
    }
    
    try {
      // Enviar correo de recuperación
      await _authService.resetPassword(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _successMessage = 'Se ha enviado un correo para restablecer tu contraseña';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A2A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  // Logo (asegúrate de que exista la imagen)
                  Image.asset(
                    'assets/images/txtscan-logo.png',
                    width: 250,
                    height: 180,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            
            const Text(
              'Recuperar Contraseña',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Restablecer Contraseña',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Campo de correo electrónico
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      hintText: 'Correo electrónico',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Mensaje de error
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Mensaje de éxito
                  if (_successMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _successMessage,
                        style: const TextStyle(color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Botón de enviar correo de recuperación
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _isLoading
                      ? const SpinKitCircle(color: Color(0xFF005AA3), size: 40.0)
                      : ElevatedButton(
                          onPressed: _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005AA3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Enviar correo de recuperación',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Enlace para volver a inicio de sesión
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Recuerdas tu contraseña?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
