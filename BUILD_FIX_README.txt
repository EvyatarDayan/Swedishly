Fix "Multiple commands produce SettingsView.stringsdata"
========================================================

You must RENAME the file so Xcode stops generating two SettingsView.stringsdata files.

Do ONE of the following:

  A) In Terminal (from this folder):
     python3 rename_worder_settings.py

  B) In Finder: open the Worder folder and rename "SettingsView.swift"
     to "WorderSettingsView.swift".

  C) In Xcode: in the Project navigator, under Worder, select
     "SettingsView.swift" → Right-click → Rename → "WorderSettingsView.swift".

Then: Product → Clean Build Folder (Shift+Cmd+K), then Build (Cmd+B).
