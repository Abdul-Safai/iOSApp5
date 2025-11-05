# iOSApp5 — Field Notes (Assignment 8)

This project demonstrates **new iOS features** explored after Assignment 7:
- **SwiftData** for local persistence of notes (no external DB)
- **MapKit** with user location preview
- **PhotosPicker** to attach a photo to each note
- **ShareLink** to share note content
- **Haptics** and basic **Accessibility** labels
- (Optional) **SKStoreReviewController** prompt after saving

## Tech
- Swift 5.x, SwiftUI, SwiftData, MapKit, PhotosUI, CoreLocation

## Structure
- `Note.swift` — `@Model` persisted entity
- `ContentView.swift` — list, navigation
- `AddEditNoteView.swift` — create note, pick photo, capture location
- `NoteDetailView.swift` — read/delete, map, share
- `LocationManager.swift` — simple location wrapper

## Permissions
- Location When In Use
- Photo Library

## How to Run
- Open `iOSApp5.xcodeproj` (or workspace), build & run on iOS 17+ simulator/device.
