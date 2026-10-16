import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Contrôleurs
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();

  // États
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePassword2 = true;
  bool _acceptTerms = false;

  // Erreurs par champ
  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _emailError;
  String? _dateError;
  String? _passwordError;
  String? _password2Error;
  String? _globalError;

  // Date sélectionnée
  DateTime? _selectedDate;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _dateController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  /// Ouvre le sélecteur de date
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 18),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10), // au moins 10 ans
      locale: const Locale('fr', 'FR'),
      helpText: 'Ta date de naissance',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        _dateError = null;
      });
    }
  }

  /// Vérifie tous les champs avant envoi
  bool _validate() {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _usernameError = null;
      _emailError = null;
      _dateError = null;
      _passwordError = null;
      _password2Error = null;
      _globalError = null;
    });

    bool isValid = true;

    if (_firstNameController.text.trim().isEmpty) {
      _firstNameError = 'Le prénom est obligatoire';
      isValid = false;
    }

    if (_lastNameController.text.trim().isEmpty) {
      _lastNameError = 'Le nom est obligatoire';
      isValid = false;
    }

    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _usernameError = 'Le pseudo est obligatoire';
      isValid = false;
    } else if (username.length < 3) {
      _usernameError = 'Le pseudo doit faire au moins 3 caractères';
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(username)) {
      _usernameError = 'Lettres, chiffres, _ et . uniquement';
      isValid = false;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailError = 'L\'email est obligatoire';
      isValid = false;
    } else if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
      _emailError = 'Email invalide';
      isValid = false;
    }

    if (_selectedDate == null) {
      _dateError = 'La date de naissance est obligatoire';
      isValid = false;
    } else {
      final age = DateTime.now().year - _selectedDate!.year;
      if (age < 10) {
        _dateError = 'Tu dois avoir au moins 10 ans';
        isValid = false;
      }
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      _passwordError = 'Le mot de passe est obligatoire';
      isValid = false;
    } else if (password.length < 8) {
      _passwordError = 'Au moins 8 caractères';
      isValid = false;
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      _passwordError = 'Au moins une majuscule';
      isValid = false;
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      _passwordError = 'Au moins un chiffre';
      isValid = false;
    }

    if (_password2Controller.text != password) {
      _password2Error = 'Les mots de passe ne correspondent pas';
      isValid = false;
    }

    if (!_acceptTerms) {
      _globalError = 'Tu dois accepter les conditions';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  /// Envoie le formulaire au backend
  Future<void> _register() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _globalError = null;
    });

    final dateStr = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : '';

    final result = await AuthService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      password2: _password2Controller.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: dateStr,
    );

    if (!mounted) return;

        if (result['success'] == true) {
      // 1️⃣ Connexion auto pour obtenir le token
      final loginResult = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (loginResult['success'] == true) {
        // 2️⃣ Envoie automatiquement le code de vérification
        await AuthService.sendVerificationCode();

        if (!mounted) return;

        // 3️⃣ Direction écran de vérification
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(
              email: _emailController.text.trim(),
            ),
          ),
          (route) => false,
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé, mais erreur de connexion.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
        } else {
      setState(() {
        _isLoading = false;
        // Message plus clair selon l'erreur
        final errorMsg = result['error'] ?? 'Erreur inconnue';
        if (errorMsg.contains('email')) {
          _globalError = 'Cet email est déjà utilisé. Essaie un autre.';
        } else if (errorMsg.contains('username')) {
          _globalError = 'Ce pseudo est déjà pris. Essaie un autre.';
        } else {
          _globalError = errorMsg;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── EN-TÊTE ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Inscription',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ─── LOGO + SLOGAN ─────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
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
                      padding: const EdgeInsets.all(8),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Rejoins Baobab',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Le Sénégal participe',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── FORMULAIRE ────────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDFDF5), // crème
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── PRÉNOM ─────────────
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'Prénom',
                          icon: Icons.person_outline,
                          error: _firstNameError,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),

                        // ─── NOM ────────────────
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Nom',
                          icon: Icons.person,
                          error: _lastNameError,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),

                        // ─── PSEUDO ─────────────
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Nom d\'utilisateur (unique)',
                          icon: Icons.alternate_email,
                          error: _usernameError,
                        ),
                        const SizedBox(height: 12),

                        // ─── EMAIL ──────────────
                        _buildTextField(
                          controller: _emailController,
                          label: 'Adresse email',
                          icon: Icons.email_outlined,
                          error: _emailError,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),

                        // ─── DATE DE NAISSANCE ──
                        TextField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: InputDecoration(
                            labelText: 'Date de naissance',
                            prefixIcon: const Icon(Icons.cake_outlined,
                                color: AppTheme.green),
                            suffixIcon: const Icon(Icons.calendar_today,
                                size: 18, color: AppTheme.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorText: _dateError,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                    

                        // ─── MOT DE PASSE ───────
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppTheme.green),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorText: _passwordError,
                            filled: true,
                            fillColor: Colors.white,
                            helperText:
                                '8 caractères min. avec 1 majuscule et 1 chiffre',
                            helperStyle: const TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ─── CONFIRMATION ───────
                        TextField(
                          controller: _password2Controller,
                          obscureText: _obscurePassword2,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppTheme.green),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword2
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() => _obscurePassword2 =
                                    !_obscurePassword2);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorText: _password2Error,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ─── CONDITIONS ─────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              activeColor: AppTheme.green,
                              onChanged: (v) => setState(
                                  () => _acceptTerms = v ?? false),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text:
                                              'J\'accepte les '),
                                      TextSpan(
                                        text: 'conditions d\'utilisation',
                                        style: const TextStyle(
                                          color: AppTheme.green,
                                          fontWeight: FontWeight.bold,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                      ),
                                      const TextSpan(
                                          text:
                                              ' et la politique de confidentialité.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ─── ERREUR GLOBALE ─────
                        if (_globalError != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Text(
                              _globalError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // ─── BOUTON CRÉER ───────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                                : const Text(
                                    'Créer mon compte',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ─── LIEN CONNEXION ─────
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                children: [
                                  TextSpan(
                                      text: 'Tu as déjà un compte ? '),
                                  TextSpan(
                                    text: 'Se connecter',
                                    style: TextStyle(
                                      color: AppTheme.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? error,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        errorText: error,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}