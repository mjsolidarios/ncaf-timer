# NCAF 2026 Timer

A Flutter event/contest timer app for the **National Culture and Arts Festival 2026**, built with the *Cultural Tapestry* design system.

## Features

- ⏱ **Countdown timer** with configurable duration (hours, minutes, seconds)
- ▶️ **Start / Pause / Resume / Reset** controls
- ✏️ **Editable event name** — tap the title to rename the event or contest
- ⛶ **Full-screen mode** — maximize the timer to fill the entire screen/window
- 📱 **Mobile responsive** — adapts to any screen size
- 🎨 **Cultural Tapestry design** — vibrant festival palette with glassmorphism and animated orbs
- 🌐 **Multi-platform** — deployable as Web, Android, iOS, Linux, Windows, or macOS app

## Design System: The Cultural Tapestry

| Token | Value | Usage |
|---|---|---|
| Primary | `#406E51` | Heritage green — navigation, CTAs |
| Secondary | `#9C5000` | Sun-kissed orange — energy, Pagsaulog |
| Tertiary | `#834AAE` | Royal purple — artistic prestige |
| Surface | `#FEFCF1` | Warm cream — background |
| On Surface | `#383831` | Soft text (never pure black) |

**Typography:**
- **Noto Serif** — Display & Headlines (tradition voice)
- **Plus Jakarta Sans** — Body & Labels (function voice)

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.0.0

### Install dependencies

```bash
flutter pub get
```

### Run

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios

# Linux desktop
flutter run -d linux

# Windows desktop
flutter run -d windows

# macOS desktop
flutter run -d macos
```

### Build for production

```bash
# Web
flutter build web

# Android APK
flutter build apk

# iOS
flutter build ios

# Linux
flutter build linux
```

### Run tests

```bash
flutter test
```

