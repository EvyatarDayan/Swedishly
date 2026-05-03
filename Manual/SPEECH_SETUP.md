# My list dictation (speech recognition)

For the mic button to work, the app must declare two usage descriptions. Without them, tapping the mic would crash; the app now shows an alert and asks you to add the keys. After adding them, clean build and run.

**In Xcode:** Select the **Swedishly** target → **Info** tab → under **Custom iOS Target Properties** click **+** and add:

1. **Privacy - Speech Recognition Usage Description**  
   Value: `Swedishly uses speech recognition so you can dictate Swedish and English sentences in My list.`

2. **Privacy - Microphone Usage Description**  
   Value: `Swedishly uses the microphone to record your voice for dictation in My list.`

Then **Product → Clean Build Folder** and run. Tapping the mic will show the system permission dialog and dictation will work.
