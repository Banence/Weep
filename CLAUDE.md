# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Weep is an iOS/iPadOS app built with Swift and SwiftUI, targeting iOS 26.0. The project uses Xcode 26.0.1 with automatic code signing.

## Build Commands

```bash
# Build (debug)
xcodebuild -scheme Weep -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Build (release)
xcodebuild -scheme Weep -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

No test targets or linting tools are configured yet. The project uses Xcode's file system-based target membership — new Swift files in the `Weep/` directory are automatically included.

## Architecture

- `WeepApp.swift` — App entry point (`@main`). Clerk auth will be configured here.
- `Views/RootView.swift` — Routes between onboarding and home screen based on onboarding completion state.
- `Views/Onboarding/OnboardingContainerView.swift` — Manages the 10-step onboarding flow with progress bar, back/skip navigation, and animated transitions.
- `ViewModels/OnboardingViewModel.swift` — `@Observable` state for all onboarding data. Persists to UserDefaults for mid-flow resume. Will migrate to Clerk `unsafeMetadata` when SDK is integrated.
- `Theme/WeepTheme.swift` — Design system: colors (`WeepColor`), typography (`WeepFont`), haptics (`WeepHaptics`), and staggered animation modifier.
- `Models/OnboardingModels.swift` — Enums for shopping frequency, locations, storage zones, dietary preferences, goals, and onboarding steps.
- `Components/` — Reusable UI: `WeepButton`, `OnboardingProgressBar`, `SelectionCard`, `ChipView`, `FlowLayout`.

## Design System

Colors defined in `WeepColor` (hex-based): primaryGreen `#2D6A4F`, accentWarm `#E9C46A`, alertAmber `#F4A261`, alertRed `#E76F51`, background `#FEFAE0`. Typography uses SF Rounded (headlines), SF Pro (body), SF Mono (stats). All interactive elements include haptic feedback via `WeepHaptics`.

## Swift Concurrency Settings

The project enables `SWIFT_APPROACHABLE_CONCURRENCY` with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. All types default to MainActor isolation — use `nonisolated` or explicit actor annotations when needed.
