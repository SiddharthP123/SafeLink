import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

export default function AlertBanner({ type, lat, lng, onDismiss }) {
  const isSOS = type === 'SOS';
  return (
    <View style={[styles.banner, isSOS ? styles.sos : styles.comfort]}>
      <Text style={styles.title}>{isSOS ? 'SOS ALERT' : 'COMFORT ALERT'}</Text>
      <Text style={styles.location}>
        {lat.toFixed(5)}, {lng.toFixed(5)}
      </Text>
      <TouchableOpacity onPress={onDismiss} style={styles.dismiss}>
        <Text style={styles.dismissText}>Dismiss</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    margin: 12,
    padding: 16,
    borderRadius: 12,
  },
  sos: { backgroundColor: '#E24B4A' },
  comfort: { backgroundColor: '#BA7517' },
  title: { color: '#fff', fontSize: 18, fontWeight: '500' },
  location: { color: '#fff', marginTop: 4, fontSize: 13 },
  dismiss: {
    marginTop: 10,
    backgroundColor: 'rgba(255,255,255,0.25)',
    padding: 8,
    borderRadius: 8,
    alignItems: 'center',
  },
  dismissText: { color: '#fff', fontWeight: '500' },
});
