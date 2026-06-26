import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class StatistiquesAdmin extends StatefulWidget {
  const StatistiquesAdmin({super.key});

  @override
  State<StatistiquesAdmin> createState() => _StatistiquesAdminState();
}

class _StatistiquesAdminState extends State<StatistiquesAdmin> {
  // Instance du client Supabase pour interagir avec la base de données distante
  final SupabaseClient supabase = Supabase.instance.client;
  
  // Constantes de configuration pour éviter les fautes de frappe (hardcoding) dans les requêtes
  static const String _tableProduits = 'produits';
  static const String _colonneNomProduit = 'nom_produit';

  // Variables d'état pour gérer le chargement (spinners) et l'authentification
  bool _isLoadingGlobalStats = true;
  bool _isCheckingAuth = true;
  bool _isLoadingFilteredProducts = false;
  String? _errorMessage;

  // Compteurs globaux alimentés par les requêtes de comptage (KPI)
  int _countProductsRegistered = 0;
  int _countWarehouses = 0;
  int _countStaffUsers = 0;
  int _countClientUsers = 0;
  int _countTotalOrders = 0;

  // Listes et conteneurs pour le système de filtrage par entrepôt
  List<Map<String, dynamic>> _warehousesList = []; 
  String? _selectedWarehouseId; 
  String _selectedWarehouseName = "";
  List<Map<String, dynamic>> _productsInSelectedWarehouse = []; 

