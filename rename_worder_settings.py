#!/usr/bin/env python3
"""Rename Worder/SettingsView.swift to Worder/WorderSettingsView.swift to fix build conflict."""
import os
import shutil

base = os.path.dirname(os.path.abspath(__file__))
src = os.path.join(base, "Worder", "SettingsView.swift")
dst = os.path.join(base, "Worder", "WorderSettingsView.swift")
if os.path.exists(src):
    shutil.copy2(src, dst)
    os.remove(src)
    print("Done: renamed Worder/SettingsView.swift -> Worder/WorderSettingsView.swift")
else:
    print("Source not found:", src)
