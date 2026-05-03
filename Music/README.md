# Splash audio

Add **`logo3.mp3`** here (and keep **target membership** checked for the Swedishly app).

`LogoView` loads it with:

`Bundle.main.path(forResource: "logo3", ofType: "mp3")`

If the file is only inside this `Music/` folder and is **not** found at runtime, add a second copy at **`Swedishly/logo3.mp3`** in the project, or adjust the bundle lookup in `LogoView.swift` to use `subdirectory: "Music"`.
