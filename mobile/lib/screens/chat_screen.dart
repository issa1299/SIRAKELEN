import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

/// Discussion interne entre les 2 partenaires d'une demande.
/// Actualisation automatique toutes les 4 secondes.
class ChatScreen extends StatefulWidget {
  final String demandeId;
  final String userId;
  final String partenaireNom;
  final String trajetLabel;
  const ChatScreen({
    super.key,
    required this.demandeId,
    required this.userId,
    required this.partenaireNom,
    required this.trajetLabel,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  List<dynamic> _messages = [];
  bool _envoi = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _charger(sauterBas: false);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _charger());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _charger({bool sauterBas = true}) async {
    try {
      final msgs = await ApiService.getMessages(widget.demandeId, widget.userId);
      if (!mounted) return;
      final nouveau = msgs.length != _messages.length;
      setState(() => _messages = msgs);
      if (nouveau && sauterBas && _scroll.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _envoyer() async {
    final texte = _message.text.trim();
    if (texte.isEmpty || _envoi) return;
    setState(() => _envoi = true);
    try {
      await ApiService.envoyerMessage(
        demandeId: widget.demandeId,
        auteurId: widget.userId,
        contenu: texte,
      );
      _message.clear();
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: kRed),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Envoi impossible, réessaie.'),
        backgroundColor: kRed,
      ));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  String _heure(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.partenaireNom,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.trajetLabel,
              style: TextStyle(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(color: kOrangeLight, shape: BoxShape.circle),
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: kOrange, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun message',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Écris le premier message pour\norganiser le trajet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: kTextSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i] as Map<String, dynamic>;
                      final moi = (m['auteurId'] as String?) == widget.userId;
                      return Align(
                        alignment: moi ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: moi ? kOrange : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(moi ? 16 : 4),
                              bottomRight: Radius.circular(moi ? 4 : 16),
                            ),
                            border: moi ? null : Border.all(color: kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                moi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['contenu'] as String? ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: moi ? Colors.white : kTextPrimary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _heure(m['creeLe'] as String?),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: moi ? Colors.white70 : kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 500,
                      buildCounter: (_, {required currentLength, maxLength, required isFocused}) =>
                          const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Écris ton message…',
                        filled: true,
                        fillColor: kCream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _envoyer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _envoyer,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: kOrange, shape: BoxShape.circle),
                      child: Center(
                        child: _envoi
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
