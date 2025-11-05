# UniMedia Notes — iOSApp5 (Assignment 8)

A SwiftUI app for students: capture notes with **photos or videos**, tag them with **location**, save locally via **SwiftData**, **preview/play** media, and **share**.

## Features (new since Assignment 7)
- **SwiftData** local persistence with @Model entities
- **PhotosPicker** for images **and** videos
- **Local media storage** in Documents/Media (keeps DB lean)
- **Video playback** with AVKit `VideoPlayer`
- **Thumbnails** for images & generated previews for videos
- **MapKit + Location** tagging
- **Haptics** on save, basic Accessibility labels
- **ShareLink** to share note summaries

## Tech
Swift 5.x, iOS 17+, SwiftUI, SwiftData, PhotosUI, AVKit, MapKit, CoreLocation, CoreHaptics

## Structure
- `Models/` — `Note`, `MediaAttachment`
- `Services/` — `MediaStore` (disk I/O, thumbs), `LocationManager`
- `Views/` — `ContentView`, `AddEditNoteView`, `NoteDetailView`

## Permissions
- Photo Library
- Location When In Use

## Run
Open in Xcode 15+, build on iOS 17+ simulator or device.
