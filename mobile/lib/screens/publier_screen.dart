import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api_service.dart';

class PublierScreen extends StatefulWidget {
  final String userId;
  const PublierScreen({super.key, required this.userId});

  @override
  State<PublierScreen> createState() => _PublierScreenState();
}

class _PublierScreenState extends State<PublierScreen> {
  String? _role;
  final _depart = TextEditingController();
  final _destination = TextEditingController();
  final _heure = TextEditingController();
  final _places = TextEditingController(text: '1');
  String _date = '';
  bool _chargement = false;
  String? _erreur;
  bool _publie = false;
  bool _apercu = false;

  static const List<String> _transports = ['Voiture', 'Moto'];
  String? _transportChoisi = 'Voiture';

  @override
  void initState() {
    super.initState();
    final demain = DateTime.now().add(const Duration(days: 1));
    _date = _formatDate(demain);
  }

  @override
  void dispose() {
    _depart.dispose();
    _destination.dispose();
    _heure.dispose();
    _places.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = _formatDate(picked));
    }
  }

  Future<void> _choisirHeure() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 30),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() =>
          _heure.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _publier() async {
    if (_role == null ||
        _depart.text.trim().isEmpty ||
        _destination.text.trim().isEmpty ||
        _heure.text.isEmpty) {
      setState(() => _erreur = 'Remplis tous les champs obligatoires');
      return;
    }
    if (_role == 'conducteur' && _places.text.isEmpty) {
      setState(() => _erreur = 'Indique le nombre de places');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await ApiService.publierAd(
        userId: widget.userId,
        role: _role!,
        depart: _depart.text.trim(),
        destination: _destination.text.trim(),
        dateDeplacement: _date,
        heureDepart: _heure.text,
        moyenTransport: _role == 'conducteur'
            ? (_transportChoisi ?? 'Voiture')
            : null,
        placesDisponibles:
            _role == 'conducteur' ? int.tryParse(_places.text) : null,
      );
      if (!mounted) return;
      setState(() {
        _publie = true;
        _chargement = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = 'Connexion au serveur impossible';
        _chargement = false;
      });
    }
  }

  String _dateLisible() {
    final d = DateTime.tryParse(_date);
    if (d == null) return _date;
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final aujourdhui = DateTime.now();
    final demain = aujourdhui.add(const Duration(days: 1));
    String prefixe = '${d.day} ${mois[d.month - 1]}';
    if (d.year == aujourdhui.year &&
        d.month == aujourdhui.month &&
        d.day == aujourdhui.day) {
      prefixe = "Aujourd'hui, ${d.day} ${mois[d.month - 1]}";
    } else if (d.year == demain.year &&
        d.month == demain.month &&
        d.day == demain.day) {
      prefixe = 'Demain, ${d.day} ${mois[d.month - 1]}';
    }
    return prefixe;
  }

  Widget _ecranApercu() {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Aperçu de l\'AD')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Preview header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8F0), Color(0xFFFFF3E6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kOrange.withAlpha(60)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: kOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _role == 'conducteur'
                          ? Icons.directions_car_rounded
                          : Icons.person_search_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _role == 'conducteur'
                        ? '${_transportChoisi ?? 'Voiture'} · ${_places.text} place(s)'
                        : 'À la recherche d\'un conducteur',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Summary rows
            _ligneRecap(Icons.route_rounded, 'Trajet', '$_depart → $_destination'),
            _ligneRecap(Icons.calendar_today_rounded, 'Date', _dateLisible()),
            _ligneRecap(Icons.access_time_rounded, 'Horaire', _heure.text),
            if (_role == 'conducteur')
              _ligneRecap(Icons.event_seat_rounded, 'Places', '${_places.text} place(s)'),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _chargement ? null : _publier,
                child: _chargement
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(_role == 'conducteur'
                        ? 'Publier mon AD'
                        : 'Rechercher les trajets compatibles'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => setState(() => _apercu = false),
                child: const Text('Modifier'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _ligneRecap(IconData icone, String label, String valeur) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kOrangeLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, size: 16, color: kOrange),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: kTextSecondary)),
          const Spacer(),
          Text(
            valeur,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_apercu && !_publie) {
      return _ecranApercu();
    }

    if (_publie) {
      return Scaffold(
        backgroundColor: kCream,
        appBar: AppBar(title: const Text('AD publié')),
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: kGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                _role == 'conducteur'
                    ? 'Ton AD conducteur est publié !'
                    : 'Ton AD passager est publié !',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _role == 'conducteur'
                    ? 'Les passagers compatibles verront ton trajet.'
                    : 'Nous cherchons les conducteurs compatibles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Retour à l\'accueil'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: Text(_role == null ? 'Publier un AD' : 'Nouvel AD'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Quel est ton statut pour ce trajet ?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _role == null ? kTextPrimary : kTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            _carteRole(
              icone: Icons.directions_car_rounded,
              titre: 'Je conduis',
              description: 'Je propose des places dans mon véhicule.',
              valeur: 'conducteur',
            ),
            const SizedBox(height: 10),
            _carteRole(
              icone: Icons.person_search_rounded,
              titre: 'Je cherche un trajet',
              description: 'Je veux rejoindre un conducteur compatible.',
              valeur: 'passager',
            ),
            if (_role != null) ...[
              const SizedBox(height: 24),
              Text(
                _role == 'conducteur' ? 'Ton trajet' : 'Trajet souhaité',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _depart,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Départ',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  hintText: 'Kalaban Coro',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _destination,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: Icon(Icons.flag_outlined, size: 20),
                  hintText: 'FST — Faculté des Sciences',
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _choisirDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date du déplacement',
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                  ),
                  child: Text(_date, style: const TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _choisirHeure,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Heure de départ',
                    prefixIcon: Icon(Icons.access_time_rounded, size: 20),
                  ),
                  child: Text(
                    _heure.text.isEmpty ? '--:--' : _heure.text,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              if (_role == 'conducteur') ...[
                const SizedBox(height: 18),
                const Text(
                  'Moyen de transport',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _transports
                      .map((t) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Center(child: Text(t)),
                                selected: _transportChoisi == t,
                                selectedColor: kOrange,
                                labelStyle: TextStyle(
                                  color: _transportChoisi == t
                                      ? Colors.white
                                      : kTextSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _transportChoisi = t),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _places,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Places disponibles',
                    prefixIcon: Icon(Icons.event_seat_rounded, size: 20),
                  ),
                ),
              ],
            ],
            if (_erreur != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kRed.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: kRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _erreur!,
                        style: const TextStyle(color: kRed, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (_role != null)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _chargement
                      ? null
                      : () {
                          if (_depart.text.trim().isEmpty ||
                              _destination.text.trim().isEmpty ||
                              _heure.text.isEmpty) {
                            setState(() =>
                                _erreur = 'Remplis tous les champs obligatoires');
                            return;
                          }
                          FocusScope.of(context).unfocus();
                          setState(() => _apercu = true);
                        },
                  child: const Text('Voir l\'aperçu'),
                ),
              ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _carteRole({
    required IconData icone,
    required String titre,
    required String description,
    required String valeur,
  }) {
    final selected = _role == valeur;
    return GestureDetector(
      onTap: () => setState(() => _role = valeur),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? kOrangeLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kOrange : kBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? kOrange : kGreyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icone,
                color: selected ? Colors.white : kTextSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: kTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: kOrange, size: 22),
          ],
        ),
      ),
    );
  }
}
