import { useLocalSearchParams, Stack, useRouter } from 'expo-router';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Video, ResizeMode } from 'expo-av';
import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';

export default function Results() {
  const params = useLocalSearchParams();
  const router = useRouter();
  
  // Parse the analysis data passed as a string
  const analysis = params.analysis ? JSON.parse(params.analysis as string) : null;
  const videoUri = params.videoUri as string;
  
  const [activeShotIndex, setActiveShotIndex] = useState(0);

  const shots = analysis?.shots || [];

  return (
    <SafeAreaView style={styles.container}>
      <Stack.Screen options={{ title: 'Analysis Results', headerShown: false }} />
      
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#0f172a" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Shot Analysis</Text>
      </View>

      <View style={styles.videoContainer}>
        <Video
          style={styles.video}
          source={{ uri: videoUri }}
          useNativeControls
          resizeMode={ResizeMode.CONTAIN}
          isLooping
        />
        {/* TODO: Add Overlay Layer here */}
      </View>

      <ScrollView style={styles.resultsList}>
        <Text style={styles.sectionTitle}>Shot Breakdown</Text>
        
        {shots.map((shot: any, index: number) => (
          <TouchableOpacity 
            key={index} 
            style={[
              styles.shotCard, 
              activeShotIndex === index && styles.activeCard
            ]}
            onPress={() => setActiveShotIndex(index)}
          >
            <View style={styles.shotHeader}>
              <View style={[
                styles.badge, 
                { backgroundColor: shot.result === 'made' ? '#dcfce7' : '#fee2e2' }
              ]}>
                <Text style={[
                  styles.badgeText,
                  { color: shot.result === 'made' ? '#166534' : '#991b1b' }
                ]}>
                  {shot.result.toUpperCase()}
                </Text>
              </View>
              <Text style={styles.timestamp}>{shot.timestamp_of_outcome}</Text>
            </View>
            
            <Text style={styles.shotType}>{shot.shot_type}</Text>
            <Text style={styles.feedback}>{shot.feedback}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e2e8f0',
  },
  backButton: {
    marginRight: 16,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#0f172a',
  },
  videoContainer: {
    width: '100%',
    height: 300,
    backgroundColor: 'black',
  },
  video: {
    width: '100%',
    height: '100%',
  },
  resultsList: {
    flex: 1,
    padding: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#334155',
    marginBottom: 12,
  },
  shotCard: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    shadowColor: '#64748b',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  activeCard: {
    borderColor: '#6366f1',
    borderWidth: 2,
  },
  shotHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '700',
  },
  timestamp: {
    color: '#64748b',
    fontSize: 14,
  },
  shotType: {
    fontSize: 16,
    fontWeight: '600',
    color: '#0f172a',
    marginBottom: 4,
  },
  feedback: {
    fontSize: 14,
    color: '#334155',
    lineHeight: 20,
  },
});
