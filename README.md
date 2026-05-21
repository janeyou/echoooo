# Echoooo

A quiet way to capture conversations. Tap the mic, the screen goes dark, tap again, a transcript appears.

iOS 17+, SwiftUI. Records to local `.m4a`, uploads to your Dropbox app folder, transcribes via Riviera, shows readable text.

## Stack

- SwiftUI, SwiftData
- AVFoundation for recording
- SwiftyDropbox for OAuth and upload
- Riviera transcription via Dropbox

## Run it

Requires Xcode 16 and [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
# 1. copy the secrets example and add your Dropbox app key
cp Echoooo/Resources/Secrets.xcconfig.example Echoooo/Resources/Secrets.xcconfig
# edit the DROPBOX_APP_KEY value, get it from https://www.dropbox.com/developers/apps

# 2. generate the Xcode project
xcodegen generate

# 3. open and run
open Echoooo.xcodeproj
```

Dropbox app needs the redirect URI `db-<YOUR_APP_KEY>://2/token` registered, scopes `files.content.read` and `files.content.write`.

## Project layout

```
Echoooo/
  EchooooApp.swift          app entry, SDK setup, redirect handler
  Models/                   SwiftData record, API DTOs
  Services/                 recorder, dropbox, riviera, pipeline
  Views/                    home, listening, processing, transcript, history, settings
  Resources/                Info.plist, assets, theme, xcconfig
```

## License

No license yet. All rights reserved until decided.
