import { View, Text, StyleSheet } from 'react-native';

export default function SettingsScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.heading}>Settings</Text>
      <Text style={styles.item}>App version: 0.1.0 (mock mode)</Text>
      <Text style={styles.item}>BLE: using mock service</Text>
      <Text style={styles.item}>Firebase project: connect-0-app</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, paddingTop: 48 },
  heading: { fontSize: 22, fontWeight: '500', color: '#534AB7', marginBottom: 20 },
  item: { fontSize: 14, color: '#444', paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: '#eee' },
});
