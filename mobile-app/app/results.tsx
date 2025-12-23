import { useLocalSearchParams, Stack, useRouter } from 'expo-router';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Video, ResizeMode } from 'expo-av';
import { Ionicons } from '@expo/vector-icons';
import { useState, useMemo } from 'react';
import Svg, { Polygon, Text as SvgText, Rect, G } from 'react-native-svg';

export default function Results() {
  const params = useLocalSearchParams();
  const router = useRouter();
  
  // Parse the analysis data passed as a string
  const analysis = params.analysis ? JSON.parse(params.analysis as string) : null;
  const tracking = params.tracking ? JSON.parse(params.tracking as string) : [];
  const metadata = params.metadata ? JSON.parse(params.metadata as string) : { width: 1920, height: 1080 };
  const videoUri = params.videoUri as string;
  
  const [activeShotIndex, setActiveShotIndex] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);
  const [containerLayout, setContainerLayout] = useState({ width: 0, height: 0 });

  const shots = analysis?.shots || [];

  // Helper to find the closest tracking frame
  const currentTracking = useMemo(() => {
    if (!tracking.length) return null;
    // Simple closest match - could be optimized with binary search or interpolation
    return tracking.reduce((prev: any, curr: any) => {
      return (Math.abs(curr.timestamp - currentTime) < Math.abs(prev.timestamp - currentTime) ? curr : prev);
    });
  }, [currentTime, tracking]);

  const renderOverlay = () => {
    if (!currentTracking || !containerLayout.width || !metadata.width) return null;

    // Calculate the actual video display area within the container (ResizeMode.CONTAIN logic)
    const videoRatio = metadata.width / metadata.height;
    const containerRatio = containerLayout.width / containerLayout.height;
    
    let displayWidth = containerLayout.width;
    let displayHeight = containerLayout.height;
    let offsetX = 0;
    let offsetY = 0;

    if (videoRatio > containerRatio) {
      // Video is wider than container (fit width, black bars on top/bottom)
      displayHeight = containerLayout.width / videoRatio;
      offsetY = (containerLayout.height - displayHeight) / 2;
    } else {
      // Video is taller than container (fit height, black bars on left/right)
      displayWidth = containerLayout.height * videoRatio;
      offsetX = (containerLayout.width - displayWidth) / 2;
    }

    // Normalized coordinates (0-1) -> Screen coordinates
    const headX = offsetX + (currentTracking.head_x * displayWidth);
    const headY = offsetY + (currentTracking.head_y * displayHeight);

    // Arrow dimensions
    const arrowWidth = 20;
    const arrowHeight = 20;
    const offsetAboveHead = 60; // How far above the head to float

    // Calculate arrow points (pointing DOWN)
    // Tip is at (headX, headY - offset)
    // Base is above that
    const tipX = headX;
    const tipY = headY - offsetAboveHead;
    
    const leftBaseX = headX - arrowWidth / 2;
    const rightBaseX = headX + arrowWidth / 2;
    const baseY = tipY - arrowHeight;

    const points = `${tipX},${tipY} ${leftBaseX},${baseY} ${rightBaseX},${baseY}`;

    return (
      <G>
        {/* Name Label */}
        <Rect
          x={headX - 40}
          y={baseY - 35}
          width="80"
          height="30"
          fill="black"
          opacity="0.7"
          rx="8"
        />
        <SvgText
          x={headX}
          y={baseY - 15}
          fill="white"
          fontSize="16"
          fontWeight="bold"
          textAnchor="middle"
        >
          PLAYER
        </SvgText>

        {/* Arrow */}
        <Polygon
          points={points}
          fill="red"
          stroke="white"
          strokeWidth="2"
        />
      </G>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <Stack.Screen options={{ title: 'Analysis Results', headerShown: false }} />
      
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#0f172a" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Shot Analysis</Text>
      </View>

      <View 
        style={styles.videoContainer}
        onLayout={(e) => setContainerLayout(e.nativeEvent.layout)}
      >
        <Video
          style={styles.video}
          source={{ uri: videoUri }}
          useNativeControls
          resizeMode={ResizeMode.CONTAIN}
          isLooping
          onPlaybackStatusUpdate={(status) => {
            if (status.isLoaded) {
              setCurrentTime(status.positionMillis / 1000);
            }
          }}
          progressUpdateIntervalMillis={50}
        />
        
        {/* Overlay Layer */}
        <View style={StyleSheet.absoluteFill} pointerEvents="none">
          <Svg height="100%" width="100%">
            {renderOverlay()}
          </Svg>
        </View>
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
