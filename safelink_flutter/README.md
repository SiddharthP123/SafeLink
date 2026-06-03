# SafeLink v1.2 — Flutter iOS App

Safety wristband companion app for Imperial College London Design Engineering (DESE40004).

## What it does
Two paired users each wear an ESP32-C3 wristband. Pressing the wristband button sends a real-time alert to the paired user's phone with live GPS location.

- **COMFORT** — short press: gentle check-in, banner notification
- **SOS** — long press: urgent alert, local notification, SMS to emergency contacts

## Quick deploy

```bash
# Phone A (default — connects to SafeLink-A band)
./deploy_phone.sh

# Phone B (select BAND B in Settings after first launch)
./deploy_phone_b.sh

# Rebuild already installed app (~5 sec, no full build)
./deploy_phone.sh --install-only
./deploy_phone_b.sh --install-only
```

## Stack
- Flutter / Dart — iOS only (iPhone 14+, iOS 26 beta)
- Firebase Auth + Firestore (real-time alerts)
- flutter_blue_plus (BLE scan + GATT)
- flutter_local_notifications (lock-screen alerts)
- flutter_map (OSM, no API key)

## Folder layout
```
lib/
  main.dart              # app entry, routing, bottom nav
  app_theme.dart         # SL color tokens
  firebase_options.dart  # Firebase config
  screens/               # one file per screen
  services/              # BLE, Firebase, auth, profile, etc.
  widgets/               # wave_background
assets/images/           # logo.png
ios/                     # Xcode project + Pods
```

## Band BLE names
| Band | Advertisement name |
|------|--------------------|
| A    | `SafeLink-A`       |
| B    | `SafeLink_B`       |

Select your band in **Settings → MY BAND** before first use.

## Acknowledgements

Built for **Imperial College London** Design Engineering (DESE40004) by a team of 5 students.

AI assistance: portions of this codebase were developed and debugged with the help of **[Claude](https://claude.ai)** (Anthropic), an AI assistant. Claude aided in Flutter/Dart implementation, BLE service architecture, Firebase integration, UI design, and debugging throughout development.
