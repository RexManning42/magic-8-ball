# Magic 8 Ball

A Magic 8 Ball for iPhone, built with SwiftUI. Ask a yes-or-no question, then shake your phone or wiggle the ball. The die floats up through the purple liquid with one of the 20 classic answers.

## Features

- Shake the phone, wiggle the ball with your finger, or tap it
- 8-sided die that sinks, tumbles and rises through the liquid
- Liquid slosh while shaking and a distant gong when the answer appears
- Haptic feedback
- Sounds respect the silent switch
- Supports VoiceOver and Reduce Motion

## Requirements

- Xcode 16 or later
- iOS 17 or later

## Building

Open `EightBall.xcodeproj` in Xcode, pick a simulator or your iPhone, and run. To run on a device, select your team under the EightBall target's Signing & Capabilities tab.

In the simulator, trigger a shake with Device ▸ Shake (⌃⌘Z).

## Sounds

Both sound files in `EightBall/Sounds` are produced by a script:

```bash
swift tools/make_sounds.swift tools/source/water-sloshing.mp3 EightBall/Sounds
```

- **Slosh** is cut from [Water Sloshing](https://freesound.org/people/vmgraw/sounds/235625/) by vmgraw on Freesound, released under [Creative Commons 0](https://creativecommons.org/publicdomain/zero/1.0/).
- **Gong** is synthesized by the script.

## License

The code is released under the [MIT License](LICENSE).
