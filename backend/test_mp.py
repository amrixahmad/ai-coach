import mediapipe as mp
try:
    import mediapipe.python.solutions.pose as mp_pose
    print("Success: import mediapipe.python.solutions.pose")
    pose = mp_pose.Pose()
    print("Pose created successfully")
except Exception as e:
    print(f"Failed explicit import: {e}")

try:
    from mediapipe import solutions
    print("Success: from mediapipe import solutions")
except Exception as e:
    print(f"Failed from import: {e}")
