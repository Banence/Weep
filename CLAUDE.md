# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Weep (Waste Efficient Eating Planner) is an iOS/iPadOS app built with Swift and SwiftUI, targeting iOS 26.0. It helps users reduce food waste by tracking kitchen inventory, sending expiry alerts, and generating AI meal plans from ingredients that need using up. The project uses Xcode 26.0.1 with automatic code signing.

## Build Commands

```bash
# Build (debug)
xcodebuild -scheme Weep -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Build (release)
xcodebuild -scheme Weep -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

No test targets or linting tools are configured yet. The project uses Xcode's file system-based target membership — new Swift files in the `Weep/` directory are automatically included.

## Dependencies (SPM via Xcode)

- **ClerkKit / ClerkKitUI** (clerk-ios >= 1.0.8) — Authentication (Apple ID & Google OAuth)
- **Supabase** (supabase-swift >= 2.0.0) — PostgreSQL database, Realtime sync, Storage
- **Lottie** (lottie-ios >= 4.0.0) — Animated loaders
- Apple frameworks: Vision (OCR/classification), PhotosUI, UserNotifications, CoreHaptics

Claude AI integration uses direct HTTP calls to `api.anthropic.com/v1/messages` (no SDK).

## Architecture

MVVM with `@Observable`. Swift Concurrency (`async/await`) throughout.

### Entry & Navigation
- `WeepApp.swift` — App entry point (`@main`), Clerk auth configuration, Supabase client init.
- `Views/RootView.swift` — Routes between onboarding and `MainTabView` based on onboarding completion.
- `Views/MainTabView.swift` — 4-tab layout: Kitchen, Meal Planner, History, Profile.

### Onboarding (12 steps)
- `Views/Onboarding/OnboardingContainerView.swift` — Manages the 12-step flow with progress bar, back/skip navigation, and animated transitions.
- `ViewModels/OnboardingViewModel.swift` — `@Observable` state for all onboarding data. Persists to UserDefaults for mid-flow resume and syncs to Supabase profiles table on completion.
- Steps: welcome → signUp → greeting → household → shoppingFrequency → shoppingLocations → kitchenZones → dietary → wasteReality → goal → permissions → firstScan.
- Screen files in `Views/Onboarding/`: `WelcomeScreen`, `SignUpScreen`, `GreetingScreen`, `HouseholdScreen`, `ShoppingHabitsScreen`, `KitchenZonesScreen`, `DietaryScreen`, `WasteRealityScreen`, `GoalScreen`, `PermissionsScreen`, `FirstScanScreen`.

### Main App Views
- `Views/MealPlannerView.swift` — AI-generated meal suggestions from expiring items, save/view plan history.
- `Views/HistoryView.swift` — Filterable log of used/expired/deleted items.
- `Views/ProductDetailSheet.swift` — Full product detail overlay.
- `Views/ExpiryCheckInSheet.swift` — Expiry check-in prompt.
- `Views/Profile/` — `ProfileView`, `AccountDetailView`, `AppearanceView`.

### Camera & Scanning
- `Views/Camera/CameraCaptureView.swift` — 3-step capture flow: product photo → expiry date OCR → review & confirm.
- `Views/Camera/CameraPreviewView.swift` — Live camera preview.
- `Views/Camera/CameraService.swift` — AVCaptureSession management.
- `Views/Camera/DateScannerView.swift` — Live OCR date detection overlay.

### ViewModels
- `ViewModels/KitchenStore.swift` — Main inventory state management, local cache (UserDefaults), Supabase CRUD with Realtime subscriptions, auto-expiry marking.
- `ViewModels/OnboardingViewModel.swift` — Onboarding flow state.

### Models
- `Models/FoodItem.swift` — `FoodItem` (inventory item with nutrition, expiry, removal tracking), `FreshnessStatus`, `MealPlan`, `MealSuggestion`, `ProfileDTO`.
- `Models/OnboardingModels.swift` — Enums: `ShoppingFrequency`, `ShoppingLocation`, `StorageZone`, `DietaryPreference`, `PrimaryGoal`, `OnboardingStep`.

### Services
- `Services/SupabaseService.swift` — Database operations, image storage (`product-images` bucket), profile sync.
- `Services/ClaudeProductAnalyzer.swift` — Claude Vision API for product image analysis (name, brand, nutrition, allergens, storage tips, shelf life).
- `Services/MealPlanGenerator.swift` — Claude API for generating 3 meal suggestions from expiring items.
- `Services/ExpiryDateParser.swift` — OCR date extraction using Vision + NSDataDetector + regex (20+ date formats).
- `Services/ProductIdentifier.swift` — Vision image classification and label text recognition.
- `Services/NotificationManager.swift` — 3-level expiry alerts (3 days, 1 day, day-of), daily 8:30 AM summary, actionable notifications (mark used / snooze).

### Theme & Components
- `Theme/WeepTheme.swift` — Design system: `WeepColor`, `WeepFont`, `WeepHaptics`, staggered animation modifier.
- `Theme/ThemeManager.swift` — Light/Dark/System theme persistence (UserDefaults + Supabase).
- `Components/` — `WeepButton`, `OnboardingProgressBar`, `SelectionCard`.

## Design System

Colors defined in `WeepColor` (hex-based): primaryGreen `#2D6A4F`, accentWarm `#E9C46A`, alertAmber `#F4A261`, alertRed `#E76F51`, background `#FEFAE0`. Typography uses SF Rounded (headlines), SF Pro (body), SF Mono (stats). All interactive elements include haptic feedback via `WeepHaptics`.

## Database (Supabase)

Three tables: `food_items` (inventory with nutrition and removal tracking), `profiles` (user preferences, household, onboarding data), `meal_plans` (saved AI-generated suggestions). Images stored in `product-images` Storage bucket.

## Configuration

API keys are stored in `Secrets.xcconfig` (git-ignored). Required keys: Clerk publishable key, Supabase URL + anon key, Anthropic API key.

## Swift Concurrency Settings

The project enables `SWIFT_APPROACHABLE_CONCURRENCY` with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. All types default to MainActor isolation — use `nonisolated` or explicit actor annotations when needed.
