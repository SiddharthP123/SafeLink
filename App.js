import { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, SafeAreaView, Platform } from 'react-native';

import HomeScreen from './app/index';
import MapScreen from './app/map';
import ContactsScreen from './app/contacts';
import SettingsScreen from './app/settings';
import DebugScreen from './app/debug';

const TABS = [
  { name: 'Home',     icon: '🏠', component: HomeScreen },
  { name: 'Map',      icon: '🗺',  component: MapScreen },
  { name: 'Contacts', icon: '👤', component: ContactsScreen },
  { name: 'Settings', icon: '⚙️', component: SettingsScreen },
  { name: 'Debug',    icon: '🔧', component: DebugScreen },
];

export default function App() {
  const [active, setActive] = useState(0);
  const Screen = TABS[active].component;

  return (
    <SafeAreaView style={styles.root}>
      <View style={styles.screen}>
        <Screen />
      </View>
      <View style={styles.tabBar}>
        {TABS.map((tab, i) => (
          <TouchableOpacity key={tab.name} style={styles.tab} onPress={() => setActive(i)}>
            <Text style={styles.icon}>{tab.icon}</Text>
            <Text style={[styles.label, i === active && styles.labelActive]}>
              {tab.name}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#fff' },
  screen: { flex: 1 },
  tabBar: {
    flexDirection: 'row',
    borderTopWidth: 1,
    borderTopColor: '#e5e5e5',
    backgroundColor: '#fff',
    paddingBottom: Platform.OS === 'ios' ? 8 : 4,
  },
  tab: { flex: 1, alignItems: 'center', paddingVertical: 8 },
  icon: { fontSize: 20 },
  label: { fontSize: 10, color: '#999', marginTop: 2 },
  labelActive: { color: '#534AB7', fontWeight: '500' },
});
