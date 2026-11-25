import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../widgets/carte_ad.dart';
import '../widgets/responsive_wrapper.dart';
import 'detail_ad_public_screen.dart';
import 'publier_screen.dart';

/// Ecran « Parcourir tous les AD ».
/// Acces conditionne cote serveur a un AD actif non expire.
class ParcourirAdsScreen extends StatefulWidget {
  final String userId;
  final String? departDefaut;
  final String? destinationDefaut;
  const ParcourirAdsScreen({
    super.key,
    required this.userId,
    this.departDefaut,
    this.destinationDefaut,
  });

  @override
  State<ParcourirAdsScreen> createState() => _ParcourirAdsScreenState();
}

class _ParcourirAdsScreenState extends State<ParcourirAdsScreen> {
  final _scroll = ScrollController();

  List<dynamic> _items = [];
  int _page = 1;
  bool _chargement = true;
  bool _chargementPlus = false;
  bool _fini = false;
  String? _erreur;
  bool _accesRefuse = false;

  String _tri = 'pertinence';
  bool _elargir = false;
  String? _date;
  String? _heureDebut;
  String? _heureFin;
  String? _zoneDepart;
  String? _zoneArrivee;
  String? _transport;

  @override
  void initState() {
    super.initState();
    _charger(premier: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_chargementPlus &&
        !_fini &&
        !_chargement) {
      _chargerPlus();
    }
  }

  Future<void> _charger({bool premier = false}) async {
    if (premier) {
      setState(() {
        _chargement = true;
        _erreur = null;
        _accesRefuse = false;
        _items = [];
        _page = 1;
        _fini = false;
      });
    }
    try {
      final res = await ApiService.parcourirAds(
        userId: widget.userId,
        page: _page,
        tri: _tri,
        date: _date,
        heureDebut: _heureDebut,
        heureFin: _heureFin,
        zoneDepart: _zoneDepart,
        zoneArrivee: _zoneArrivee,
        transport: _transport,
        elargir: _elargir,
      );
      final items = (res['items'] as List<dynamic>?) ?? [];
      if (!mounted) return;
      setState(() {
        if (premier || _page == 1) {
          _items = items;
        } else {
          _items.addAll(items);
        }
        final total = (res['total'] as num?)?.toInt() ?? _items.length;
        _fini = _items.length >= total;
        _chargement = false;
        _chargementPlus = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'AD_ACTIF_REQUIS') {
        setState(() {
          _accesRefuse = true;
          _chargement = false;
          _chargementPlus = false;
        });
      } else {
        setState(() {
          _erreur = e.message;
          _chargement = false;
          _chargementPlus = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Connexion au serveur impossible';
        _chargement = false;
        _chargementPlus = false;
      });
    }
  }

  Future<void> _chargerPlus() async {
    if (_fini) return;
    setState(() => _chargementPlus = true);
    _page += 1;
    await _charger();
  }

  Future<void> _refresh() async {
    _page = 1;
    await _charger(premier: true);
  }

  void _ouvrirFiltres() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FiltresSheet(
        date: _date,
        heureDebut: _heureDebut,
        heureFin: _heureFin,
        zoneDepart: _zoneDepart,
        zoneArrivee: _zoneArrivee,
        transport: _transport,
        onAppliquer: (d, hd, hf, zd, za, tr) {
          setState(() {
            _date = d;
            _heureDebut = hd;
            _heureFin = hf;
            _zoneDepart = zd;
            _zoneArrivee = za;
            _transport = tr;
          });
          _refresh();
        },
      ),
    );
  }

