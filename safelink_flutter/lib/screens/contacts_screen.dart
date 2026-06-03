import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../services/contacts_service.dart';
import '../widgets/wave_background.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, String>> _contacts = [];
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactsService.getContacts();
    if (mounted) setState(() { _contacts = contacts; _loading = false; });
  }

  Future<void> _addContact() async {
    final name  = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter both name and phone.')));
      return;
    }
    await ContactsService.addContact({'name': name, 'phone': phone});
    _nameCtrl.clear();
    _phoneCtrl.clear();
    if (mounted) FocusScope.of(context).unfocus();
    await _loadContacts();
  }

  Future<void> _removeContact(int index) async {
    await ContactsService.removeContact(index);
    await _loadContacts();
  }

  Future<void> _pickFromPhoneContacts() async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);
    if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacts permission denied.')));
      return;
    }
    // Load contacts with phone + photo
    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone},
    );
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SL.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ContactPickerSheet(
        contacts: contacts,
        alreadySaved: _contacts.map((c) => c['phone'] ?? '').toSet(),
        onPick: (selected) async {
          for (final c in selected) {
            final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
            if (phone.isEmpty) continue;
            await ContactsService.addContact({'name': c.displayName ?? '', 'phone': phone});
          }
          await _loadContacts();
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: WaveBackground())),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: SL.lime))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EMERGENCY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 2)),
                        const Text('CONTACTS', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: SL.white, height: 1, letterSpacing: -1)),
                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: SL.red.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SL.red.withAlpha(50)),
                          ),
                          child: const Text('These people get an SMS with your location when SOS fires.',
                              style: TextStyle(fontSize: 12, color: SL.red, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 28),

                        // Import from phone
                        GestureDetector(
                          onTap: _pickFromPhoneContacts,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: SL.pink.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SL.pink.withAlpha(60)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.contacts_rounded, color: SL.pink, size: 18),
                                SizedBox(width: 8),
                                Text('IMPORT FROM PHONE CONTACTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: SL.pink, letterSpacing: 1.2)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // OR divider
                        const Row(
                          children: [
                            Expanded(child: Divider(color: SL.border)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR', style: TextStyle(fontSize: 11, color: SL.grey, fontWeight: FontWeight.w700, letterSpacing: 1)),
                            ),
                            Expanded(child: Divider(color: SL.border)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        const Text('ADD MANUALLY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        _DarkField(controller: _nameCtrl, label: 'NAME', hint: 'e.g. Mum', icon: Icons.person_outline_rounded),
                        const SizedBox(height: 12),
                        _DarkField(controller: _phoneCtrl, label: 'PHONE', hint: '+44 7700 000000', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _addContact,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(color: SL.lime, borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: const Text('ADD CONTACT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SL.bg, letterSpacing: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Saved list
                        Row(
                          children: [
                            const Text('SAVED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: SL.lime, borderRadius: BorderRadius.circular(100)),
                              child: Text('${_contacts.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SL.bg)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_contacts.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SL.border)),
                            child: const Text('No contacts saved yet.\nAdd one above or import from your phone.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: SL.grey)),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _contacts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final c = _contacts[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SL.border)),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(color: SL.pink.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.person_rounded, color: SL.pink, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: SL.white)),
                                          Text(c['phone'] ?? '', style: const TextStyle(fontSize: 12, color: SL.grey)),
                                        ],
                                      ),
                                    ),
                                    // Quick-call button
                                    GestureDetector(
                                      onTap: () async {
                                        final phone = (c['phone'] ?? '').replaceAll(' ', '');
                                        final uri = Uri.parse('tel:$phone');
                                        if (await canLaunchUrl(uri)) launchUrl(uri);
                                      },
                                      child: Container(
                                        width: 36, height: 36,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(color: SL.lime.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.call_rounded, color: SL.lime, size: 18),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _removeContact(i),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: SL.red.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('REMOVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SL.red, letterSpacing: 1)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Multi-select contact picker sheet ─────────────────────────────────────

class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;
  final Set<String> alreadySaved;
  final Future<void> Function(List<Contact>) onPick;

  const _ContactPickerSheet({required this.contacts, required this.alreadySaved, required this.onPick});

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final Set<int> _selected = {};
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: SL.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Expanded(child: Text('SELECT CONTACTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5))),
                if (selectedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: SL.lime, borderRadius: BorderRadius.circular(100)),
                    child: Text('$selectedCount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SL.bg)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Contact list
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: widget.contacts.length,
              itemBuilder: (_, i) {
                final c = widget.contacts[i];
                final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
                final isSelected = _selected.contains(i);
                final alreadyAdded = widget.alreadySaved.contains(phone);
                return ListTile(
                  leading: _contactAvatar(c.displayName ?? ''),
                  title: Text(c.displayName ?? '', style: const TextStyle(color: SL.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    phone.isEmpty ? 'No number' : phone,
                    style: TextStyle(color: alreadyAdded ? SL.lime : SL.grey, fontSize: 12),
                  ),
                  trailing: alreadyAdded
                      ? const Icon(Icons.check_circle_rounded, color: SL.lime, size: 20)
                      : Checkbox(
                          value: isSelected,
                          activeColor: SL.lime,
                          checkColor: SL.bg,
                          side: const BorderSide(color: SL.border),
                          onChanged: phone.isEmpty ? null : (v) => setState(() {
                            v == true ? _selected.add(i) : _selected.remove(i);
                          }),
                        ),
                  onTap: (phone.isEmpty || alreadyAdded) ? null : () => setState(() {
                    _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
                  }),
                );
              },
            ),
          ),

          // Add selected button
          if (selectedCount > 0)
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
              child: GestureDetector(
                onTap: _adding ? null : () async {
                  setState(() => _adding = true);
                  final picked = _selected.map((i) => widget.contacts[i]).toList();
                  Navigator.of(context).pop();
                  await widget.onPick(picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: SL.lime, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(
                    'ADD $selectedCount CONTACT${selectedCount > 1 ? 'S' : ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SL.bg, letterSpacing: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactAvatar(String name) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: SL.pink.withAlpha(25), borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: SL.pink, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

// ── Input field ────────────────────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  const _DarkField({required this.controller, required this.label, required this.hint, required this.icon, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(color: SL.white, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: SL.darkGrey, fontSize: 13),
            prefixIcon: Icon(icon, color: SL.grey, size: 18),
            filled: true,
            fillColor: SL.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SL.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SL.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SL.lime, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
