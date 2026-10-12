import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _filiereController = TextEditingController();
  final _niveauController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String? _success;
  bool _obscurePassword = true;
  bool _obscurePassword2 = true;

  Future<void> _register() async {
    // Vérifications
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _password2Controller.text.isEmpty) {
      setState(() => _error = 'Remplis tous les champs obligatoires');
      return;
    }

    if (_passwordController.text != _password2Controller.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() => _error = 'Mot de passe : 8 caractères minimum');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    final result = await AuthService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      password2: _password2Controller.text,
      filiere: _filiereController.text.trim(),
      niveau: _niveauController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _isLoading = false;
        _success = 'Compte créé ! Tu peux te connecter.';
      });
      // Attendre 1.5s puis revenir au login
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        _isLoading = false;
        _error = result['error'] ?? 'Erreur inconnue';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E40AF),
      appBar: AppBar(
        title: const Text('Inscription'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.person_add, size: 60, color: Color(0xFF1E40AF)),
                  const SizedBox(height: 12),
                  const Text(
                    'Créer un compte',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Username
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Pseudo *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filière
                  TextField(
                    controller: _filiereController,
                    decoration: const InputDecoration(
                      labelText: 'Filière',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Niveau
                  TextField(
                    controller: _niveauController,
                    decoration: const InputDecoration(
                      labelText: 'Niveau (L1, L2, M1...)',
                      prefixIcon: Icon(Icons.grade_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password 2
                  TextField(
                    controller: _password2Controller,
                    obscureText: _obscurePassword2,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword2
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() =>
                              _obscurePassword2 = !_obscurePassword2);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Messages
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  if (_success != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_success!,
                          style: const TextStyle(color: Colors.green)),
                    ),

                  const SizedBox(height: 8),

                  // Bouton inscription
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Créer mon compte',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}