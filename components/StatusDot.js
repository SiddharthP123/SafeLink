import { View, Text, StyleSheet } from 'react-native';

export default function StatusDot({ connected }) {
  return (
    <View style={styles.row}>
      <View style={[styles.dot, connected ? styles.on : styles.off]} />
      <Text style={styles.label}>{connected ? 'Band connected' : 'Searching...'}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  dot: { width: 12, height: 12, borderRadius: 6 },
  on: { backgroundColor: '#1D9E75' },
  off: { backgroundColor: '#999' },
  label: { fontSize: 14, color: '#555' },
});
