#!/bin/sh
# Run this once to fix "Multiple commands produce SettingsView.stringsdata"
# Then delete this script.
cd "$(dirname "$0")"
mv -f SettingsView.swift AdjectivesSettingsView.swift 2>/dev/null && echo "Done: renamed SettingsView.swift to AdjectivesSettingsView.swift" || echo "File already renamed or not found."
