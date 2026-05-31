# ⚡ Surge — Constantly Growing

**Your personal English vocabulary growth app**

## Features
- 🏠 **Home** — Word of the Day (AI-powered), daily stats, recent words
- 📚 **Word Bank** — Full searchable/filterable word collection
- 🃏 **Drill** — Flip-card spaced repetition with mastery tracking
- 📝 **Notes** — Personal notebook for grammar rules & observations
- 📊 **Progress** — Streak calendar, mastery breakdown, milestones
- ⚙️ **Settings** — API key configuration, data management

## Offline Support
Everything except AI-powered features works fully offline:
- ✅ Browse & search Word Bank
- ✅ Drill flashcards
- ✅ Add words manually
- ✅ Notes
- ✅ Word of the Day (cached from last fetch)
- ⚡ AI auto-fill — requires internet + API key
- ⚡ AI Word of the Day — requires internet + API key

## Setup

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Add your Anthropic API key
Open the app → tap ⚙️ Settings → paste your API key from [console.anthropic.com](https://console.anthropic.com)

> **Without a key:** the app works fully offline. AI features are disabled but Word of the Day falls back to a curated default word.

### 3. Run
```bash
flutter run
```

## Tech Stack
- **Flutter** — cross-platform (Android/iOS)
- **shared_preferences** — offline-first local storage
- **google_fonts** — DM Sans typography
- **flutter_animate** — smooth animations
- **fl_chart** — progress charts
- **Anthropic API** — Claude for AI word details & Word of the Day

## App Icon
Replace `android/app/src/main/res/mipmap-*/ic_launcher.png` with your `favicon.png` for each density, or use `flutter_launcher_icons` package.
fuck yeah