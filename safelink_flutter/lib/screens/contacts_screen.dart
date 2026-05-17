import 'package:flutter/material.dart';
import '../services/contacts_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, String>> _contacts = [];
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactsService.getContacts();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    }
  }

  Future<void> _addContact() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and phone.')),
      );
      return;
    }

    await ContactsService.addContact({'name': name, 'phone': phone});
    _nameCtrl.clear();
    _phoneCtrl.clear();
    FocusScope.of(context).unfocus();
    await _loadContacts();
  }

  Future<void> _removeContact(int index) async {
    await ContactsService.removeContact(index);
    await _loadContacts();
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
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color(0xFF534AB7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE24B4A).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE24B4A).withAlpha(50),
                      ),
                    ),
                    child: const Text(
                      'These contacts will receive an SMS with your '
                      'location when an SOS alert fires.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFE24B4A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Add contact form
                  const Text(
                    'Add Contact',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      hintText: '+44 7700 000000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addContact,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF534AB7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Saved contacts list
                  Text(
                    'Saved Contacts (${_contacts.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_contacts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No emergency contacts saved yet.\nAdd one above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _contacts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final c = _contacts[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFF534AB7),
                                radius: 18,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      c['phone'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _removeContact(index),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFE24B4A),
                                ),
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
