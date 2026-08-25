import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class PublierScreen extends StatefulWidget {
  final String userId;
  const PublierScreen({super.key, required this.userId});

  @override
  State<PublierScreen> createState() => _PublierScreenState();
}

class _PublierScreenState extends State<PublierScreen> {
  String? _role; // 'conducteur' ou 'passager'
  final _depart = TextEditingController();
  final _destination = TextEditingController();
  final _heure = TextEditingController();
  final _places = TextEditingController(text: '1');
  String _date = '';
  bool _chargement = false;
  String? _erreur;
  bool _publie = false;

  static const List<String> _transports = ['Voiture', 'Moto'];

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

  String? _transportChoisi = 'Voiture';

  @override
  Widget build(BuildContext context) {
    // Écran de confirmation
    if (_publie) {
      return Scaffold(
        appBar: AppBar(title: const Text('AD publié'), backgroundColor: Colors.transparent),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                    color: kGreen, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 20),
              Text(
                _role == 'conducteur'
                    ? 'Ton AD conducteur est publié !'
                    : 'Ton AD passager est publié !',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                _role == 'conducteur'
                    ? 'Les passagers compatibles verront ton trajet.'
                    : 'Nous cherchons les conducteurs compatibles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => HomeScreen(userId: widget.userId)),
                  (route) => false,
                ),
                child: const Text('Retour à l’accueil'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_role == null ? 'Publier un AD' : 'Nouvel AD'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Étape 1 : choix du rôle =====
            Text(
              'Quel est ton statut pour ce trajet ?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: _role == null ? kOrangeDark : Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            _carteRole(
              icone: Icons.directions_car,
              titre: 'Je conduis',
              description:
                  'Je propose des places dans mon véhicule à des passagers au trajet similaire.',
              valeur: 'conducteur',
            ),
            const SizedBox(height: 10),
            _carteRole(
              icone: Icons.person_search,
              titre: 'Je cherche un trajet',
              description:
                  'Je veux rejoindre un conducteur qui effectue un trajet similaire au mien.',
              valeur: 'passager',
            ),
            if (_role != null) ...[
              const SizedBox(height: 20),
              Text(
                _role == 'conducteur' ? 'Ton trajet' : 'Trajet souhaité',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _depart,
                decoration: const InputDecoration(
                  labelText: 'Départ',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'Kalaban Coro',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _destination,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: Icon(Icons.flag_outlined),
                  hintText: 'FST — Faculté des Sciences',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _choisirDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date du déplacement',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(_date),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _choisirHeure,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure de départ',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_heure.text.isEmpty ? '--:--' : _heure.text),
                      ),
                    ),
                  ),
                ],
              ),
              if (_role == 'conducteur') ...[
                const SizedBox(height: 12),
                const Text('Moyen de transport',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
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
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _transportChoisi = t),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _places,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Places disponibles',
                    prefixIcon: Icon(Icons.event_seat),
                  ),
                ),
              ],
            ],
            if (_erreur != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_erreur!,
                    style: const TextStyle(
                        color: Color(0xFFA3392F), fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            if (_role != null)
              FilledButton(
                onPressed: _chargement ? null : _publier,
                child: _chargement
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_role == 'conducteur'
                        ? 'Publier mon AD'
                        : 'Rechercher les trajets compatibles'),
              ),
            const SizedBox(height: 24),
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
    final selectionne = _role == valeur;
    return InkWell(
      onTap: () => setState(() => _role = valeur),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selectionne ? const Color(0xFFFFF3E6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectionne ? kOrange : const Color(0xFFEDEAE2),
            width: selectionne ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selectionne ? kOrange : const Color(0xFFF6F5F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone,
                  color: selectionne ? Colors.white : Colors.grey.shade600),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(description,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
