# DriftDock 🌊

An iOS SpringBoard jailbreak tweak inspired by **Drift** that removes the stock 4-app limit on your iPhone / iPad dock and replaces it with an infinite, smooth-scrolling dock with snap physics, edge fade/shrink animations, and haptic feedback.

---

## ✨ Features

- **Infinite Apps in Dock**: Place up to 50+ apps or folders in your dock instead of the stock 4.
- **Fluid Horizontal Scrolling**: Powered by a custom `UIScrollView` wrapper (`DriftScrollView`) tuned with `UIScrollViewDecelerationRateFast` for responsive, native-feeling momentum.
- **Snap-to-Icon Physics**: Calculates target offsets on flick deceleration to ensure an app icon is always cleanly centered and never cut off at the edge.
- **Drift Edge Animations**: Smooth cubic-eased scaling down to `0.7x` and alpha fading down to `0.35` as icons slide past the left and right edges.
- **Haptic Feedback**: Fires subtle, crisp taptic ticks (`UISelectionFeedbackGenerator`) every time you slide past an icon slot.
- **Full Gesture Compatibility**: Native 3D Touch / Haptic Touch context menus, app taps, and drag-and-drop icon reordering (jiggle mode) work seamlessly without touch conflicts.
- **Dynamic Preferences (No Respring Required)**: Real-time preference updates via Darwin notifications (`CFNotificationCenter`).

---

## 🏗️ Architecture & How It Works

```
SpringBoard Hierarchy:
┌────────────────────────────────────────────────────────┐
│ SBDockView (Dock Platter & Blur)                       │
│  └─ DriftScrollView (Custom Horizontal ScrollView)      │
│      └─ SBDockIconListView (Unlimited App Icons)       │
│          ├─ SBIconView (App 1)                         │
│          ├─ SBIconView (App 2)                         │
│          ├─ ...                                        │
│          └─ SBIconView (App N)                         │
└────────────────────────────────────────────────────────┘
```

1. **Capacity Hooks (`SBDockIconListView` & `SBIconListModel`)**:
   - Stock iOS enforces the 4-icon limit inside `iconColumnsForCurrentOrientation`, `maximumIconCount`, `maxIcons`, and `allowsAddingIconCount:`.
   - `Tweak.x` intercepts these calls and overrides them with the user-defined maximum (e.g. 50).
   - `SBIconListModel` is also hooked so SpringBoard's model layer never rejects extra apps when dragged into the dock.

2. **Scroll View Injection (`SBDockView`)**:
   - In `-[SBDockView layoutSubviews]`, `Tweak.x` dynamically wraps the native `SBDockIconListView` inside `DriftScrollView`.
   - The platter view's `clipsToBounds` is respected so icons stay elegantly confined within the dock bounds.

3. **Physics & Edge Shader Effects (`DriftScrollView`)**:
   - As icons scroll, `applyEdgeEffects` converts each icon's coordinate space and evaluates its distance from the dock edges.
   - A cubic hermite curve (`smooth = progress * progress * (3.0 - 2.0 * progress)`) provides smooth acceleration into the shrink/fade state.

---

## 🛠️ Requirements & Building

### Prerequisites
- [Theos](https://theos.dev) installed on macOS, Linux, or WSL.
- iOS 14.0 - 17.0+ patched SDK placed in `$THEOS/sdks/`.
- Modern jailbreak environment (Dopamine, Palera1n, XinaA15, or checkra1n).

### Build for Rootless (iOS 15 - 18 / Dopamine / Palera1n):
```bash
make clean
make package THEOS_PACKAGE_SCHEME=rootless
```
The resulting `.deb` package will be generated inside the `packages/` directory.

### Build for Rootful:
```bash
make clean
make package
```

### Install directly via SSH to your device:
```bash
export THEOS_DEVICE_IP=192.168.1.xxx
export THEOS_DEVICE_PORT=22
make do THEOS_PACKAGE_SCHEME=rootless
```

---

## ⚙️ Configuration (Settings.app)

Access **Settings > DriftDock** on your iOS device to configure:
- **Enable DriftDock**: Toggle tweak on or off.
- **Dock Capacity Slider**: Adjust max allowed icons (4 to 60).
- **Snap to Nearest Icon**: Turn snap physics on/off.
- **Haptic Feedback**: Toggle scroll ticks.
- **Edge Fade & Shrink**: Toggle edge zoom/fade effects.
- **Respring SpringBoard**: Quick action button to reload SpringBoard if needed.

---

## 📁 Project Structure

```
DriftDock/
├── Makefile                       # Main Theos build script
├── control                        # Debian package control file
├── Tweak.h                        # SpringBoard private header declarations
├── Tweak.x                        # Logos hooks for SpringBoard, DockView & IconListView
├── DriftManager.h                 # Preferences manager header
├── DriftManager.m                 # Real-time preference observer implementation
├── DriftScrollView.h              # Scroll container header
├── DriftScrollView.m              # Snap physics, haptics & edge animations
└── driftprefs/                    # Settings bundle
    ├── Makefile                   # Bundle makefile
    ├── entry.plist                # Settings app registration
    ├── DriftRootListController.h  # Controller header
    ├── DriftRootListController.m  # Preferences controller & respring action
    └── Resources/
        └── Root.plist             # Settings UI specifiers
```
