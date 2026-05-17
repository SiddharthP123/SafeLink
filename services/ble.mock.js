let _onButtonPress = null;

export function connectToBand(onButtonPress, onConnect) {
  _onButtonPress = onButtonPress;

  console.log('[MOCK BLE] Scanning...');

  setTimeout(() => {
    console.log('[MOCK BLE] Connected to SafeLink-A');
    if (onConnect) onConnect();
  }, 2000);

  setTimeout(() => {
    console.log('[MOCK BLE] Auto-firing COMFORT button press');
    if (_onButtonPress) _onButtonPress('COMFORT');
  }, 5000);

  setTimeout(() => {
    console.log('[MOCK BLE] Auto-firing SOS button press');
    if (_onButtonPress) _onButtonPress('SOS');
  }, 12000);
}

export function vibrateBand(type) {
  console.log(`[MOCK BLE] Vibrating — ${type}`);
}