  int get _nbFiltresActifs {
    int n = 0;
    if (_date != null) n++;
    if (_heureDebut != null || _heureFin != null) n++;
    if (_zoneDepart != null && _zoneDepart!.isNotEmpty) n++;
    if (_zoneArrivee != null && _zoneArrivee!.isNotEmpty) n++;
    if (_transport != null && _transport!.isNotEmpty) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: const Text('Parcourir tous les trajets'),
      ),
      body: ResponsiveWrapper(child: _corps()),
    );
  }

  Widget _corps() {
    if (_accesRefuse) {
      return _etatAccesRefuse();
    }
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: kOrange));
    }
    if (_erreur != null && _items.isEmpty) {
      return _etatErreur();
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: kOrange,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Barre de tri + filtres
          _barreOutils(),
          const SizedBox(height: 12),
          if (_items.isEmpty) _etatVide() else ...[
            ..._items.map((it) {
              final m = it as Map<String, dynamic>;
              return CarteAd(
                ad: m,
                compatible: m['compatible'] as Map<String, dynamic>?,
                distanceKm: (m['distanceKm'] as num?)?.toDouble(),
                dureeMinutes: (m['dureeMinutes'] as num?)?.toInt(),
                proximiteKm: (m['proximiteKm'] as num?)?.toDouble(),
                proprietaire: m['proprietaire'] as Map<String, dynamic>?,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailAdPublicScreen(
                      ad: m,
                      userId: widget.userId,
                    ),
                  ),
                ),
              );
            }),
          ],
          if (_chargementPlus)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: kOrange)),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _barreOutils() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Tri
        ChoiceChip(
          label: Text(_tri == 'pertinence' ? 'Pertinence' : 'Date'),
          selected: true,
          onSelected: (_) {
            setState(() => _tri = _tri == 'pertinence' ? 'date' : 'pertinence');
            _refresh();
          },
          selectedColor: kOrangeLight,
          labelStyle: const TextStyle(color: kOrange, fontWeight: FontWeight.w700, fontSize: 12),
        ),
        // Filtres
        ActionChip(
          avatar: Icon(Icons.tune_rounded, size: 16, color: _nbFiltresActifs > 0 ? kOrange : kTextSecondary),
          label: Text('Filtres${_nbFiltresActifs > 0 ? ' ($_nbFiltresActifs)' : ''}'),
          onPressed: _ouvrirFiltres,
        ),
        // Elargir
        FilterChip(
          label: const Text('Élargir'),
          selected: _elargir,
          onSelected: (v) {
            setState(() => _elargir = v);
            _refresh();
          },
          selectedColor: kOrangeLight,
          checkmarkColor: kOrange,
          labelStyle: TextStyle(
            color: _elargir ? kOrange : kTextSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _etatVide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: kOrangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.route_rounded, color: kOrange, size: 30),
          ),
          const SizedBox(height: 16),
          const Text('Aucun trajet pour le moment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextPrimary)),
          const SizedBox(height: 8),
          Text(
            _elargir
                ? 'Aucun trajet ne correspond à tes filtres.'
                : 'Élargis la recherche ou modifie les filtres pour voir plus de trajets.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kTextSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (!_elargir)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  setState(() => _elargir = true);
                  _refresh();
                },
                child: const Text('Élargir la recherche'),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _ouvrirFiltres,
              child: const Text('Modifier les filtres'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _etatErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: kTextSecondary),
            const SizedBox(height: 12),
            Text(_erreur ?? 'Erreur réseau', textAlign: TextAlign.center, style: TextStyle(color: kTextSecondary)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  Widget _etatAccesRefuse() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: kOrangeLight, shape: BoxShape.circle),
              child: const Icon(Icons.route_rounded, color: kOrange, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Publie un trajet pour parcourir les trajets',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 8),
            Text(
              'Pour parcourir tous les trajets, tu dois d\'abord publier un Avis de Déplacement actif.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PublierScreen(userId: widget.userId)),
                  );
                  _refresh();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Publier un trajet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feuille de filtres
// ---------------------------------------------------------------------------

class _FiltresSheet extends StatefulWidget {
  final String? date;
  final String? heureDebut;
  final String? heureFin;
  final String? zoneDepart;
  final String? zoneArrivee;
  final String? transport;
  final void Function(String?, String?, String?, String?, String?, String?) onAppliquer;

  const _FiltresSheet({
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.zoneDepart,
    required this.zoneArrivee,
    required this.transport,
    required this.onAppliquer,
  });

  @override
  State<_FiltresSheet> createState() => _FiltresSheetState();
}

class _FiltresSheetState extends State<_FiltresSheet> {
  late TextEditingController _zd;
  late TextEditingController _za;
  String? _date;
  String? _hd;
  String? _hf;
  String? _transport;

  @override
  void initState() {
    super.initState();
    _date = widget.date;
    _hd = widget.heureDebut;
    _hf = widget.heureFin;
    _zd = TextEditingController(text: widget.zoneDepart ?? '');
    _za = TextEditingController(text: widget.zoneArrivee ?? '');
    _transport = widget.transport;
  }

  @override
  void dispose() {
    _zd.dispose();
    _za.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date != null ? DateTime.tryParse(_date!) ?? now : now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _date = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _choisirHeure(bool debut) async {
    final initial = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final s = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (debut) {
          _hd = s;
        } else {
          _hf = s;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtres', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextPrimary)),
            const SizedBox(height: 16),
            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(_date ?? 'Toutes'),
              trailing: const Icon(Icons.calendar_today_rounded, color: kOrange),
              onTap: _choisirDate,
            ),
            if (_date != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _date = null),
                  child: const Text('Effacer la date'),
                ),
              ),
            // Heure
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _choisirHeure(true),
                    child: Text(_hd == null ? 'Heure min' : _hd!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _choisirHeure(false),
                    child: Text(_hf == null ? 'Heure max' : _hf!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _zd,
              decoration: const InputDecoration(
                labelText: 'Zone de départ',
                hintText: 'ex. Sirakoro',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _za,
              decoration: const InputDecoration(
                labelText: 'Zone d\'arrivée',
                hintText: 'ex. FST Bamako',
              ),
            ),
            const SizedBox(height: 12),
            const Text('Transport', style: TextStyle(fontWeight: FontWeight.w700, color: kTextSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['Tous', 'Voiture', 'Moto'].map((t) {
                final val = t == 'Tous' ? null : t;
                return ChoiceChip(
                  label: Text(t),
                  selected: _transport == val,
                  onSelected: (_) => setState(() => _transport = val),
                  selectedColor: kOrangeLight,
                  labelStyle: TextStyle(color: _transport == val ? kOrange : kTextSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _date = null;
                        _hd = null;
                        _hf = null;
                        _zd.clear();
                        _za.clear();
                        _transport = null;
                      });
                    },
                    child: const Text('Tout effacer'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onAppliquer(
                        _date,
                        _hd,
                        _hf,
                        _zd.text.trim().isEmpty ? null : _zd.text.trim(),
                        _za.text.trim().isEmpty ? null : _za.text.trim(),
                        _transport,
                      );
                    },
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
