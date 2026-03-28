# Weep - Waste Efficient Eating Planner

Weep is an AI-powered iOS app that helps you reduce food waste by tracking your kitchen inventory, alerting you before items expire, and generating meal plans from ingredients that need to be used up.

## Features

### Kitchen Inventory
- **AI Product Scanning** — Snap a photo of any food product and Claude AI extracts the name, brand, category, nutrition facts, allergens, ingredients, and storage recommendations.
- **Expiry Date OCR** — Automatically reads expiry dates from product labels using Apple Vision with support for 20+ date formats.
- **Freshness Tracking** — Visual freshness indicators (Very Fresh, Fresh, Expiring Soon, Expired) with a weekly overview and freshness ratio dashboard.
- **Storage Zones** — Organize items by Fridge, Freezer, or Pantry with customizable zones.

### AI Meal Planner
- **Smart Suggestions** — Generates 3 practical meal recipes prioritizing items closest to expiry.
- **Recipe Details** — Full recipes with ingredients (cross-referenced with your kitchen), step-by-step instructions, cooking time, servings, and difficulty level.
- **Save & Review** — Save generated meal plans for later and browse your plan history.

### Expiry Notifications
- **3-Level Alert System** — Gentle nudge at 3 days, urgent alert at 1 day, critical alert on the expiry date.
- **Daily Summary** — Morning notification at 8:30 AM summarizing items expiring soon.
- **Actionable** — Mark items as used or snooze reminders directly from the notification.

### Waste History
- **Removal Tracking** — Every item is logged as Used, Expired, or Deleted with timestamps.
- **Filterable History** — Review past items by removal reason.
- **Waste Awareness** — Estimated monthly food waste cost based on household size.

### Profile & Preferences
- **Theme Support** — Light, Dark, or System appearance.
- **Account Management** — Manage your account, log out, or delete your data.

## Tech Stack

| Layer | Technology |
|---|---|
| **Platform** | iOS / iPadOS 26.0+, Swift, SwiftUI |
| **Auth** | [Clerk](https://clerk.com) (Apple ID & Google OAuth) |
| **Backend** | [Supabase](https://supabase.com) (PostgreSQL, Realtime, Storage) |
| **AI** | [Claude API](https://docs.anthropic.com) (Vision analysis & meal generation) |
| **OCR** | Apple Vision framework |
| **Animations** | [Lottie](https://github.com/airbnb/lottie-ios) |

## Architecture

The app follows **MVVM** with Swift's `@Observable` macro and uses Swift Concurrency (`async/await`) throughout.

```
Weep/
├── WeepApp.swift                 # App entry point, Clerk config
├── Views/
│   ├── RootView.swift            # Routes between onboarding and main app
│   ├── Onboarding/               # 12-step onboarding flow
│   ├── Kitchen/                  # Home tab — inventory dashboard
│   ├── MealPlanner/              # AI meal suggestions & saved plans
│   ├── History/                  # Waste tracking history
│   ├── Profile/                  # Account & settings
│   └── Camera/                   # Product capture & OCR flow
├── ViewModels/
│   ├── OnboardingViewModel.swift # Onboarding state & persistence
│   └── KitchenStore.swift        # Main inventory state, Supabase sync
├── Models/                       # Data models (FoodItem, MealPlan, etc.)
├── Services/
│   ├── SupabaseService.swift     # Database & storage operations
│   ├── ClaudeProductAnalyzer.swift # AI image analysis
│   ├── MealPlanGenerator.swift   # AI meal plan generation
│   ├── ExpiryDateParser.swift    # OCR date extraction
│   ├── NotificationManager.swift # Push notification scheduling
│   └── CameraService.swift       # Camera session management
├── Components/                   # Reusable UI components
└── Theme/
    └── WeepTheme.swift           # Design system (colors, fonts, haptics)
```

## Onboarding Flow

1. Welcome → 2. Sign Up (Clerk) → 3. Personalized Greeting → 4. Household Info → 5. Shopping Frequency → 6. Shopping Locations → 7. Kitchen Zones → 8. Dietary Preferences → 9. Waste Self-Assessment → 10. Primary Goal → 11. Permissions (Camera & Notifications) → 12. First Product Scan

## Getting Started

### Prerequisites
- Xcode 26.0.1+
- iOS 26.0+ Simulator or device

### Configuration
The app requires API keys for the following services:
- **Clerk** — Authentication
- **Supabase** — Database, realtime sync, and image storage
- **Anthropic (Claude)** — Product analysis and meal plan generation

### Build

```bash
# Debug build
xcodebuild -scheme Weep -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Release build
xcodebuild -scheme Weep -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Database Tables

| Table | Purpose |
|---|---|
| `food_items` | Kitchen inventory with nutrition, expiry, and removal tracking |
| `profiles` | User preferences, household info, onboarding data |
| `meal_plans` | Saved AI-generated meal suggestions |

## Design System

- **Colors** — Primary Green `#2D6A4F`, Accent Warm `#E9C46A`, Alert Amber `#F4A261`, Alert Red `#E76F51`, Background `#FEFAE0`
- **Typography** — SF Rounded (headlines), SF Pro (body), SF Mono (stats)
- **Haptics** — Feedback on all interactive elements

## License

All rights reserved.
