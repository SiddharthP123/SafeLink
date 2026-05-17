import { useState } from 'react';
import {
  View, Text, TouchableOpacity, ScrollView, StyleSheet,
} from 'react-native';
import * as Location from 'expo-location';
import { sendAlert } from '../services/firebase';

function timestamp() {
  return new Date().toLocaleTimeString();
}

export default function DebugScreen() {
  const [logs, setLogs] = useState([]);
  const [busy, setBusy] = useState(false);

  function addLog(msg) {
    setLogs((prev) => [`[${timestamp()}] ${msg}`, ...prev]);
  }

  async function trigger(type) {
    if (busy) return;
    setBusy(true);
    try {
      addLog(`Requesting location...`);
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        addLog('Location permission denied');
        return;
      }
      const pos = await Location.getCurrentPositionAsync({});
      const { latitude, longitude } = pos.coords;
      addLog(`Got location: ${latitude.toFixed(5)}, ${longitude.toFixed(5)}`);
      await sendAlert(type, latitude, longitude);
      addLog(`Sent ${type} alert to Firebase`);
    } catch (e) {
      addLog(`Error: ${e.message}`);
    } finally {
      setBusy(false);
    }
  }

  return (
    <View style={styles.container}>
      <Text style={styles.heading}>Debug / Simulator</Text>
      <Text style={styles.sub}>Manually trigger alerts using real GPS. Use this on demo day if hardware misbehaves.</Text>

      <TouchableOpacity
        style={[styles.btn, styles.comfort, busy && styles.disabled]}
        onPress={() => trigger('COMFORT')}
        disabled={busy}
      >
        <Text style={styles.btnText}>Simulate short press (COMFORT)</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.btn, styles.sos, busy && styles.disabled]}
        onPress={() => trigger('SOS')}
        disabled={busy}
      >
        <Text style={styles.btnText}>Simulate long press (SOS)</Text>
      </TouchableOpacity>

      <Text style={styles.logHeader}>Activity log</Text>
      <ScrollView style={styles.logBox}>
        {logs.length === 0 && (
          <Text style={styles.logEmpty}>No actions yet — press a button above.</Text>
        )}
        {logs.map((line, i) => (
          <Text key={i} style={styles.logLine}>{line}</Text>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, paddingTop: 48 },
  heading: { fontSize: 22, fontWeight: '500', color: '#534AB7', marginBottom: 6 },
  sub: { fontSize: 13, color: '#666', marginBottom: 24 },
  btn: {
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 12,
  },
  comfort: { backgroundColor: '#BA7517' },
  sos: { backgroundColor: '#E24B4A' },
  disabled: { opacity: 0.5 },
  btnText: { color: '#fff', fontSize: 16, fontWeight: '500' },
  logHeader: { fontSize: 14, fontWeight: '500', color: '#444', marginBottom: 8 },
  logBox: {
    flex: 1,
    backgroundColor: '#f4f4f4',
    borderRadius: 8,
    padding: 12,
  },
  logEmpty: { color: '#aaa', fontSize: 13 },
  logLine: { fontSize: 12, color: '#333', marginBottom: 4, fontFamily: 'monospace' },
});
