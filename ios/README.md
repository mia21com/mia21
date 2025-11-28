# 🤖 Mia21 iOS SDK

**Build powerful AI chat experiences in your iOS apps with just a few lines of code.**

The official Swift SDK for Mia21 AI Chat API - production-ready, fully tested, and designed for real-world apps.

[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B%20%7C%20macOS%2012%2B-lightgrey.svg)](https://swift.org)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)

---

## 📦 Table of Contents

- [Quick Start](#-quick-start)
- [Features](#-features)
- [Installation](#-installation)
- [Basic Usage](#-basic-usage)
- [Advanced Features](#-advanced-features)
- [Example Apps](#-example-apps)
- [API Reference](#-api-reference)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)
- [Support](#-support)

---

## ⚡ Quick Start

### 1️⃣: Install via Swift Package Manager

**In Xcode:**
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/mia21com/mia21.git`
3. Select version: `1.0.0` or later
4. Add to your target

### 2️⃣: Get Your API Key

Sign up at [mia21.com](https://mia21.com/signup) to get your free API key.

### 3️⃣: Initialize and Send a Message

```swift
import Mia21

// Initialize the client
let client = Mia21Client(apiKey: "YOUR_API_KEY")

// Start a chat session
try await client.initialize()

// Send a message
let response = try await client.chat(message: "Hello! How can you help me?")
print(response.message)
```

That's it! You're ready to build. For more examples, see the sections below.

---

## ✨ Features

### 🚀 Core Features
- ✅ **Real-time Streaming** - Word-by-word responses
- ✅ **Async/Await** - Modern Swift concurrency
- ✅ **Conversation History** - Persistent chat storage
- ✅ **Voice Input** - Speech-to-text built-in
- ✅ **Multi-Bot** - Switch AI personalities
- ✅ **Spaces** - Organize by context/topic
- ✅ **BYOK** - Use your own LLM keys

### 📱 Platform Support
- **iOS** 15.0+ (iPhone & iPad)
- **macOS** 12.0+ (Intel & Apple Silicon)
- **watchOS** 8.0+
- **tvOS** 15.0+

### 🎨 Framework Support
- **SwiftUI** - Native declarative UI
- **UIKit** - Traditional UIKit apps
- **Combine** - Reactive programming ready

---

## 🔧 Installation

### Swift Package Manager (Recommended)

**Xcode 14+:**
1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Paste the URL: `https://github.com/mia21com/mia21.git`
4. Select version rule: **Up to Next Major** `1.0.0`
5. Click **Add Package**

---

## 📖 Basic Usage

### 1️⃣ Initialize the Client

```swift
import Mia21

let client = Mia21Client(
    apiKey: "your-api-key",
    userId: "user-123",       // Unique user identifier
    environment: .production  // .production or .staging
)
```

> **💡 Pro Tip:** Always use a persistent `userId` in production to maintain conversation history across app sessions.

### 2️⃣ Configure Logging (Optional but Recommended)

```swift
// 🔍 Enable detailed logs during development
#if DEBUG
Mia21Client.setLogLevel(.debug)  // See all SDK activity
#else
Mia21Client.setLogLevel(.error)  // Production: only errors
#endif
```

**Log Levels:**
- `.debug` - Verbose (all operations, requests, responses)
- `.info` - Important events only
- `.error` - Errors only (recommended for production)
- `.none` - No logging

### 3️⃣ Initialize Chat Session

```swift
// ✅ Simple - Start chatting immediately
try await client.initialize()

// ✅✅ Recommended - With welcome message
let response = try await client.initialize(
    options: InitializeOptions(
        generateFirstMessage: true  // Bot greets the user
    )
)

if let welcome = response.message {
    print("Bot: \(welcome)")
    // Example: "Hi! I'm here to help. What can I do for you today?"
}

// ✅✅✅ Full Configuration
let response = try await client.initialize(
    options: InitializeOptions(
        spaceId: "customer_support",    // Organize by context
        botId: "helpful_assistant",     // Specific AI personality
        generateFirstMessage: true,     // Bot greets user
        incognitoMode: false,           // Save conversation (default)
        language: "en",                 // User's language
        userName: "Alex"                // Personalize responses
    )
)
```

> **📝 Note:** Call `initialize()` once when your chat screen appears. You can reuse the same client for multiple messages.

### 4️⃣ Send Messages

**Option A: Non-Streaming (All at once)**
```swift
// ✅ Simple - Wait for complete response
let response = try await client.chat(message: "Tell me a joke")
print(response.message)
// Output: "Why did the chicken cross the road? To get to the other side!"
```

**Option B: Streaming (Real-time, word-by-word)**
```swift
// ✅✅ Recommended - See responses as they're typed
var messages = [ChatMessage(role: .user, content: "Write a haiku about coding")]
var botResponse = ""

try await client.streamChat(messages: messages) { chunk in
    botResponse += chunk
    
    // 🎯 Update UI on main thread
    Task { @MainActor in
        updateLabel(with: botResponse)
    }
}

// Save complete response to history
messages.append(ChatMessage(role: .assistant, content: botResponse))
```

**Advanced Streaming with Options:**
```swift
try await client.streamChat(
    messages: messages,
    options: ChatOptions(
        spaceId: "creative_writing",
        temperature: 0.9,      // More creative (0.0 = focused, 2.0 = random)
        maxTokens: 500         // Limit response length
    )
) { chunk in
    print(chunk, terminator: "")  // Print each word as it arrives
}
```

### 5️⃣ Manage Conversation History

**📋 List All Conversations:**
```swift
let conversations = try await client.listConversations(
    spaceId: nil,  // nil = all spaces, or specify: "customer_support"
    limit: 50      // Default: 50
)

for conv in conversations {
    print("\(conv.displayTitle()) - \(conv.messageCount) messages")
}
// Output:
// "Help with API integration - 12 messages"
// "Bug report discussion - 5 messages"
```

**📖 Load a Specific Conversation:**
```swift
let conversation = try await client.getConversation(conversationId: "conv-123")

// Convert to ChatMessage format
var messages: [ChatMessage] = conversation.messages.map { msg in
    ChatMessage(
        role: msg.role == "user" ? .user : .assistant,
        content: msg.content
    )
}

print("Loaded \(messages.count) messages")
```

**🔄 Continue an Existing Conversation:**
```swift
// Add new user message
messages.append(ChatMessage(role: .user, content: "Tell me more about that"))

// Stream response and continue the conversation
try await client.streamChat(
    messages: messages,
    options: ChatOptions(
        conversationId: "conv-123"  // ✅ Continue this conversation
    )
) { chunk in
    print(chunk, terminator: "")
}
```

**🗑️ Delete a Conversation:**
```swift
try await client.deleteConversation(conversationId: "conv-123")
print("Conversation deleted")
```

### 6️⃣ Close Session (Important for Resource Management)

```swift
// ✅ Close when app backgrounds
func sceneDidEnterBackground(_ scene: UIScene) {
    Task {
        try? await client.close()
    }
}

// ✅ Close when user logs out
func signOut() async {
    try? await client.close()
    // Clear user data...
}

// ✅ SwiftUI - Close on scene phase change
.onChange(of: scenePhase) { phase in
    if phase == .background {
        Task { try? await client.close() }
    }
}
```

> **⚠️ Important:** Always close sessions when backgrounding to free resources and prevent memory leaks.

---

## 🚀 Advanced Features

### 🎤 Voice Input (Speech-to-Text)

Turn audio into text automatically:

```swift
// 1. Record audio (use AVAudioRecorder or similar)
let audioURL = getRecordedAudioFile()
let audioData = try Data(contentsOf: audioURL)

// 2. Transcribe
let result = try await client.transcribeAudio(
    audioData: audioData,
    language: "en"  // Auto-detects if omitted
)

print("User said: \(result.text)")
// Output: "What's the weather like today?"

// 3. Send transcribed text to chat
let response = try await client.chat(message: result.text)
```

**📋 Supported Formats:**
- ✅ **WAV** (recommended) - Best accuracy
- ✅ **M4A** - iOS native format
- ✅ **MP3** - Compressed audio

**⚙️ Recommended Settings:**
- Sample rate: **16kHz**
- Channels: **Mono**
- Bit depth: **16-bit**

### 🏠 Spaces - Organize Conversations by Context

Spaces let you organize chats by topic, use case, or customer:

```swift
// 1️⃣ List available spaces
let spaces = try await client.listSpaces()

for space in spaces {
    print("\(space.name) - \(space.spaceId)")
}
// Output:
// "Customer Support - support_space"
// "Sales Inquiries - sales_space"
// "Technical Help - tech_space"

// 2️⃣ Start chat in specific space
try await client.initialize(
    options: InitializeOptions(spaceId: "support_space")
)

// 3️⃣ Switch spaces (close current, open new)
try await client.close()
try await client.initialize(
    options: InitializeOptions(spaceId: "sales_space")
)
```

### 🤖 Multi-Bot Support - Different AI Personalities

Switch between different AI personalities/assistants:

```swift
// 1️⃣ List available bots
let bots = try await client.listBots()

for bot in bots {
    print("\(bot.name) - \(bot.description ?? "")")
    if bot.isDefault {
        print("  ⭐ Default bot")
    }
}
// Output:
// "Customer Support Bot - Friendly and helpful"
//   ⭐ Default bot
// "Technical Expert - Detailed technical answers"
// "Sales Assistant - Product recommendations"

// 2️⃣ Use specific bot for a conversation
try await client.streamChat(
    messages: messages,
    options: ChatOptions(botId: "technical_expert")
) { chunk in
    print(chunk, terminator: "")
}

// 3️⃣ Switch bots mid-conversation
messages.append(ChatMessage(role: .user, content: "Now explain technically"))

try await client.streamChat(
    messages: messages,
    options: ChatOptions(botId: "technical_expert")
) { chunk in
    // Different bot, different personality
}
```

### 🔑 BYOK (Bring Your Own Key)

Use your own OpenAI or Google Gemini API key for direct billing:

```swift
// ✅ Initialize with your LLM key
let client = Mia21Client(
    customerLlmKey: "sk-proj-..." // Your OpenAI or Gemini key
)

// Specify which LLM to use
try await client.initialize(
    options: InitializeOptions(
        llmType: .openai,  // or .gemini
        generateFirstMessage: true
    )
)

// 💰 All requests now bill directly to YOUR account
// ✅ No Mia21 API usage fees (just platform fees)
```

**Why Use BYOK?**
- 💰 **Lower cost** - Pay LLM providers directly
- 🔒 **More control** - Your own rate limits
- 📊 **Direct analytics** - See usage in your LLM dashboard
- 🎯 **Custom models** - Use fine-tuned models from your account

**Supported LLMs:**
- ✅ **OpenAI** - GPT-4, GPT-4 Turbo, GPT-3.5
- ✅ **Google Gemini** - Gemini Pro, Gemini Pro Vision

---

## 🛡️ Error Handling

```swift
do {
    let response = try await client.chat(message: "Hello")
    print(response.message)
    
} catch Mia21Error.chatNotInitialized {
    // Need to call initialize() first
    print("Please initialize the chat session")
    
} catch Mia21Error.apiError(let message) {
    // Server-side error
    print("API error: \(message)")
    
} catch Mia21Error.networkError(let error) {
    // Network connectivity issue
    print("Network error: \(error.localizedDescription)")
    
} catch Mia21Error.invalidResponse {
    // Unexpected response format
    print("Invalid response from server")
    
} catch Mia21Error.decodingError(let error) {
    // JSON parsing failed
    print("Failed to parse response: \(error)")
    
} catch {
    // Unknown error
    print("Unexpected error: \(error)")
}
```

---

## 📱 Example Apps (Production-Ready Code)

Both examples are **fully functional**, **production-ready** apps you can learn from or use as a starting point:

### 🎨 SwiftUI Example (`Examples/MiaSwiftUIExample/`)

**Features:**
- ✅ Modern MVVM architecture
- ✅ Real-time streaming with smooth animations
- ✅ Conversation history with persistence
- ✅ Voice input (hands-free mode with VAD)
- ✅ Space and bot switcher
- ✅ Dark mode support
- ✅ Markdown rendering in messages
- ✅ Background session management
- ✅ Pull-to-refresh conversations
- ✅ Swipe-to-delete

**Perfect for:** New projects, declarative UI fans

---

### 📱 UIKit Example (`Examples/MiaUIKitExample/`)

**Features:**
- ✅ Programmatic UI (no storyboards)
- ✅ Custom message bubbles with markdown
- ✅ Streaming with smooth scrolling
- ✅ Voice transcription + audio playback
- ✅ Side menu navigation
- ✅ TableView-based chat
- ✅ Swipe actions on conversations
- ✅ Loading states and error handling
- ✅ Haptic feedback
- ✅ Accessibility support

**Perfect for:** Existing UIKit apps, more control

---

### 🚀 Run the Examples:

```bash
# 1. Clone the repository
git clone https://github.com/mia21com/mia21.git
cd mia21/ios/Examples

# 2. Open in Xcode
open MiaSwiftUIExample.xcodeproj  # or MiaUIKitExample.xcodeproj

# 3. Update API key in SceneDelegate.swift or App.swift
# 4. Build and run (⌘R)
```

> **💡 Tip:** The example apps demonstrate best practices for production apps including error handling, background sessions, and memory management.

---

## 📊 API Reference

### Mia21Client

| Method | Description | Returns |
|--------|-------------|---------|
| `initialize(options:)` | Start chat session | `InitializeResponse` |
| `chat(message:options:)` | Send message (non-streaming) | `ChatResponse` |
| `streamChat(messages:options:onChunk:)` | Send message (streaming) | `Void` |
| `streamChatWithVoice(messages:options:voiceConfig:onEvent:)` | Stream with voice output | `Void` |
| `listSpaces()` | Get all spaces | `[Space]` |
| `listBots()` | Get all bots | `[Bot]` |
| `listConversations(spaceId:limit:)` | Get conversation history | `[ConversationSummary]` |
| `getConversation(conversationId:)` | Get full conversation | `Conversation` |
| `deleteConversation(conversationId:)` | Delete conversation | `DeleteConversationResponse` |
| `transcribeAudio(audioData:language:)` | Speech-to-text | `TranscriptionResponse` |
| `close(spaceId:)` | Close session | `Void` |

### Configuration Types

**InitializeOptions:**
- `spaceId: String?` - Space identifier
- `botId: String?` - Bot identifier
- `llmType: LLMType?` - `.openai` or `.gemini`
- `userName: String?` - User's display name
- `language: String?` - Language code (e.g., "en")
- `generateFirstMessage: Bool` - Bot greets user
- `incognitoMode: Bool` - Don't save conversation
- `customerLlmKey: String?` - BYOK key
- `spaceConfig: SpaceConfig?` - Custom space config

**ChatOptions:**
- `spaceId: String?` - Override space
- `botId: String?` - Override bot
- `conversationId: String?` - Continue conversation
- `temperature: Double?` - LLM temperature (0.0-2.0)
- `maxTokens: Int?` - Max response length
- `llmType: LLMType?` - Override LLM
- `customerLlmKey: String?` - BYOK key

---

## 🔍 Troubleshooting

### ❌ Error: "Chat not initialized"

**Problem:** Trying to send messages before initializing the session.

```swift
// ❌ Wrong
let client = Mia21Client(apiKey: "...")
try await client.chat(message: "Hello")  // ❌ Crashes!

// ✅ Correct
let client = Mia21Client(apiKey: "...")
try await client.initialize()  // ✅ Initialize first
try await client.chat(message: "Hello")  // ✅ Now works
```

---

### ❌ Streaming Responses Not Appearing

**Problem:** UI not updating during streaming.

```swift
// ❌ Wrong - Updates happen on background thread
try await client.streamChat(messages: messages) { chunk in
    label.text += chunk  // ❌ Crashes or doesn't update
}

// ✅ Correct - Update UI on main thread
try await client.streamChat(messages: messages) { chunk in
    Task { @MainActor in
        label.text += chunk  // ✅ Works perfectly
    }
}
```

---

### ❌ Conversations Not Being Saved

**Problem:** Using incognito mode unintentionally.

```swift
// ❌ Wrong - Conversation won't be saved
try await client.initialize(
    options: InitializeOptions(incognitoMode: true)
)

// ✅ Correct - Conversations will be saved
try await client.initialize(
    options: InitializeOptions(incognitoMode: false)  // or omit it
)
```

---

### ❌ Voice Transcription Failing

**Problem:** Unsupported audio format or quality.

```swift
// ✅ Best Practice:
// - Format: WAV (lossless)
// - Sample rate: 16kHz
// - Channels: Mono
// - Bit depth: 16-bit

// Example: Configure AVAudioRecorder correctly
let settings: [String: Any] = [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVSampleRateKey: 16000.0,
    AVNumberOfChannelsKey: 1,
    AVLinearPCMBitDepthKey: 16,
    AVLinearPCMIsFloatKey: false
]
```

---

### ❌ Network Timeout Errors

**Problem:** Requests timing out on slow connections.

```swift
// ✅ Increase timeout for slow networks
let client = Mia21Client(
    apiKey: "...",
    timeout: 90.0  // 90 seconds instead of default 60
)
```

---

## 📄 License

This SDK is released under the **MIT License**. See [LICENSE](LICENSE) for full details.

```
Copyright (c) 2025 Mia21

Permission is hereby granted, free of charge, to use, copy, modify, and distribute
this software for any purpose with or without fee.
```

---

**Built with ❤️ by the Mia21 Team**
