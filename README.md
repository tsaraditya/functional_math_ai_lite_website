# Functional Math AI Lite Studio 🧠📊

A live, production-deployed cross-platform web application built using Flutter and Dart, engineered specifically to support UK Level 1 and Level 2 Functional Skills Mathematics. 

🔗 **Live Application Deployment:** https://tsaraditya.github.io/functional_math_ai_lite_website/

---

## 🚀 Key Architectural Features

* **LLM Engine Integration:** Powered by the Llama 3.3-70b model utilizing the Groq API framework to handle complex, real-time context-retaining conversational tutoring loops.
* **JSON Parsing Architecture:** Built a strict automated data mapping engine (`Map<String, dynamic>`) backed by robust asynchronous try-catch handlers to reliably parse nested generative AI payloads into operational database layers.
* **Universal Browser Compatibility:** Integrated platform-specific conditional imports (`universal_html` and `web_html`) to bypass browser sandbox limitations, creating an active web-blob stream bridge that allows users to download dynamically generated `.doc` assessment matrices directly from the UI.
* **Persistent Utility Matrix:** Designed an asynchronous, global state navigation layout featuring an adaptive floating action button (FAB) that maintains a running scientific calculator matrix across all operational view tabs.

---

## 🛠️ Pedagogical Requirements Engineering

Drawing from classroom data points teaching Functional Skills Mathematics within UK educational frameworks, this system acts as a non-linear scaffold. Instead of presenting static multiple-choice answers, the AI tutor tracks student calculation sequences and generates step-by-step conceptual hints based on verified adult learning edge cases.

---

## 💻 Tech Stack & Dependencies

* **Frontend Framework:** Flutter & Dart (Web Release Target)
* **API Middleware:** High-throughput Groq Client Connection
* **Core Models:** Llama-3.3-70b-versatile
* **Dependencies:** `http`, `path_provider`, `share_plus`, `universal_html`

---

## 📦 Local Development & Secure Compilation

To execute the project locally with full access to the AI engine, compile using compile-time environment definitions to protect live API tokens:

```bash
# Fetch required dependencies
flutter pub get

# Execute local web runner
flutter run -d chrome --dart-define=GROQ_API_KEY=YOUR_API_KEY

# Compile release assets for production
flutter build web --release --dart-define=GROQ_API_KEY=YOUR_API_KEY
