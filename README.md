# 🤖 Mia21 SDKs

**Build powerful AI chat experiences on iOS and Android with just a few lines of code.**

Official SDKs for Mia21 AI Chat API - production-ready, fully tested, and designed for real-world mobile apps.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 📱 Available Platforms

### 🍎 [iOS SDK](./ios/)

[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B%20%7C%20macOS%2012%2B-lightgrey.svg)](./ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](./ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](./ios/)

Native Swift SDK for iOS, macOS, watchOS, and tvOS.

**Quick Start:**
```swift
import Mia21

let client = Mia21Client(apiKey: "YOUR_API_KEY")
try await client.initialize()
let response = try await client.chat(message: "Hello!")
```

**Features:**
- ✅ Real-time streaming responses
- ✅ Voice input (speech-to-text)
- ✅ Multi-bot support
- ✅ Conversation management
- ✅ SwiftUI & UIKit examples

👉 [**iOS Documentation**](./ios/README.md) | [Examples](./ios/Examples/)

---

### 🤖 Android SDK

🚧 **Coming Soon**

Native Kotlin SDK for Android is currently in development.

**Planned Features:**
- ⏳ Kotlin coroutines
- ⏳ Real-time streaming
- ⏳ Voice input support
- ⏳ Multi-bot support
- ⏳ Jetpack Compose examples

Stay tuned for updates!

---

## ⚡ Quick Start Guide

### Get Your API Key

Sign up at [mia21.com](https://mia21.com/signup) to get your free API key.

### Installation

<details>
<summary><b>iOS - Swift Package Manager</b></summary>

**In Xcode:**
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/yourusername/mia-sdks.git`
3. Select the `Mia21` product
4. Add to your target

**Or in Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/yourusername/mia-sdks.git", from: "1.0.0")
]
```
</details>

<details>
<summary><b>Android - Coming Soon</b></summary>

The Android SDK is currently in development. Check back soon for installation instructions!
</details>

## ✨ Core Features

| Feature | iOS | Android | Description |
|---------|:---:|:-------:|-------------|
| **Real-time Streaming** | ✅ | 🚧 | Word-by-word responses |
| **Voice Input** | ✅ | 🚧 | Speech-to-text built-in |
| **Conversation History** | ✅ | 🚧 | Persistent chat storage |
| **Multi-Bot Support** | ✅ | 🚧 | Switch AI personalities |
| **Spaces** | ✅ | 🚧 | Organize by context/topic |
| **BYOK** | ✅ | 🚧 | Use your own LLM keys |
| **Async/Await** | ✅ | 🚧 | Modern concurrency |
| **Error Handling** | ✅ | 🚧 | Comprehensive error types |

---

## 📖 Documentation

### Platform-Specific Docs
- 📱 [**iOS Full Documentation**](./ios/README.md) - Complete guide with examples
- 🤖 **Android Documentation** - Coming Soon

### Example Apps
- 🎨 [SwiftUI Example](./ios/Examples/MiaSwiftUIExample/) - Modern declarative UI
- 📱 [UIKit Example](./ios/Examples/MiaUIKitExample/) - Traditional UIKit
- 🚀 **Android Example** - Coming Soon

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
Copyright (c) 2025 Mia21

Permission is hereby granted, free of charge, to use, copy, modify, and distribute
this software for any purpose with or without fee.
```

---

**Built with ❤️ by the Mia21 Team**
