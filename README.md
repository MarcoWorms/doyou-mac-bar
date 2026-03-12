# DO!!YOU!!! Radio Menu Bar App

Tiny macOS menu bar app for the live DO!!YOU!!! radio stream.

<img width="362" height="329" alt="Screenshot 2026-03-12 at 14 19 38" src="https://github.com/user-attachments/assets/2b2fc55f-91af-4075-9d68-4217bbe4229f" />

It uses the stream exposed by the public player page at `https://doyou.world/pages/player` and packages a ready-to-run app in `dist/`.

## Just want to use it?

You do not need Xcode or any dev setup for that.

1. Download this repo, or grab `DOYOU Radio.zip` from `dist/`.
2. Open `DOYOU Radio.zip` and drag `DOYOU Radio.app` somewhere sensible like `Applications`.
3. Open `DOYOU Radio.app`.
4. A small icon appears in your Mac menu bar.
5. Left click the icon to start or stop the radio.
6. Right click the icon for options.

If macOS blocks the app the first time:

1. Control-click the app and choose `Open`, or
2. Go to `System Settings > Privacy & Security` and allow it there.

## What it does

- Left click the menu bar icon to start or stop the stream immediately
- Right click the icon to open the options menu
- Open the original player page from the menu if you want the full web player
- Quit without leaving a Dock icon behind

## For developers

If you want to rebuild the app or inspect the source, start here.

## Project Layout

- `Sources/DOYOUMenuBarRadio/main.swift`: native AppKit app and AVPlayer wiring
- `Resources/Info.plist`: bundle metadata for the menu bar app
- `scripts/build_app.sh`: rebuilds the signed `.app` bundle with `swiftc`
- `dist/DOYOU Radio.app`: built app bundle
- `dist/DOYOU Radio.zip`: zipped distributable copy of the app

## Requirements

- macOS 13 or newer
- Xcode Command Line Tools

## Build

```sh
./scripts/build_app.sh
```

That produces:

- `dist/DOYOU Radio.app`
- an ad-hoc signed bundle that launches as a menu bar app

## Run

```sh
open "dist/DOYOU Radio.app"
```

## Notes

- The live stream URL currently used by the app is `https://doyouworld.out.airtime.pro/doyouworld_a`
- The built app in `dist/` is committed so the repo can be cloned and run immediately
