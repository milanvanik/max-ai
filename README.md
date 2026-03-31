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

Max isn't just another ChatGPT wrapper. He is an **Agentic Assistant** designed to help you interact with the real world, heavily leaning towards becoming a powerful **study and productivity companion**. 

Max comes with a distinct personality (think Harvey Specter meets Mike Ross) and uses a custom-built Hybrid Router to seamlessly switch between Groq (Llama-3) for lightning-fast reasoning and Google Gemini for sophisticated multi-modal fallbacks. He doesn't just talk; he *acts* by using tools.

## ✨ Core Features

- **🧠 Hybrid AI Engine**: Intelligently routes text queries to Groq's high-speed Llama models and vision/fallback queries to Google Gemini.
- **🦾 Agentic Tools**: Max has "hands". He can pause his thinking to pull real-world data:
  - 🔍 **Live Web Search** (via Tavily)
  - 🌤️ **Live Weather** (via OpenWeatherMap)
  - 🕰️ **System Time & Date Awareness**
- **🎙️ Push-to-Talk Voice Mode**: A specialized, hold-to-speak interface where Max responds with short, natural, conversational audio instead of giant walls of text.
- **📚 Multi-Threaded Memory**: Local persistence using Hive. Max auto-names your conversation threads based on context, allowing you to jump back into past sessions instantly.

## 🚀 Future Roadmap (Study Focus)

Max is evolving from a raw assistant into a dedicated **Study Buddy**. Upcoming features include:

- [ ] **Flashcards & UI Widgets**: Dynamic, AI-generated study cards rendered natively in Flutter.
- [ ] **NotebookLM-Style Document Analysis**: Upload PDFs or textbooks and have Max synthesize the material, test your knowledge, and act as a personalized tutor.
- [ ] **Premium UI Overhaul**: Glassmorphism, tailored animations, and a world-class aesthetic finish.

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
