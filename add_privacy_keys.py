#!/usr/bin/env python3
"""Add Speech/Microphone privacy keys to Swedishly.xcodeproj so My list dictation doesn't crash."""
import os

# From workspace root Swedishly/Swedishly, project is at ../Swedishly.xcodeproj
script_dir = os.path.dirname(os.path.abspath(__file__))
workspace_root = os.path.dirname(script_dir)  # Swedishly (inner app folder's parent)
pbx_path = os.path.join(workspace_root, "Swedishly.xcodeproj", "project.pbxproj")

if not os.path.isfile(pbx_path):
    print("Not found:", pbx_path)
    exit(1)

needle = 'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";'
insert = '''				INFOPLIST_KEY_NSMicrophoneUsageDescription = "Swedishly uses the microphone to record your voice for dictation in My list.";
				INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "Swedishly uses speech recognition so you can dictate Swedish and English sentences in My list.";'''

with open(pbx_path, "r") as f:
    content = f.read()

if "INFOPLIST_KEY_NSSpeechRecognitionUsageDescription" in content:
    print("Privacy keys already present.")
    exit(0)

# Insert after each occurrence of the orientations line (Debug and Release blocks)
count = content.count(needle)
if count == 0:
    print("Target line not found in pbxproj.")
    exit(1)
content = content.replace(
    needle,
    needle + "\n" + insert,
    count,
)
with open(pbx_path, "w") as f:
    f.write(content)
print("Added privacy keys to project. Clean build and run.")
