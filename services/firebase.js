import { initializeApp } from 'firebase/app';
import { getFirestore, doc, setDoc, onSnapshot } from 'firebase/firestore';

// Pasted config idea - in HCDE document on Google Docs.
const firebaseConfig = {
  apiKey: 'AIzaSyBYG_Ct43Xokf8f14XH5mw5n_Bu9jskySg',
  authDomain: 'connect-0-app.firebaseapp.com',
  projectId: 'connect-0-app',
  storageBucket: 'connect-0-app.firebasestorage.app',
  messagingSenderId: '130637803692',
  appId: '1:130637803692:web:8ae872344885ffd9f02f09',
  measurementId: 'G-L43HB33F4S',
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);

// Person A calls this when button pressed.
export async function sendAlert(type, lat, lng) {
  await setDoc(doc(db, 'alerts', 'active'), {
    type, // "COMFORT" or "SOS"
    lat,
    lng,
    timestamp: Date.now(),
    seen: false,
  });
}

// Person B calls this to listen for incoming alerts.
export function listenForAlerts(callback) {
  return onSnapshot(doc(db, 'alerts', 'active'), (snap) => {
    if (snap.exists()) callback(snap.data());
  });
}
