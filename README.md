# ⚡ JioGenie - Unofficial AI Assistance for Jio (Flutter & React + RAG)

A modern, responsive, component-driven AI chatbot application with authentic **Reliance Jio portal branding**, colors, typography, pill-shaped UI components, category navigation tabs, and **Okapi BM25 RAG** powered by **Groq Cloud LPUs**.

Now featuring a complete **Flutter** cross-platform frontend (Web, Linux Desktop, Android, iOS) alongside the original lightweight React 18 frontend!

---

## 🎨 Jio Design System & Branding

- 🔵 **Jio Royal Blue** (`#0057FF`) & **Deep Jio Navy** (`#0A2885` / `#00175A`)
- 🔴 **Jio Digital Red** (`#E50027`) circular brand badges ("Unofficial AI")
- ⚡ **Jio True 5G Cyan & Mint** (`#00C2FF` / `#00D284`)
- ⚪ **Jio Signature Light Portal Surface** (`#F5F7FB`) & pure white cards
- 🔘 **Pill-shaped Components**: `border-radius: 9999px` on action buttons, search, and category tabs
- 📡 **Custom Telecom Emblem**: Vector-drawn transmitter beacon with radio broadcast wave arcs
- 🔤 **Typography**: Plus Jakarta Sans geometric typography matching official Jio styling

---

## 📱 Flutter Frontend Architecture (`flutter_app/`)

The Flutter application provides native desktop, mobile, and web performance:
- **`JioGenieApp` / `main.dart`**: Reactive state management (chats, active session, search, settings, streaming tokens).
- **`JioNavbar`**: Top bar with sidebar toggle, JioGenie brand title, "New Inquiry" button, and "Export Markdown" action.
- **`JioSidebar`**: Responsive collapsible drawer with search filter, date-grouped chat history ("Today", "Yesterday", "Previous 7 Days", "Older"), inline rename and delete, and Settings / Clear History actions.
- **`CategoryTabs`**: Horizontal scrollable pill tabs for **All Services**, **Mobile Plans**, **True 5G**, **JioFiber**, **JioAirFiber**, and **eSIM & Support**.
- **`WelcomeView`**: Hero telecom emblem, official tagline, and responsive 2x2 grid of prompt suggestion cards.
- **`MessageBubble`**: Rich GitHub-flavored Markdown rendering with tables, code blocks, copy action, thumbs up feedback, retry, and verified **Jio.com source pills** with `url_launcher`.
- **`SynthesizingIndicator` & `LiveStreamRibbon`**: 4-bar animated signal indicator and real-time streaming badge.
- **`ComposerBar`**: Auto-expanding pill input container with send button, stop generating button, and legal disclaimer.
- **`RagService`**: Client-side Okapi BM25 token-matching engine with bundled `jio_knowledge.json` asset and synonym expansion.
- **`GroqService`**: Direct SSE streaming client for Groq Cloud LPUs with liquid typewriter easing and offline smart simulation.
- **`StorageService`**: Persistent chat history and engine settings via `SharedPreferences`.

---

## 🚀 Quick Start

### 1. Run Flutter Frontend

Navigate to `flutter_app` and run on your preferred platform:

```bash
cd flutter_app

# Run on Chrome (Web)
flutter run -d chrome

# Run on Linux Desktop
flutter run -d linux

# Run tests
flutter test

# Build production web release
flutter build web
```

### 2. Run with Python Server (Serves Flutter Web)

```bash
# Serve Flutter Web build directly
python server.py --flutter --port 8080

# Or serve original React frontend
python server.py --port 8080
```

---

## 📁 Project Structure

```
jiogenie/
├── flutter_app/                  # Flutter cross-platform project
│   ├── assets/
│   │   └── jio_knowledge.json    # Bundled Jio knowledge corpus
│   ├── lib/
│   │   ├── main.dart             # App entry & state orchestration
│   │   ├── constants/            # Jio brand colors, category prompts, settings
│   │   ├── models/               # ChatSession, ChatMessage, Citation, KnowledgeDoc
│   │   ├── services/             # RagService, GroqService, StorageService
│   │   ├── theme/                # JioTheme (Plus Jakarta Sans, light palette)
│   │   └── widgets/              # JioNavbar, JioSidebar, WelcomeView, MessageBubble, ComposerBar...
│   ├── build/web/                # Compiled Flutter Web production bundle
│   └── pubspec.yaml              # Flutter dependencies & assets configuration
├── index.html                    # React 18 mount point & CDN dependencies
├── app.jsx                       # React 18 application components
├── styles.css                    # Jio website design system & styles
├── rag_engine.py                 # Okapi BM25 retrieval engine & Groq synthesis
├── scraper.py                    # Web scraper for https://www.jio.com/
├── jio_knowledge.json            # Verified Jio.com knowledge corpus
├── server.py                     # Python HTTP server & RAG API gateway (with --flutter support)
├── start.bat                     # 1-click Windows launcher
└── README.md                     # Documentation
```
