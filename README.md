# Tomater 🍅

A small, 8-bit arcade-style Pomodoro timer for Apple Silicon Macs (macOS 14+). Native Swift/SwiftUI, no network, stats kept in a local SQLite file.

## Build

```bash
./build.sh
```

This creates `build/Tomater.app`. Copy it to `/Applications` to keep it:

```bash
cp -R build/Tomater.app /Applications/
```

To start it at login: System Settings → General → Login Items → add Tomater.

## Features

- Timer in the menu bar (🍅 49:59 / ☕️ 09:58), with Start/Pause/Stop/Open/Quit menu. Can be turned off.
- Hide or show the dock icon. (The dock icon can only be hidden while the menu bar timer is on, so the app is always reachable.)
- Focus, break, long break lengths, and how many focus timers before a long break.
- Breaks start by themselves. "Auto-start focus after break" starts the next focus timer when the break ends.
- "Jump on top when time's up": when a timer ends, the window comes to the front and floats above all windows until you click it. A short 8-bit jingle plays either way.
- Focus text: change the "FOCUS!" title in Settings. Leave it blank for "FOCUS!". Up to 16 characters: A-Z, 0-9, space and `: ! - . ' ? /`.
- Stats screen: today, this week, last week.
- Space bar starts/pauses when the window is focused.
- Theme: AUTO uses the light look from 6:00 AM to 5:59 PM and the dark look from 6:00 PM to 5:59 AM (follows the clock, not the system appearance). DAY and NIGHT keep one look.

## Data

- Completed focus timers: `~/Library/Application Support/Tomater/tomater.sqlite` (table `pomodoros`, one row per completed timer, `completed_at` in Unix seconds).
- Settings: `defaults read dev.tomater.Tomater`.
