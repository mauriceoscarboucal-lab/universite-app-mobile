import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'complete_profile_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Entre les 6 chiffres du code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _info = null;
    });

    final result = await AuthService.verifyEmail(code);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email vérifié ! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _error = result['error'] ?? 'Code incorrect';
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isSending = true;
      _error = null;
      _info = null;
    });

    final result = await AuthService.sendVerificationCode();

    if (!mounted) return;

    setState(() {
      _isSending = false;
      if (result['success'] == true) {
        _info = 'Nouveau code envoyé à ${widget.email}';
      } else {
        _error = result['error'] ?? 'Erreur envoi';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.gradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Icône email
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 50,
                    color: AppTheme.green,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Vérifie ton email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'On t\'a envoyé un code à 6 chiffres à\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Carte avec le champ
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFDF5),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '000000',
                          hintStyle: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 32,
                            letterSpacing: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.green,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      if (_info != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _info!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Vérifier',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: _isSending ? null : _resendCode,
                        child: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Renvoyer le code',
                                style: TextStyle(
                                  color: AppTheme.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}