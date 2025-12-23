import mediapipe
import os

print(f"MediaPipe path: {mediapipe.__path__}")
try:
    from mediapipe import solutions
    print("Success: from mediapipe import solutions")
except ImportError as e:
    print(f"Error importing solutions directly: {e}")

try:
    import mediapipe.python.solutions
    print("Success: import mediapipe.python.solutions")
except ImportError as e:
    print(f"Error importing mediapipe.python.solutions: {e}")

print("Directory of mediapipe:")
print(dir(mediapipe))
