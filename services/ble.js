import { BleManager } from 'react-native-ble-plx';
import { Buffer } from 'buffer';

const manager = new BleManager();

// These must match exactly what you put in your ESP32 firmware
const SERVICE_UUID = '12345678-1234-1234-1234-123456789012';
const BUTTON_CHAR_UUID = '87654321-4321-4321-4321-210987654321'; // ESP32 notifies this
const MOTOR_CHAR_UUID = 'AAAABBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF'; // app writes this

let connectedDevice = null;

// Scan and connect to the band
export function connectToBand(onButtonPress) {
  manager.startDeviceScan(null, null, async (error, device) => {
    if (error) {
      console.error(error);
      return;
    }

    if (device.name === 'SafeLink-A' || device.name === 'SafeLink-B') {
      manager.stopDeviceScan();
      const connected = await device.connect();
      await connected.discoverAllServicesAndCharacteristics();
      connectedDevice = connected;

      // Listen for button press notifications from the band
      connected.monitorCharacteristicForService(
        SERVICE_UUID,
        BUTTON_CHAR_UUID,
        (err, char) => {
          if (err) return;
          const value = Buffer.from(char.value, 'base64').toString('utf-8');
          onButtonPress(value); // fires "COMFORT" or "SOS"
        }
      );
    }
  });
}

// Tell the band to vibrate
export async function vibrateband(type) {
  if (!connectedDevice) return;
  const command = type === 'SOS' ? 'SOS_VIBRATE' : 'VIBRATE';
  const encoded = Buffer.from(command).toString('base64');
  await connectedDevice.writeCharacteristicWithResponseForService(
    SERVICE_UUID,
    MOTOR_CHAR_UUID,
    encoded
  );
}