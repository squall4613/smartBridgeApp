# SmartBridge App

SmartBridge overview: https://smart-bridge-overview-mab7.vercel.app/?fbclid=IwY2xjawSAqWRleHRuA2FlbQIxMQBzcnRjBmFwcF9pZAwzNTA2ODU1MzE3MjgAAR6b1PCdYeOpCJoQxXDF07yeHR9kg-TRsXsroG3gHGRD6JG4aJ11JNCPChQdFQ_aem_2vACyEhBoZ9WXJBkTlbrnQ


SmartBridge is a Flutter-based communication assistant that combines:

- Real-time sign recognition using camera and landmark-based model inference
- Speech-to-text input
- Text-to-speech output
- Accessibility-focused controls

## Supported Targets

- Android (primary runtime)
- Web

Unneeded platform scaffolding for iOS, macOS, Linux, and Windows has been removed to keep this project focused and lighter.

## Version

- Current version: 1.0.0+1
- Last updated: April 15, 2026

## Core Pages

1. Translate
- Live camera sign recognition
- Speech-to-text capture
- Text-to-speech playback

2. History
- Stores recognized signs, speech captures, and spoken outputs
- Supports history clearing

3. Settings
- Accessibility options: text size, contrast, reduced motion, haptics
- Voice and recognition settings
- Permission shortcut to system app settings

4. About
- App details and version information
- Functional summary and usage notice

## First-Launch Flow

On first opening, users see swipeable onboarding pages that explain:

- What SmartBridge does
- Main translation functions
- Hand-sign tutorial reference image
- Accessibility support
- Expanded Terms and Conditions with usage and safety notes

The app is only accessible after checking the terms acceptance box.

## Technical Notes

- Main app entry and UI flow: `lib/main.dart`
- Services:
  - `lib/services/camera_service.dart`
  - `lib/services/model_service.dart`
  - `lib/services/permission_handler.dart`
- Model assets:
  - `assets/models/model_float32.tflite`
  - `assets/models/labels.txt`

## Run Commands

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```
