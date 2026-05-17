import * as SecureStore from 'expo-secure-store';

const KEY = 'emergency_contacts';

export async function getEmergencyContacts() {
  const raw = await SecureStore.getItemAsync(KEY);
  return raw ? JSON.parse(raw) : [];
}

export async function saveEmergencyContacts(contacts) {
  await SecureStore.setItemAsync(KEY, JSON.stringify(contacts));
}
