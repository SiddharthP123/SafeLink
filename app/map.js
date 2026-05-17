import { View, Text, TouchableOpacity, Linking, StyleSheet } from 'react-native';
import { listenForAlerts } from '../services/firebase';
import { useState, useEffect } from 'react';

export default function MapScreen() {
  const [alert, setAlert] = useState(null);

  useEffect(() => {
    return listenForAlerts((data) => {
      if (!data.seen) setAlert(data);
    });
  }, []);

  function openInMaps() {
    if (!alert) return;
    Linking.openURL(`https://maps.google.com/?q=${alert.lat},${alert.lng}`);
  }

  if (!alert) {
    return (
      <View style={styles.empty}>
        <Text style={styles.emptyIcon}>📍</Text>
        <Text style={styles.emptyText}>No alert received yet</Text>
        <Text style={styles.emptySub}>Location will appear here when your paired user sends an alert.</Text>
      </View>
    );
  }

  const isSOS = alert.type === 'SOS';
  const time = new Date(alert.timestamp).toLocaleTimeString();

  return (
    <View style={styles.container}>
      <View style={[styles.badge, isSOS ? styles.sosBadge : styles.comfortBadge]}>
        <Text style={styles.badgeText}>{isSOS ? 'SOS' : 'COMFORT'}</Text>
      </View>

      <Text style={styles.label}>Location received</Text>
      <Text style={styles.coords}>{alert.lat.toFixed(6)}</Text>
      <Text style={styles.coords}>{alert.lng.toFixed(6)}</Text>
      <Text style={styles.time}>at {time}</Text>

      <TouchableOpacity style={styles.mapsBtn} onPress={openInMaps}>
        <Text style={styles.mapsBtnText}>Open in Google Maps</Text>
      </TouchableOpacity>

      <Text style={styles.note}>
        Full map view requires a development build.{'\n'}For now, tap above to open the location.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  empty: {
    flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32,
  },
  emptyIcon: { fontSize: 48, marginBottom: 12 },
  emptyText: { fontSize: 18, fontWeight: '500', color: '#333', marginBottom: 8 },
  emptySub: { fontSize: 14, color: '#888', textAlign: 'center' },

  container: {
    flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32,
  },
  badge: {
    paddingHorizontal: 20, paddingVertical: 8, borderRadius: 20, marginBottom: 24,
  },
  sosBadge: { backgroundColor: '#E24B4A' },
  comfortBadge: { backgroundColor: '#BA7517' },
  badgeText: { color: '#fff', fontWeight: '500', fontSize: 16 },

  label: { fontSize: 14, color: '#888', marginBottom: 8 },
  coords: { fontSize: 24, fontWeight: '500', color: '#333', letterSpacing: 1 },
  time: { fontSize: 13, color: '#aaa', marginTop: 8, marginBottom: 32 },

  mapsBtn: {
    backgroundColor: '#534AB7',
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: 8,
    marginBottom: 16,
  },
  mapsBtnText: { color: '#fff', fontWeight: '500', fontSize: 15 },

  note: { fontSize: 12, color: '#bbb', textAlign: 'center', lineHeight: 18 },
});
