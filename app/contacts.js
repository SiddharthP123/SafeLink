import { useState, useEffect } from 'react';
import {
  View, Text, TextInput, TouchableOpacity,
  FlatList, StyleSheet, Alert,
} from 'react-native';
import { getEmergencyContacts, saveEmergencyContacts } from '../services/contacts';

export default function ContactsScreen() {
  const [contacts, setContacts] = useState([]);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');

  useEffect(() => {
    getEmergencyContacts().then(setContacts);
  }, []);

  async function addContact() {
    if (!name.trim() || !phone.trim()) return;
    const updated = [...contacts, { id: Date.now().toString(), name: name.trim(), phone: phone.trim() }];
    setContacts(updated);
    await saveEmergencyContacts(updated);
    setName('');
    setPhone('');
  }

  async function removeContact(id) {
    const updated = contacts.filter((c) => c.id !== id);
    setContacts(updated);
    await saveEmergencyContacts(updated);
  }

  return (
    <View style={styles.container}>
      <Text style={styles.heading}>Emergency Contacts</Text>
      <Text style={styles.sub}>These people receive an SMS on SOS alert.</Text>

      <View style={styles.form}>
        <TextInput
          style={styles.input}
          placeholder="Name"
          value={name}
          onChangeText={setName}
        />
        <TextInput
          style={styles.input}
          placeholder="Phone number"
          keyboardType="phone-pad"
          value={phone}
          onChangeText={setPhone}
        />
        <TouchableOpacity style={styles.addBtn} onPress={addContact}>
          <Text style={styles.addBtnText}>Add Contact</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={contacts}
        keyExtractor={(item) => item.id}
        style={styles.list}
        ListEmptyComponent={<Text style={styles.empty}>No contacts added yet.</Text>}
        renderItem={({ item }) => (
          <View style={styles.row}>
            <View>
              <Text style={styles.contactName}>{item.name}</Text>
              <Text style={styles.contactPhone}>{item.phone}</Text>
            </View>
            <TouchableOpacity onPress={() => removeContact(item.id)}>
              <Text style={styles.remove}>Remove</Text>
            </TouchableOpacity>
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, paddingTop: 48 },
  heading: { fontSize: 22, fontWeight: '500', color: '#534AB7' },
  sub: { fontSize: 13, color: '#666', marginTop: 4, marginBottom: 20 },
  form: { gap: 10, marginBottom: 24 },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 15,
  },
  addBtn: {
    backgroundColor: '#534AB7',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  addBtnText: { color: '#fff', fontWeight: '500', fontSize: 15 },
  list: { flex: 1 },
  empty: { color: '#999', textAlign: 'center', marginTop: 20 },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  contactName: { fontSize: 15, fontWeight: '500' },
  contactPhone: { fontSize: 13, color: '#666', marginTop: 2 },
  remove: { color: '#E24B4A', fontSize: 14 },
});
