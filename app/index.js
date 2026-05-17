import { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import * as Location from 'expo-location';
import * as SMS from 'expo-sms';
import { connectToBand, vibrateBand } from '../services/ble';
import { sendAlert, listenForAlerts } from '../services/firebase';
import { getEmergencyContacts } from '../services/contacts';

export default function HomeScreen() {
  const [connected, setConnected] = useState(false);
  const [incomingAlert, setIncomingAlert] = useState(null);

  useEffect(() => {
    // Connect to band and listen for button presses
    connectToBand(async (type) => {
      const location = await Location.getCurrentPositionAsync({});
      const { latitude, longitude } = location.coords;

      // Send alert to Firebase so paired phone receives it
      await sendAlert(type, latitude, longitude);

      if (type === 'SOS') {
        // Also fire SMS to emergency contacts
        const contacts = await getEmergencyContacts();
        const numbers = contacts.map((c) => c.phone);
        await SMS.sendSMSAsync(
          numbers,
          `🆘 SOS from SafeLink. Location: https://maps.google.com/?q=${latitude},${longitude}`
        );
      }
    });

    // Listen for incoming alerts from paired user
    const unsub = listenForAlerts(async (alert) => {
      setIncomingAlert(alert);
      await vibrateBand(alert.type); // vibrate THIS band
    });

    return () => unsub();
  }, []);

  return (
    <View style={styles.container}>
      <StatusDot connected={connected} />
      {incomingAlert && (
        <AlertBanner
          type={incomingAlert.type}
          lat={incomingAlert.lat}
          lng={incomingAlert.lng}
          onDismiss={() => setIncomingAlert(null)}
        />
      )}
      <Text style={styles.status}>
        {connected ? 'Band connected' : 'Searching for band...'}
      </Text>
    </View>
  );
}
