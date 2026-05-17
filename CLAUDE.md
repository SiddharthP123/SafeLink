# SafeLink — Claude Code Agent Briefing

## What this project is

SafeLink is a React Native (Expo) app built by a team of 5 Imperial College London Design Engineering students. It is the software half of a safety wristband product. Two users each wear a wristband (ESP32-C3 based) paired to their phone. When one user presses their wristband button, the other user's wristband vibrates and their phone shows an alert with a map location.

There are two alert levels:
- **COMFORT** — short press on wristband. Gentle vibration to paired user's band + alert on their phone.
- **SOS** — long press on wristband. Urgent vibration pattern + alert + SMS sent to emergency contacts with GPS location.

---

## Current state

All 6 phases of the app have been built up to this point. The folder structure, Firebase integration, BLE service, home screen, map screen, contacts screen, and settings screen are all in place.

**The ESP32-C3 hardware has not arrived yet.** The immediate task is to mock-test the full app flow without real hardware, using a mock BLE service and a debug/simulator screen.

---

## Project stack

| Layer | Technology |
|---|---|
| Framework | React Native via Expo (managed workflow) |
| Language | JavaScript |
| BLE | `react-native-ble-plx` |
| Realtime backend | Firebase Firestore |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Maps | `react-native-maps` + `expo-location` |
| SOS SMS | `expo-sms` |
| Contacts storage | `expo-secure-store` |
| Navigation | `expo-router` |

---

## Folder structure

```
SafeLink/
├── app/
│   ├── index.js          ← home / pairing screen (main screen)
│   ├── map.js            ← live location map screen
│   ├── contacts.js       ← emergency contacts screen
│   ├── settings.js       ← settings screen
│   └── debug.js          ← hardware simulator screen (to be built)
├── services/
│   ├── ble.js            ← real BLE logic (do not modify)
│   ├── ble.mock.js       ← mock BLE for testing without hardware (to be built)
│   ├── firebase.js       ← Firestore read/write helpers
│   └── location.js       ← GPS helpers
├── components/
│   ├── AlertBanner.js    ← banner shown when alert received
│   └── StatusDot.js      ← BLE connection indicator dot
└── assets/
```

---

## Firebase data structure

Firestore database has one active document used for alert relay:

```
Collection: alerts
  Document: active
    Fields:
      type: "COMFORT" | "SOS"
      lat: number
      lng: number
      timestamp: number (Date.now())
      seen: boolean
```

`sendAlert(type, lat, lng)` writes to this document.
`listenForAlerts(callback)` subscribes to real-time updates on this document.

---

## BLE UUIDs (must match ESP32 firmware exactly)

```
SERVICE_UUID:     12345678-1234-1234-1234-123456789012
BUTTON_CHAR_UUID: 87654321-4321-4321-4321-210987654321  ← ESP32 notifies (sends button events)
MOTOR_CHAR_UUID:  AAAABBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF  ← app writes (triggers vibration)
```

Button characteristic sends UTF-8 string: `"COMFORT"` or `"SOS"`.
Motor characteristic receives UTF-8 string: `"VIBRATE"` or `"SOS_VIBRATE"`.

---

## What to build now — mock testing task

The hardware has not arrived. Build the following two things so the full app flow can be tested end-to-end without an ESP32.

### Task 1 — create `services/ble.mock.js`

A drop-in replacement for `services/ble.js` that simulates the ESP32 without real hardware. It should:

- Log `[MOCK BLE] Scanning...` then after 2 seconds log `[MOCK BLE] Connected to SafeLink-A`
- After 5 seconds automatically fire `onButtonPress('COMFORT')`
- After 12 seconds automatically fire `onButtonPress('SOS')`
- `vibrateBand(type)` should just log `[MOCK BLE] Vibrating — {type}` with no real action

### Task 2 — create `app/debug.js`

A debug/simulator screen with manual trigger buttons. It should:

- Have a button labelled **"Simulate short press (COMFORT)"** — calls `sendAlert('COMFORT', lat, lng)` using real current GPS
- Have a button labelled **"Simulate long press (SOS)"** — calls `sendAlert('SOS', lat, lng)` using real current GPS
- Show a log feed on screen of recent actions with timestamps so the team can see what fired and when
- Be styled consistently with the rest of the app (purple `#534AB7` for COMFORT, red `#E24B4A` for SOS)
- Be reachable from the main navigation — add it as a tab or accessible from settings

### Task 3 — wire up the mock in `app/index.js`

In `app/index.js`, swap the BLE import to use the mock:

```javascript
// Use this line while testing without hardware:
import { connectToBand, vibrateBand } from '../services/ble.mock';
// Swap back to '../services/ble' when ESP32 arrives
```

### Task 4 — verify the full test chain works

Run `npx expo start` and confirm this sequence works on two phones simultaneously:

1. Phone A opens the app — mock BLE logs "Connected"
2. After 5 seconds, COMFORT alert fires automatically — Firestore document updates
3. Phone B (also running the app) receives the alert — banner appears
4. Phone B's `vibrateBand('COMFORT')` logs to console (no hardware yet)
5. Phone B's map screen shows a pin at Phone A's location
6. Repeat manually using the debug screen buttons for both COMFORT and SOS
7. For SOS, confirm SMS would be triggered (expo-sms opens the native SMS compose sheet on device)

---

## Testing without two phones

If only one phone is available, open the Firebase console (console.firebase.google.com → Firestore → alerts → active) in a browser. Manually edit the document fields to simulate an incoming alert. The app should react in real time.

Alternatively trigger from CLI:

```bash
firebase firestore:set alerts/active \
  --project YOUR_PROJECT_ID \
  '{"type":"COMFORT","lat":51.4988,"lng":-0.1749,"timestamp":1234567890,"seen":false}'
```

---

## Design system

Keep all new UI consistent with these values:

| Token | Value |
|---|---|
| Primary colour | `#534AB7` (purple) |
| SOS colour | `#E24B4A` (red) |
| COMFORT colour | `#BA7517` (amber) |
| Success | `#1D9E75` (teal) |
| Background | system default (white / dark auto) |
| Border radius | 12px for cards, 8px for buttons |
| Font weight | 400 regular, 500 medium only |

---

## What NOT to change

- `services/ble.js` — leave the real BLE service untouched, it will be used when hardware arrives
- `services/firebase.js` — Firestore helpers are working, do not restructure
- Firebase config values — do not replace or clear these
- UUID strings — these must stay identical to the ESP32 firmware

---

## When the ESP32 arrives

The only change needed to switch from mock to real hardware:

1. In `app/index.js` change the import from `ble.mock` back to `ble`
2. Flash the ESP32 firmware with matching UUIDs
3. Use the nRF Connect app (Android) to verify the band is advertising before testing in-app
4. Run integration test gates in order: BLE connect → button event → Firebase update → second phone alert → band vibration command

---

## Commands to know

```bash
npx expo start          # start dev server, scan QR in Expo Go
npx expo start --clear  # clear cache if something looks broken
firebase firestore:set  # inject test data from CLI
```

---

## Team context

- 5 students, Design Engineering Year 1, Imperial College London
- 2 week build timeline, ~£50 budget
- This is a working prototype for a demo, not a production app
- Prioritise the demo chain working reliably over code elegance
- The debug screen is not a throwaway — keep it in the build for the demo day so the team can trigger alerts manually if hardware misbehaves