  // Palette de couleurs de l'application (Charte graphique BAN)
  static const Color _primaryColor = Color(0xFF1B5E20); 
  static const Color _surfaceColor = Colors.white;
  static const Color _backgroundColor = Color(0xFFF8FAFC); 
  static const Color _textColorPrimary = Color(0xFF0F172A); 
  static const Color _textColorSecondary = Color(0xFF475569); 

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  // Vérifie si l'utilisateur possède un jeton de session actif, sinon redirection immédiate
  Future<void> _checkAuthAndLoadData() async {
    if (supabase.auth.currentSession == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    setState(() => _isCheckingAuth = false);
    _loadGlobalStatistics();
  }

  // Effectue l'ensemble des requêtes asynchrones en parallèle ou à la suite pour alimenter le tableau de bord
  Future<void> _loadGlobalStatistics() async {
    if (!mounted) return;
    setState(() {
      _isLoadingGlobalStats = true;
      _errorMessage = null;
    });
    
    try {
      // 1. Extraction et dédoublonnage automatique via un 'Set' (ne garde que les valeurs uniques)
      final productsRes = await supabase.from(_tableProduits).select(_colonneNomProduit);
      final distinctProducts = List<Map<String, dynamic>>.from(productsRes)
          .where((e) => e[_colonneNomProduit] != null)
          .map((e) => e[_colonneNomProduit].toString().toLowerCase().trim())
          .toSet(); 
      _countProductsRegistered = distinctProducts.length;

      // 2. Récupération des entrepôts triés par ordre alphabétique
      final warehouseRes = await supabase.from('entrepots').select('id, nom_entrepot').order('nom_entrepot');
      _warehousesList = List<Map<String, dynamic>>.from(warehouseRes);
      _countWarehouses = _warehousesList.length;

      // 3. Récupération et filtrage en mémoire (Where) des types de rôles utilisateurs
      final usersRes = await supabase.from('profiles').select('role');
      final users = List<Map<String, dynamic>>.from(usersRes);
      final staffRoles = ['admin', 'stock', 'finance'];
      
      _countStaffUsers = users.where((u) => u['role'] != null && staffRoles.contains(u['role'].toString().toLowerCase())).length;
      _countClientUsers = users.length - _countStaffUsers;

      // 4. Volume global des lignes de commandes enregistrées
      final ordersRes = await supabase.from('commandes').select('id');
      _countTotalOrders = ordersRes.length;

      // Sélection automatique du premier entrepôt de la liste si aucun choix n'a encore été fait
      if (_warehousesList.isNotEmpty && _selectedWarehouseId == null) {
        _selectedWarehouseId = _warehousesList.first['id'].toString();
        _selectedWarehouseName = _warehousesList.first['nom_entrepot'].toString();
        await _loadProductsByWarehouse(_selectedWarehouseId!);
      }

      if (mounted) setState(() => _isLoadingGlobalStats = false);
    } catch (e) {
      debugPrint("Erreur Supabase SQL : $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Détail de l'erreur : ${e.toString()}";
          _isLoadingGlobalStats = false;
        });
      }
    }
  }

  // Charge les produits spécifiques liés à un entrepôt donné via une clause de filtrage (eq)
  Future<void> _loadProductsByWarehouse(String warehouseId) async {
    if (!mounted) return;
    setState(() => _isLoadingFilteredProducts = true);

    try {
      final productsRes = await supabase
          .from(_tableProduits)
          .select('id, $_colonneNomProduit, quantite')
          .eq('entrepot_id', warehouseId)
          .order(_colonneNomProduit);

      if (mounted) {
        setState(() {
          _productsInSelectedWarehouse = List<Map<String, dynamic>>.from(productsRes);
          _isLoadingFilteredProducts = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur filtrage entrepôt $warehouseId : $e");
      if (mounted) {
        setState(() {
          _productsInSelectedWarehouse = [];
          _isLoadingFilteredProducts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _primaryColor)));
    }

    return BanLayout(
      title: "TABLEAU DE BORD STATISTIQUE",
      activeRoute: '/dashboard_stats',
      child: Container(
        color: _backgroundColor,
        padding: const EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              if (_errorMessage != null) _buildErrorBanner(),
              if (_errorMessage == null && _isLoadingGlobalStats)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64.0),
                  child: Center(child: CircularProgressIndicator(color: _primaryColor)),
                )
              else ...[
                _buildKPIGrid(), // Grille adaptative des compteurs
                const SizedBox(height: 40),
                _buildWarehouseFilterAndProductTableSection(), // Zone de filtrage et tableau
              ],
            ],
          ),
        ),
      ),
    );
  }

  // En-tête de page avec titre explicatif et bouton de rafraîchissement manuel
  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Vue d'Ensemble de l'Activité", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: _textColorPrimary)),
          const SizedBox(height: 6),
          Text("Données consolidées en temps réel issues de l'infrastructure de production.", style: GoogleFonts.poppins(color: _textColorSecondary, fontSize: 14)),
        ],
      ),
      ElevatedButton.icon(
        onPressed: _loadGlobalStatistics, 
        icon: const Icon(Icons.sync_rounded, size: 20),
        label: Text("SYNCHRONISER LES DONNÉES", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _surfaceColor, foregroundColor: _primaryColor,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
      ),
    ],
  );

  // Bannière d'erreur rouge élégante affichée en cas de rupture de connexion ou mauvaise requête
  Widget _buildErrorBanner() => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 24), 
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
        const SizedBox(width: 12),
        Expanded(child: Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.red.shade800, fontWeight: FontWeight.w500))),
      ],
    ),
  );

  // Grille réactive (LayoutBuilder) modifiant le nombre de cartes affichées par ligne selon la largeur de l'écran
  Widget _buildKPIGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 5;
        if (constraints.maxWidth < 1400) crossAxisCount = 3;
        if (constraints.maxWidth < 900) crossAxisCount = 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20, mainAxisSpacing: 20,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5, 
          children: [
            _StatCard(title: "Produits Enregistrés", value: "$_countProductsRegistered", subtitle: "Catalogue d'articles uniques", icon: Icons.assignment_outlined, color: const Color(0xFF4F46E5)), 
            _StatCard(title: "Nombre d'Entrepôts", value: "$_countWarehouses", subtitle: "Infrastructures logistiques", icon: Icons.warehouse_outlined, color: _primaryColor),
            _StatCard(title: "Utilisateurs Staff", value: "$_countStaffUsers", subtitle: "Équipe administrative", icon: Icons.manage_accounts_outlined, color: const Color(0xFF0369A1)), 
            _StatCard(title: "Comptes Clients", value: "$_countClientUsers", subtitle: "Opérateurs économiques", icon: Icons.people_alt_outlined, color: const Color(0xFF2563EB)), 
            _StatCard(title: "Commandes Totales", value: "$_countTotalOrders", subtitle: "Flux de transactions réelles", icon: Icons.shopping_cart_outlined, color: const Color(0xFFD97706)), 
          ],
        );
      },
    );
  }

  // Section contenant le sélecteur d'entrepôt et le tableau des stocks associés
  Widget _buildWarehouseFilterAndProductTableSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Informations produits par entrepôt", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _textColorPrimary)),
                  const SizedBox(height: 4),
                  Text("Inventaire filtré par site de stockage physique.", style: GoogleFonts.poppins(color: _textColorSecondary, fontSize: 13)),
                ],
              ),
              _warehousesList.isEmpty
                  ? Text("Aucun entrepôt trouvé", style: TextStyle(color: _textColorSecondary))
                  : Container(
                      width: 300, padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: _backgroundColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedWarehouseId, isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: _primaryColor),
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _textColorPrimary),
                          dropdownColor: _surfaceColor, borderRadius: BorderRadius.circular(10),
                          items: _warehousesList.map((wh) {
                            return DropdownMenuItem<String>(
                              value: wh['id'].toString(),
                              child: Text(wh['nom_entrepot'].toString()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue != _selectedWarehouseId) {
                              final selectedWh = _warehousesList.firstWhere((element) => element['id'].toString() == newValue);
                              setState(() {
                                _selectedWarehouseId = newValue;
                                _selectedWarehouseName = selectedWh['nom_entrepot'].toString();
                              });
                              _loadProductsByWarehouse(newValue); 
                            }
                          },
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Choix conditionnel du Widget à afficher selon le statut de chargement ou le volume de données
          _isLoadingFilteredProducts
              ? const Padding(padding: EdgeInsets.all(48.0), child: Center(child: CircularProgressIndicator(color: _primaryColor)))
              : _productsInSelectedWarehouse.isEmpty
                  ? _buildEmptyProductsState()
                  : _buildProductsDataTable(),
        ],
      ),
    );
  }

  // État visuel vide (Placeholder) si l'entrepôt sélectionné ne détient aucun produit enregistré
  Widget _buildEmptyProductsState() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text("Aucune marchandise répertoriée.", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _textColorSecondary)),
          Text("Les stocks de cet entrepôt sont actuellement à zéro dans la base de données.", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // Construction du tableau de données (DataTable HTML-like) listant les produits
  Widget _buildProductsDataTable() {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        dataRowMinHeight: 60, dataRowMaxHeight: 60, horizontalMargin: 12, columnSpacing: 24,
        columns: [
          DataColumn(label: _buildTableHeader("NOM PRODUIT")),
          DataColumn(label: _buildTableHeader("QUANTITÉ ENTRÉES")),
          DataColumn(label: _buildTableHeader("QUANTITÉ SORTIES")),
          DataColumn(label: _buildTableHeader("EN STOCK")),
          DataColumn(label: _buildTableHeader("LOCALISATION ENTREPOT")),
        ],
        rows: _productsInSelectedWarehouse.map((product) {
          // Cast sécurisé de l'élément numérique dynamique en double avant traitement
          final double qteStock = (product['quantite'] as num? ?? 0.0).toDouble();
          
          return DataRow(cells: [
            DataCell(Text(product[_colonneNomProduit] ?? 'Manioc', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: _textColorPrimary))),
            DataCell(Text("0", style: GoogleFonts.poppins(color: _textColorSecondary, fontSize: 14))),
            DataCell(Text("0", style: GoogleFonts.poppins(color: _textColorSecondary, fontSize: 14))),
            DataCell(
              Text(
                // Supprime les décimales .0 inutiles pour un affichage propre (ex: 50 au lieu de 50.0)
                qteStock.toStringAsFixed(qteStock.truncateToDouble() == qteStock ? 0 : 2),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: qteStock > 0 ? _primaryColor : Colors.red.shade700),
              ),
            ),
            DataCell(Text(_selectedWarehouseName, style: GoogleFonts.poppins(color: _textColorSecondary, fontWeight: FontWeight.w500, fontSize: 14))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF64748B), letterSpacing: 0.5));
  }
}

// --- WIDGET ENCAPSULÉ : CARTE DE STATISTIQUE INDIVIDUELLE (KPI) ---

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
                const SizedBox(height: 8),
                Text(value, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(16),
            // ignore: deprecated_member_use
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 30),
          )
        ],
      ),
    );
  }
}