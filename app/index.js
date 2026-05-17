import { useEffect, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import * as Location from 'expo-location';
import * as SMS from 'expo-sms';

// Swap back to '../services/ble' when ESP32 arrives
import { connectToBand, vibrateBand } from '../services/ble.mock';
import { sendAlert, listenForAlerts } from '../services/firebase';
import { getEmergencyContacts } from '../services/contacts';
import AlertBanner from '../components/AlertBanner';
import StatusDot from '../components/StatusDot';

export default function HomeScreen() {
  const [connected, setConnected] = useState(false);
  const [incomingAlert, setIncomingAlert] = useState(null);

  useEffect(() => {
    connectToBand(
      async (type) => {
        const location = await Location.getCurrentPositionAsync({});
        const { latitude, longitude } = location.coords;

        await sendAlert(type, latitude, longitude);

        if (type === 'SOS') {
          const contacts = await getEmergencyContacts();
          const numbers = contacts.map((c) => c.phone);
          if (numbers.length > 0) {
            await SMS.sendSMSAsync(
              numbers,
              `SOS from SafeLink. Location: https://maps.google.com/?q=${latitude},${longitude}`
            );
          }
        }
      },
      () => setConnected(true)
    );

    const unsub = listenForAlerts(async (alert) => {
      if (!alert.seen) {
        setIncomingAlert(alert);
        vibrateBand(alert.type);
      }
    });

    return () => unsub();
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>SafeLink</Text>
      <StatusDot connected={connected} />
      {incomingAlert && (
        <AlertBanner
          type={incomingAlert.type}
          lat={incomingAlert.lat}
          lng={incomingAlert.lng}
          onDismiss={() => setIncomingAlert(null)}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16,
    padding: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: '500',
    color: '#534AB7',
    marginBottom: 8,
  },
});
