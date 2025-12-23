import { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ActivityIndicator, Alert } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { ResizeMode, Video } from 'expo-av';
import * as ImagePicker from 'expo-image-picker';
// @ts-ignore - The legacy export exists but might not be picked up by strict type checking in all environments
import { uploadAsync, FileSystemUploadType } from 'expo-file-system/legacy';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';

// CHANGE THIS TO YOUR COMPUTER'S LOCAL IP ADDRESS if testing on real device
// For Android Emulator, use 'http://10.0.2.2:8000'
// For iOS Simulator, use 'http://localhost:8000'
const BACKEND_URL = 'http://10.0.2.2:8000/process-video'; 

export default function Home() {
  const [videoUri, setVideoUri] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const router = useRouter();

  const pickVideo = async () => {
    // No permissions request is necessary for launching the image library
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Videos,
      allowsEditing: true,
      quality: 1,
    });

    if (!result.canceled) {
      setVideoUri(result.assets[0].uri);
    }
  };

  const uploadAndAnalyze = async () => {
    if (!videoUri) return;
    
    setIsUploading(true);
    
    try {
      console.log("Uploading to:", BACKEND_URL);
      const response = await uploadAsync(BACKEND_URL, videoUri, {
        fieldName: 'file',
        httpMethod: 'POST',
        uploadType: FileSystemUploadType.MULTIPART,
      });

      console.log("Response status:", response.status);
      
      if (response.status === 200) {
        const data = JSON.parse(response.body);
        // Navigate to results page with data
        router.push({
          pathname: '/results',
          params: { 
            analysis: JSON.stringify(data.analysis),
            tracking: JSON.stringify(data.tracking),
            metadata: JSON.stringify(data.metadata),
            videoUri: videoUri 
          }
        });
      } else {
        Alert.alert("Upload Failed", "Server returned status " + response.status);
        console.error("Upload failed:", response.body);
      }
    } catch (error) {
      console.error("Error uploading video:", error);
      Alert.alert("Error", "Failed to connect to backend. Make sure it is running.");
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <Stack.Screen options={{ title: 'AI Coach', headerShown: false }} />
      
      <View style={styles.header}>
        <Text style={styles.headerTitle}>AI Basketball Coach</Text>
        <Text style={styles.headerSubtitle}>Upload a shot to get pro feedback</Text>
      </View>

      <View style={styles.content}>
        {videoUri ? (
          <View style={styles.videoContainer}>
            <Video
              style={styles.video}
              source={{ uri: videoUri }}
              useNativeControls
              resizeMode={ResizeMode.CONTAIN}
              isLooping
            />
            <TouchableOpacity 
              style={styles.changeButton} 
              onPress={() => setVideoUri(null)}
            >
              <Ionicons name="close-circle" size={24} color="white" />
            </TouchableOpacity>
          </View>
        ) : (
          <TouchableOpacity style={styles.uploadPlaceholder} onPress={pickVideo}>
            <Ionicons name="cloud-upload-outline" size={64} color="#6366f1" />
            <Text style={styles.uploadText}>Select Video from Gallery</Text>
          </TouchableOpacity>
        )}

        {videoUri && (
          <TouchableOpacity 
            style={[styles.analyzeButton, isUploading && styles.disabledButton]} 
            onPress={uploadAndAnalyze}
            disabled={isUploading}
          >
            {isUploading ? (
              <ActivityIndicator color="white" />
            ) : (
              <>
                <Ionicons name="analytics" size={24} color="white" style={{marginRight: 8}} />
                <Text style={styles.buttonText}>Analyze Form</Text>
              </>
            )}
          </TouchableOpacity>
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  header: {
    padding: 24,
    paddingTop: 40,
  },
  headerTitle: {
    fontSize: 32,
    fontWeight: '800',
    color: '#0f172a',
  },
  headerSubtitle: {
    fontSize: 16,
    color: '#64748b',
    marginTop: 4,
  },
  content: {
    flex: 1,
    padding: 24,
    justifyContent: 'center',
    alignItems: 'center',
  },
  uploadPlaceholder: {
    width: '100%',
    height: 300,
    borderWidth: 2,
    borderColor: '#cbd5e1',
    borderStyle: 'dashed',
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#ffffff',
  },
  uploadText: {
    marginTop: 16,
    fontSize: 18,
    color: '#64748b',
    fontWeight: '500',
  },
  videoContainer: {
    width: '100%',
    height: 400, // Fixed height for preview
    borderRadius: 16,
    overflow: 'hidden',
    backgroundColor: 'black',
    position: 'relative',
  },
  video: {
    width: '100%',
    height: '100%',
  },
  changeButton: {
    position: 'absolute',
    top: 12,
    right: 12,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderRadius: 20,
    padding: 4,
  },
  analyzeButton: {
    marginTop: 32,
    width: '100%',
    backgroundColor: '#4f46e5',
    paddingVertical: 16,
    borderRadius: 12,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#4f46e5',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 4,
  },
  disabledButton: {
    opacity: 0.7,
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: '700',
  },
});
