import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'saved_posts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Tu devras te reconnecter pour accéder à l\'app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres et activité'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // ─── VOTRE COMPTE ─────────────────
          _buildSectionTitle('Votre compte'),
          _buildItem(
            context,
            icon: Icons.account_circle_outlined,
            title: 'Espace Comptes',
            subtitle:
                'Mot de passe, sécurité, informations personnelles, préférences',
            onTap: () {
              // À venir
            },
          ),
          const Divider(height: 1),

          // ─── UTILISATION PERSONNELLE ──────
          _buildSectionTitle('Utilisation personnelle'),
          _buildItem(
            context,
            icon: Icons.bookmark_border,
            title: 'Enregistré',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SavedPostsScreen(),
                ),
              );
            },
          ),
          _buildItem(
            context,
            icon: Icons.history,
            title: 'Archive',
            onTap: () {},
          ),
          _buildItem(
            context,
            icon: Icons.show_chart,
            title: 'Votre activité',
            onTap: () {},
          ),
          _buildItem(
            context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildItem(
            context,
            icon: Icons.access_time,
            title: 'Gestion du temps',
            onTap: () {},
          ),
          const Divider(height: 1),

          // ─── STATISTIQUES ────────────────
          _buildSectionTitle('Vos statistiques et outils'),
          _buildItem(
            context,
            icon: Icons.bar_chart,
            title: 'Tableau de bord',
            onTap: () {},
          ),
          _buildItem(
            context,
            icon: Icons.tune,
            title: 'Type de compte et outils',
            onTap: () {},
          ),
          const Divider(height: 1),

          // ─── CONNEXION ───────────────────
          _buildSectionTitle('Connexion'),
          _buildItem(
            context,
            icon: Icons.swap_horiz,
            title: 'Ajouter un compte',
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}