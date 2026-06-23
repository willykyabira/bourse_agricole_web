import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

/// =======================================================
/// MODEL MENU ITEM
/// =======================================================
class MenuItem {
  final String title;
  final IconData icon;
  final String route;

  MenuItem(this.title, this.icon, this.route);
}

/// =======================================================
/// BAN LAYOUT (SHELL PRINCIPAL DE L’APP)
/// =======================================================
/// - Sidebar dynamique selon rôle utilisateur
/// - Topbar global
/// - Zone centrale (child)
class BanLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String activeRoute;

  const BanLayout({
    super.key,
    required this.child,
    required this.title,
    required this.activeRoute,
  });

  /// =======================================================
  /// PALETTE BAN (IDENTITÉ VISUELLE)
  /// =======================================================
  static const Color banGreen = Color(0xFF1B5E20);
  static const Color banBluePro = Color(0xFF4C6B8B);
  static const Color banSurface = Color(0xFFF4F7F6);

  /// =======================================================
  /// MENU PAR RÔLE
  /// =======================================================
  List<MenuItem> _getMenus(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [
          MenuItem("UTILISATEURS", Icons.people_alt_rounded, '/users_manage'),
          MenuItem("ENTREPÔTS", Icons.store_mall_directory_rounded, '/warehouses'),
          MenuItem("STATISTIQUES", Icons.dashboard_rounded, '/admin'),
          MenuItem("AUDIT LOGS", Icons.security_rounded, '/logs'),
        ];

      case 'finance':
        return [
          MenuItem("TABLEAU DE BORD", Icons.dashboard_rounded, '/finance'),
          MenuItem("TRANSACTIONS", Icons.list_alt_rounded, '/payments'),
          MenuItem("VALIDATION", Icons.task_alt_rounded, '/validation'),
          MenuItem("LITIGES", Icons.report_problem_rounded, '/disputes'),
          MenuItem("RAPPORTS", Icons.assessment_rounded, '/reports_finance'),
        ];

      case 'stock':
        return [
          MenuItem("ENTRÉES", Icons.login_rounded, '/mouvements'),
          MenuItem("SORTIES", Icons.logout_rounded, '/gestion_sorties'),
          MenuItem("INVENTAIRE", Icons.inventory_2_rounded, '/inventaire'),
          MenuItem("STATISTIQUES", Icons.analytics_rounded, '/stats_stock'),
          MenuItem("RAPPORTS", Icons.description_outlined, '/reports_stock'),
        ];

      default:
        return [
          MenuItem("ACCUEIL", Icons.home_rounded, '/'),
        ];
    }
  }

  /// =======================================================
  /// BUILD PRINCIPAL
  /// =======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          /// ================= SIDEBAR =================
          Container(
            width: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [banGreen, banBluePro],
              ),
            ),
            child: Column(
              children: [
                _buildLogo(),

                const Divider(color: Colors.white24, indent: 20, endIndent: 20),

                /// MENU DYNAMIQUE SELON ROLE
                Expanded(
                  child: FutureBuilder<String>(
                    future: _fetchUserRole(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final menuItems = _getMenus(snapshot.data!);

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          return _buildMenuTile(context, menuItems[index]);
                        },
                      );
                    },
                  ),
                ),

                _buildUserSection(context),
              ],
            ),
          ),

          /// ================= CONTENT =================
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),

                Expanded(
                  child: Container(
                    color: banSurface,
                    width: double.infinity,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// =======================================================
  /// FETCH ROLE (SUPABASE)
  /// =======================================================
  Future<String> _fetchUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) return 'client';

      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return (data['role'] ?? 'stock').toString();
    } catch (_) {
      return 'stock';
    }
  }

  /// =======================================================
  /// TILE MENU (UI PRO + ACTIVE STATE CLAIR)
  /// =======================================================
  Widget _buildMenuTile(BuildContext context, MenuItem item) {
    final bool isActive = activeRoute == item.route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),

        /// NAVIGATION SAFE
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, item.route);
          }
        },

        /// STYLE ACTIVE / INACTIVE
        tileColor: isActive
            ? Colors.white.withOpacity(0.15)
            : Colors.transparent,

        leading: Icon(
          item.icon,
          color: isActive ? Colors.white : Colors.white70,
          size: 20,
        ),

        title: Text(
          item.title,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  /// =======================================================
  /// LOGO SIDEBAR
  /// =======================================================
  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.only(top: 50, bottom: 30, left: 25, right: 25),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: Colors.white, size: 38),
          const SizedBox(width: 12),
          Text(
            "BAN ITURI",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  /// =======================================================
  /// TOP BAR (UI PLUS CLEAN)
  /// =======================================================
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_open_rounded, color: banBluePro),

          const SizedBox(width: 18),

          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: banBluePro,
              letterSpacing: 0.5,
            ),
          ),

          const Spacer(),

          /// MENU USER
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              }
            },
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: banGreen,
              child: Icon(Icons.person_outline, color: Colors.white, size: 20),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text("Profil"),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text("Déconnexion"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// =======================================================
  /// USER SECTION (BOTTOM SIDEBAR)
  /// =======================================================
  Widget _buildUserSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
      ),
      child: InkWell(
        onTap: () async {
          await Supabase.instance.client.auth.signOut();

          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        },
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
            SizedBox(width: 12),
            Text(
              "Déconnexion",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}