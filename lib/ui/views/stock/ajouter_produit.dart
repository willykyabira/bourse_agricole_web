import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AjouterProduit extends StatefulWidget {
  final Map<String, dynamic>? productToEdit;
  final bool isDialog;

  const AjouterProduit({
    super.key,
    this.productToEdit,
    required this.isDialog,
    Map<String, dynamic>? produitExistant,
  });

  @override
  State<AjouterProduit> createState() => _AjouterProduitState();
}

class _AjouterProduitState extends State<AjouterProduit> {
  final Color primaryGreen = const Color(0xFF1B5E20);
  final _formKey = GlobalKey<FormState>();
  
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isLoading = true;
  bool _isEditMode = false;

  String? _currentEntrepotId;
  String? _selectedClientId;

  List<Map<String, dynamic>> _clientsSuggestions = [];

  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _catCtrl = TextEditingController();
  final TextEditingController _qteCtrl = TextEditingController();
  final TextEditingController _puCtrl = TextEditingController();
  final TextEditingController _ptCtrl = TextEditingController();
  final TextEditingController _nomClientCtrl = TextEditingController();

  DateTime? _dateRecolte;
  DateTime? _datePeremption;

  // Dictionnaire de correspondance automatique entre cultures et catégories BAN
  final Map<String, String> _mappingCategories = {
    'Tomate': 'Produits frais',
    'Banane': 'Produits frais',
    'Mangue': 'Produits frais',
    'Légumes feuilles': 'Produits frais',
    'Manioc frais': 'Tubercules',
    'Patate douce': 'Tubercules',
    'Pomme de terre': 'Tubercules',
    'Maïs (grain sec)': 'Céréales',
    'Riz': 'Céréales',
    'Haricots': 'Céréales',
    'Soja': 'Céréales',
    'Arachides': 'Oléagineux',
    'Sésame': 'Oléagineux',
    'Manioc séché': 'Transformés',
    'Café': 'Transformés',
    'Cacao': 'Transformés',
  };

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.productToEdit != null;
    _chargerInfosInitiales().then((_) {
      if (_isEditMode) {
        _remplirChampsPourEdition();
      }
    });
    _qteCtrl.addListener(_calculerPrixTotal);
    _puCtrl.addListener(_calculerPrixTotal);
  }

  // Restitution des valeurs du produit lors du basculement en mode édition
  void _remplirChampsPourEdition() {
    final p = widget.productToEdit!;
    setState(() {
      _nomCtrl.text = p['nom_produit']?.toString() ?? '';
      _catCtrl.text = p['nom_categorie']?.toString() ?? '';
      _qteCtrl.text = p['quantite']?.toString() ?? '';
      _puCtrl.text = p['prix_unitaire']?.toString() ?? '';
      _ptCtrl.text = p['prix_total']?.toString() ?? '';
      _nomClientCtrl.text = p['nom_client']?.toString() ?? '';
      _selectedClientId = p['client_id']?.toString();

      if (p['date_recolte'] != null) {
        _dateRecolte = DateTime.tryParse(p['date_recolte']);
      }
      if (p['date_peremption'] != null) {
        _datePeremption = DateTime.tryParse(p['date_peremption']);
      }
    });
  }

  // Récupération de l'entrepôt du gestionnaire connecté et de l'annuaire des déposants
  Future<void> _chargerInfosInitiales() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final myProfile = await Supabase.instance.client
          .from('profiles')
          .select('entrepot_id')
          .eq('id', user.id)
          .maybeSingle();

      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, nom_complet, role')
          .eq('role', 'client');

      if (mounted) {
        setState(() {
          _currentEntrepotId = myProfile?['entrepot_id'];
          _clientsSuggestions = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("ERREUR BAN INITIALISATION: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculerPrixTotal() {
    final q = double.tryParse(_qteCtrl.text.trim()) ?? 0;
    final p = double.tryParse(_puCtrl.text.trim()) ?? 0;
    setState(() => _ptCtrl.text = (q * p).toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEditMode ? "MODIFIER LE PRODUIT" : "RÉCEPTION PRODUIT",
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (_isEditMode)
                        _isDeleting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                                tooltip: "Supprimer ce produit",
                                onPressed: _confirmerSuppression,
                              ),
                    ],
                  ),
                  const Divider(height: 30),

                  _sectionTitle("Client / Déposant"),
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (client) => client['nom_complet'] ?? '',
                    optionsBuilder: (textValue) {
                      if (textValue.text.isEmpty) return _clientsSuggestions;
                      return _clientsSuggestions.where((c) => c['nom_complet']
                          .toString()
                          .toLowerCase()
                          .contains(textValue.text.toLowerCase()));
                    },
                    onSelected: (selection) {
                      setState(() {
                        _nomClientCtrl.text = selection['nom_complet'] ?? '';
                        _selectedClientId = selection['id']?.toString();
                      });
                    },
                    fieldViewBuilder: (ctx, autocompleteController, focus, onSubmitted) {
                      if (_nomClientCtrl.text.isNotEmpty && autocompleteController.text.isEmpty) {
                        autocompleteController.text = _nomClientCtrl.text;
                      }
                      return TextFormField(
                        controller: autocompleteController,
                        focusNode: focus,
                        decoration: _decor("Rechercher un client...", icon: Icons.person_search).copyWith(
                          suffixIcon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_drop_down),
                        ),
                        onChanged: (val) {
                          _nomClientCtrl.text = val;
                          _selectedClientId = null;
                        },
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Sélectionnez ou écrivez un client"
                            : null,
                      );
                    },
                    optionsViewBuilder: (ctx, onSelected, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 540,
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            separatorBuilder: (context, i) => const Divider(height: 1),
                            itemBuilder: (ctx, i) => ListTile(
                              leading: Icon(Icons.person, color: primaryGreen),
                              title: Text(options.elementAt(i)['nom_complet']),
                              onTap: () => onSelected(options.elementAt(i)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionTitle("Informations Produit"),
                  DropdownButtonFormField<String>(
                    initialValue: _nomCtrl.text.isNotEmpty && _mappingCategories.containsKey(_nomCtrl.text)
                        ? _nomCtrl.text
                        : null,
                    decoration: _decor("Type de produit", icon: Icons.inventory_2),
                    items: _mappingCategories.keys
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    validator: (v) => (v == null || v.isEmpty) ? "Le type de produit est requis" : null,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _nomCtrl.text = val;
                          _catCtrl.text = _mappingCategories[val]!;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _champ("Catégorie", _catCtrl, actif: false),
                  Row(
                    children: [
                      Expanded(child: _champ("Quantité", _qteCtrl, estNum: true, obligatoire: true)),
                      const SizedBox(width: 15),
                      Expanded(child: _champ("Prix Unit. (\$)", _puCtrl, estNum: true, obligatoire: true)),
                    ],
                  ),
                  _champ("Total (\$)", _ptCtrl, actif: false, icon: Icons.calculate),

                  const SizedBox(height: 20),
                  _sectionTitle("Traçabilité"),
                  Row(
                    children: [
                      Expanded(child: _dateTile("Date Récolte", _dateRecolte, () => _choisirDate(true))),
                      const SizedBox(width: 15),
                      Expanded(child: _dateTile("Date Péremption", _datePeremption, () => _choisirDate(false))),
                    ],
                  ),
                  const SizedBox(height: 35),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _choisirDate(bool isR) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isR ? (_dateRecolte ?? DateTime.now()) : (_datePeremption ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (d != null) {
      setState(() {
        if (isR) {
          _dateRecolte = d;
        } else {
          _datePeremption = d;
        }
      });
    }
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.all(18),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ANNULER",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: const EdgeInsets.all(18),
            ),
            onPressed: _isSaving ? null : _sauvegarder,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _isEditMode ? "METTRE À JOUR" : "ENREGISTRER",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // Soumission et validation du payload pour insertion ou mise à jour
  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateRecolte == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Veuillez sélectionner la date de récolte."),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double qte = double.tryParse(_qteCtrl.text.trim()) ?? 0;
      final double pu = double.tryParse(_puCtrl.text.trim()) ?? 0;
      final double pt = double.tryParse(_ptCtrl.text.trim()) ?? 0;

      final Map<String, dynamic> data = {
        'nom_produit': _nomCtrl.text,
        'quantite': qte,
        'prix_unitaire': pu,
        'prix_total': pt,
        'nom_client': _nomClientCtrl.text.trim(),
        'date_recolte': _dateRecolte?.toIso8601String(),
        'date_peremption': _datePeremption?.toIso8601String(),
        'nom_categorie': _catCtrl.text,
        'entrepot_id': _currentEntrepotId,
        'client_id': _selectedClientId,
      };

      if (_isEditMode) {
        await Supabase.instance.client
            .from('produits')
            .update(data)
            .eq('id', widget.productToEdit!['id']);
      } else {
        await Supabase.instance.client.from('produits').insert(data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          content: Text("Erreur de mise à jour : $e"),
        ),
      );
    }
  }

  Future<void> _confirmerSuppression() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer le produit"),
        content: Text("Êtes-vous sûr de vouloir supprimer définitivement le produit \"${_nomCtrl.text}\" ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULER")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmer == true) {
      _supprimerProduit();
    }
  }

  Future<void> _supprimerProduit() async {
    if (widget.productToEdit == null) {
      _afficherAlerteDialogue("Erreur Locale", "Données du produit introuvables.");
      return;
    }

    final produitId = widget.productToEdit!['id'];
    if (produitId == null) {
      _afficherAlerteDialogue("Erreur de Clé", "L'identifiant 'id' est absent du produit.");
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await Supabase.instance.client
          .from('produits')
          .delete()
          .eq('id', produitId);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        _afficherAlerteDialogue("Échec de la suppression Supabase", e.toString());
      }
    }
  }

  void _afficherAlerteDialogue(String titre, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: SingleChildScrollView(
          child: Text(message, style: const TextStyle(fontFamily: 'monospace')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fermer"),
          )
        ],
      ),
    );
  }

  InputDecoration _decor(String l, {IconData? icon}) => InputDecoration(
        labelText: l,
        prefixIcon: Icon(icon, color: primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      );

  Widget _champ(
    String l,
    TextEditingController c, {
    bool estNum = false,
    bool actif = true,
    IconData? icon,
    bool obligatoire = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          enabled: actif,
          keyboardType: estNum ? TextInputType.number : TextInputType.text,
          decoration: _decor(l, icon: icon),
          validator: obligatoire
              ? (v) => (v == null || v.trim().isEmpty) ? "Ce champ est obligatoire" : null
              : null,
        ),
      );

  Widget _dateTile(String l, DateTime? d, VoidCallback t) => InkWell(
        onTap: t,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            d == null ? l : DateFormat('dd/MM/yyyy').format(d),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12),
        ),
      );
}