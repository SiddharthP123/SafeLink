import MapView, { Marker } from 'react-native-maps';
import { listenForAlerts } from '../services/firebase';
import { useState, useEffect } from 'react';

export default function MapScreen() {
  const [alertLocation, setAlertLocation] = useState(null);

  useEffect(() => {
    return listenForAlerts((alert) => {
      setAlertLocation({ lat: alert.lat, lng: alert.lng });
    });
  }, []);

  return (
    <MapView
      style={{ flex: 1 }}
      initialRegion={{
        latitude: 51.498,
        longitude: -0.174, // Imperial College
        latitudeDelta: 0.01,
        longitudeDelta: 0.01,
      }}
    >
      {alertLocation && (
        <Marker
          coordinate={{
            latitude: alertLocation.lat,
            longitude: alertLocation.lng,
          }}
          title="Friend's location"
          pinColor="red"
        />
      )}
    </MapView>
  );
}
