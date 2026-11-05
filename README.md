# Wiggle

A tiny macOS menu bar app that nudges the mouse 1px (and back) every 1–2 minutes
so the screen never sleeps or locks.

- **Left-click** the worm icon to turn wiggling on/off. It wiggles while on and lies flat (dimmed) while off.
- **Right-click** (or ctrl-click) for the menu: status and time to next wiggle, Settings…, Quit.
- **Settings** lets you pick the min/max time between wiggles (10 s – 10 min). Each wiggle fires at a random time in that range.

## Build

Requires macOS 13+ and the Xcode command line tools.

```sh
./scripts/build-app.sh
cp -R build/Wiggle.app /Applications/
open /Applications/Wiggle.app
```

During development you can also run `swift run`.

## Accessibility permission

Posting mouse events requires **System Settings → Privacy & Security → Accessibility**.
The app prompts on first launch. Until you grant it, the menu shows a *Grant Accessibility Permission…* item.

The build is ad-hoc signed, so macOS treats each rebuild as a new app. After rebuilding,
remove Wiggle from the Accessibility list and add it again (or toggle it off and on).

## Launch at login

Add `Wiggle.app` under **System Settings → General → Login Items**.
