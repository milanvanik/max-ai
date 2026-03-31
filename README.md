<br />
<div align="center">
  <h1 align="center">Max AI Buddy ⚡</h1>

  <p align="center">
    A highly intelligent, snappy, and agentic AI companion built with Flutter.
    <br />
    <br />
    <a href="#features">Features</a>
    ·
    <a href="#roadmap">Roadmap</a>
    ·
    <a href="#setup">Setup</a>
  </p>
</div>

## 🤖 About Max

Max is a powerful, agentic AI assistant designed to help you interact with the real world seamlessly. He comes with a distinct, confident personality and uses a custom-built Hybrid Router to intelligently switch between high-speed reasoning models and sophisticated multi-modal engines. He goes beyond standard text generation by actively using tools to pull real-time data and perform complex tasks on your behalf.

## ✨ Core Features

- **🧠 Hybrid AI Engine**: Intelligently routes text queries to high-speed Llama models via Groq and logic/vision queries to Google Gemini.
- **🦾 Agentic Tools**: Max can execute live tools to synthesize factual, up-to-date data:
  - 🔍 **Live Web Search** (via Tavily)
  - 🌤️ **Live Weather** (via OpenWeatherMap)
  - 🕰️ **System Time & Date Awareness**
- **🎙️ Push-to-Talk Voice Mode**: A specialized, hold-to-speak interface where Max responds with short, natural, conversational audio instead of giant walls of text.
- **📚 Multi-Threaded Memory**: Local persistence using Hive. Max auto-names your conversation threads based on context, allowing you to jump back into past sessions instantly.

## 🚀 Future Roadmap (Focus: Next-Gen Study & Productivity)

Max is rapidly evolving into a dedicated, high-performance study and productivity companion:

- [ ] **Smart Flashcards**: Dynamic, AI-generated study cards and interactive widgets rendered natively in Flutter.
- [ ] **Advanced Document Synthesis**: Upload PDFs, textbooks, or notes and have Max map the material, test your knowledge, and act as a personalized, context-aware tutor.
- [ ] **Premium UI Overhaul**: Implementation of modern design aesthetics, tailored animations, and a world-class visual finish.

## 🛠️ Setup & Environmental Variables

To run Max locally, you will need to create a `.env` file in the root directory with the following API keys:

```env
GEMINI_API_KEY=your_gemini_key
GROQ_API_KEY=your_groq_key
TAVILY_API_KEY=your_tavily_key
OPENWEATHER_API_KEY=your_openweather_key
```

### Build Requirements
- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / Xcode

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.
