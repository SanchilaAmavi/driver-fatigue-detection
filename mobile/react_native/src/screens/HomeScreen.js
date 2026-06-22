import React, {useEffect, useState} from 'react';
import {Button, SafeAreaView, StyleSheet, Text, View} from 'react-native';
import ApiService from '../services/apiService';

const HomeScreen = () => {
  const [statusMessage, setStatusMessage] = useState('Ready to connect to backend.');

  useEffect(() => {
    checkBackend();
  }, []);

  const checkBackend = async () => {
    const status = await ApiService.healthCheck();
    setStatusMessage(status ? 'Backend reachable.' : 'Backend unreachable.');
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.card}>
        <Text style={styles.title}>Driver Fatigue Detection</Text>
        <Text style={styles.message}>{statusMessage}</Text>
        <Button title="Retry Backend Check" onPress={checkBackend} />
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  card: {
    margin: 24,
    padding: 24,
    backgroundColor: '#ffffff',
    borderRadius: 12,
    shadowColor: '#000',
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 2,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    marginBottom: 12,
  },
  message: {
    fontSize: 16,
    marginBottom: 18,
  },
});

export default HomeScreen;
