import { StatusBar } from 'expo-status-bar';
import { StyleSheet, View } from 'react-native';
import InstagramWebView from './src/InstagramWebView';

export default function App() {
  return (
    <View style={styles.container}>
      <StatusBar style="dark" />
      <InstagramWebView />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
});
