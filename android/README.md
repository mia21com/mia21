# 🤖 Mia21 Android SDK

**Build powerful AI chat experiences in your Android apps with just a few lines of code.**

The official Kotlin SDK for Mia21 AI Chat API - production-ready, fully tested, and designed for real-world apps.

[![Platform](https://img.shields.io/badge/platform-Android%205.0+-green.svg)](https://developer.android.com)
[![Kotlin](https://img.shields.io/badge/Kotlin-1.9+-purple.svg)](https://kotlinlang.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](../LICENSE)

---

## 📦 Table of Contents

- [Quick Start](#-quick-start)
- [Features](#-features)
- [Installation](#-installation)
- [Basic Usage](#-basic-usage)
- [Advanced Features](#-advanced-features)
- [Example Apps](#-example-apps)
- [API Reference](#-api-reference)
- [Troubleshooting](#-troubleshooting)

---

## ⚡ Quick Start

### 1️⃣: Install via Gradle

**In settings.gradle.kts:**
```kotlin
dependencyResolutionManagement {
    repositories {
        maven { url = uri("https://jitpack.io") }
    }
}
```

**In app/build.gradle.kts:**
```kotlin
dependencies {
    implementation("com.github.mia21com:mia21:1.0.0")
}
```

### 2️⃣: Get Your API Key

Sign up at [mia21.com](https://mia21.com/signup) to get your free API key.

### 3️⃣: Initialize and Send a Message

```kotlin
import com.mia21.Mia21Client

// Initialize the client
val client = Mia21Client(apiKey = "YOUR_API_KEY")

// Start a chat session
client.initialize()

// Send a message
val response = client.chat("Hello! How can you help me?")
println(response.message)
```

That's it! You're ready to build. For more examples, see the sections below.

---

## ✨ Features

### 🚀 Core Features
- ✅ **Real-time Streaming** - Word-by-word responses
- ✅ **Kotlin Coroutines** - Modern async patterns
- ✅ **Conversation History** - Persistent chat storage
- ✅ **Voice Input** - Speech-to-text built-in
- ✅ **Multi-Bot** - Switch AI personalities
- ✅ **Spaces** - Organize by context/topic

### 📱 Platform Support
- **Android** 5.0+ (API level 21+)

### 🎨 Framework Support
- **Jetpack Compose** - Modern declarative UI
- **XML Views** - Traditional Android UI
- **Kotlin Flow** - Reactive streaming

---

## 🔧 Installation

### Gradle (Recommended)

**Android Studio:**
1. Open your project in Android Studio
2. Add JitPack to **settings.gradle.kts**:
```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```
3. Add dependency to **app/build.gradle.kts**:
```kotlin
dependencies {
    implementation("com.github.mia21com:mia21:1.0.0")
}
```
4. Sync your project with Gradle files

---

## 📖 Basic Usage

### 1️⃣ Initialize the Client

```kotlin
import com.mia21.Mia21Client
import com.mia21.models.Mia21Environment

val client = Mia21Client(
    apiKey = "your-api-key",
    userId = "user-123",       // Unique user identifier
    environment = Mia21Environment.PRODUCTION  // .PRODUCTION or .STAGING
)
```

> **💡 Pro Tip:** Always use a persistent `userId` in production to maintain conversation history across app sessions.

### 2️⃣ Configure Logging (Optional but Recommended)

```kotlin
// 🔍 Enable detailed logs during development
if (BuildConfig.DEBUG) {
    Mia21Client.setLogLevel(LogLevel.DEBUG)  // See all SDK activity
} else {
    Mia21Client.setLogLevel(LogLevel.ERROR)  // Production: only errors
}
```

**Log Levels:**
- `DEBUG` - Verbose (all operations, requests, responses)
- `INFO` - Important events only
- `ERROR` - Errors only (recommended for production)
- `NONE` - No logging

### 3️⃣ Initialize Chat Session

```kotlin
// ✅ Simple - Start chatting immediately
client.initialize()

// ✅✅ Recommended - With welcome message
val response = client.initialize(
    options = InitializeOptions(
        generateFirstMessage = true  // Bot greets the user
    )
)

response.message?.let { welcome ->
    println("Bot: $welcome")
    // Example: "Hi! I'm here to help. What can I do for you today?"
}

// ✅✅✅ Full Configuration
val response = client.initialize(
    options = InitializeOptions(
        spaceId = "customer_support",    // Organize by context
        botId = "helpful_assistant",     // Specific AI personality
        generateFirstMessage = true,     // Bot greets user
        incognitoMode = false,           // Save conversation (default)
        language = "en",                 // User's language
        userName = "Alex"                // Personalize responses
    )
)
```

> **📝 Note:** Call `initialize()` once when your chat screen appears. You can reuse the same client for multiple messages.

### 4️⃣ Send Messages

**Option A: Non-Streaming (All at once)**
```kotlin
// ✅ Simple - Wait for complete response
val response = client.chat("Tell me a joke")
println(response.message)
// Output: "Why did the chicken cross the road? To get to the other side!"
```

**Option B: Streaming (Real-time, word-by-word)**
```kotlin
// ✅✅ Recommended - See responses as they're typed
val messages = listOf(
    ChatMessage(role = MessageRole.USER, content = "Write a haiku about coding")
)
var botResponse = ""

client.streamChat(messages).collect { chunk ->
    botResponse += chunk
    
    // 🎯 Update UI on main thread
    withContext(Dispatchers.Main) {
        updateTextView(botResponse)
    }
}

// Save complete response to history
messages + ChatMessage(role = MessageRole.ASSISTANT, content = botResponse)
```

**Advanced Streaming with Options:**
```kotlin
client.streamChat(
    messages = messages,
    options = ChatOptions(
        spaceId = "creative_writing",
        temperature = 0.9,      // More creative (0.0 = focused, 2.0 = random)
        maxTokens = 500         // Limit response length
    )
).collect { chunk ->
    print(chunk)  // Print each word as it arrives
}
```

### 5️⃣ Manage Conversation History

**📋 List All Conversations:**
```kotlin
val conversations = client.listConversations(
    spaceId = null,  // null = all spaces, or specify: "customer_support"
    limit = 50       // Default: 50
)

conversations.forEach { conv ->
    println("${conv.displayTitle()} - ${conv.messageCount} messages")
}
// Output:
// "Help with API integration - 12 messages"
// "Bug report discussion - 5 messages"
```

**📖 Load a Specific Conversation:**
```kotlin
val conversation = client.getConversation(conversationId = "conv-123")

// Convert to ChatMessage format
val messages = conversation.messages.map { msg ->
    ChatMessage(
        role = if (msg.role == "user") MessageRole.USER else MessageRole.ASSISTANT,
        content = msg.content
    )
}

println("Loaded ${messages.size} messages")
```

**🔄 Continue an Existing Conversation:**
```kotlin
// Add new user message
val updatedMessages = messages + ChatMessage(role = MessageRole.USER, content = "Tell me more about that")

// Stream response and continue the conversation
client.streamChat(
    messages = updatedMessages,
    options = ChatOptions(
        conversationId = "conv-123"  // ✅ Continue this conversation
    )
).collect { chunk ->
    print(chunk)
}
```

**🗑️ Delete a Conversation:**
```kotlin
client.deleteConversation(conversationId = "conv-123")
println("Conversation deleted")
```

### 6️⃣ Close Session (Important for Resource Management)

```kotlin
// ✅ Close when activity is destroyed
override fun onDestroy() {
    super.onDestroy()
    lifecycleScope.launch {
        client.close()
    }
}

// ✅ Close when user logs out
suspend fun signOut() {
    client.close()
    // Clear user data...
}

// ✅ Jetpack Compose - Close on lifecycle event
DisposableEffect(Unit) {
    onDispose {
        scope.launch { client.close() }
    }
}
```

> **⚠️ Important:** Always close sessions when backgrounding to free resources and prevent memory leaks.

---

## 🚀 Advanced Features

### 🎤 Voice Input (Speech-to-Text)

Turn audio into text automatically:

```kotlin
// 1. Record audio (use MediaRecorder or similar)
val audioFile = getRecordedAudioFile()
val audioData = audioFile.readBytes()

// 2. Transcribe
val result = client.transcribeAudio(
    audioData = audioData,
    language = "en"  // Auto-detects if omitted
)

println("User said: ${result.text}")
// Output: "What's the weather like today?"

// 3. Send transcribed text to chat
val response = client.chat(result.text)
```

**📋 Supported Formats:**
- ✅ **WAV** (recommended) - Best accuracy
- ✅ **M4A** - Common mobile format
- ✅ **MP3** - Compressed audio

**⚙️ Recommended Settings:**
- Sample rate: **16kHz**
- Channels: **Mono**
- Bit depth: **16-bit**

### 🏠 Spaces - Organize Conversations by Context

Spaces let you organize chats by topic, use case, or customer:

```kotlin
// 1️⃣ List available spaces
val spaces = client.listSpaces()

spaces.forEach { space ->
    println("${space.name} - ${space.spaceId}")
}
// Output:
// "Customer Support - support_space"
// "Sales Inquiries - sales_space"
// "Technical Help - tech_space"

// 2️⃣ Start chat in specific space
client.initialize(
    options = InitializeOptions(spaceId = "support_space")
)

// 3️⃣ Switch spaces (close current, open new)
client.close()
client.initialize(
    options = InitializeOptions(spaceId = "sales_space")
)
```

### 🤖 Multi-Bot Support - Different AI Personalities

Switch between different AI personalities/assistants:

```kotlin
// 1️⃣ List available bots
val bots = client.listBots()

bots.forEach { bot ->
    println("${bot.name} - ${bot.description ?: ""}")
    if (bot.isDefault) {
        println("  ⭐ Default bot")
    }
}
// Output:
// "Customer Support Bot - Friendly and helpful"
//   ⭐ Default bot
// "Technical Expert - Detailed technical answers"
// "Sales Assistant - Product recommendations"

// 2️⃣ Use specific bot for a conversation
client.streamChat(
    messages = messages,
    options = ChatOptions(botId = "technical_expert")
).collect { chunk ->
    print(chunk)
}

// 3️⃣ Switch bots mid-conversation
val newMessages = messages + ChatMessage(role = MessageRole.USER, content = "Now explain technically")

client.streamChat(
    messages = newMessages,
    options = ChatOptions(botId = "technical_expert")
).collect { chunk ->
    // Different bot, different personality
}
```

---

## 🛡️ Error Handling

```kotlin
try {
    val response = client.chat("Hello")
    println(response.message)
    
} catch (e: Mia21Exception.ChatNotInitializedException) {
    // Need to call initialize() first
    println("Please initialize the chat session")
    
} catch (e: Mia21Exception.ApiException) {
    // Server-side error
    println("API error: ${e.message}")
    
} catch (e: Mia21Exception.NetworkException) {
    // Network connectivity issue
    println("Network error: ${e.message}")
    
} catch (e: Exception) {
    // Unknown error
    println("Unexpected error: ${e.message}")
}
```

---

## 📱 Example Apps (Production-Ready Code)

The example app is a **fully functional**, **production-ready** app you can learn from or use as a starting point:

### 🎨 Jetpack Compose Example (`example-app/`)

**Features:**
- ✅ Modern MVVM architecture
- ✅ Real-time streaming with smooth animations
- ✅ Conversation history with persistence
- ✅ Voice input (hands-free mode with VAD)
- ✅ Space and bot switcher
- ✅ Dark mode support
- ✅ Markdown rendering in messages
- ✅ Background session management
- ✅ Swipe-to-delete

**Perfect for:** New projects, declarative UI fans

---

### 🚀 Run the Example:

```bash
# 1. Clone the repository
git clone https://github.com/mia21com/mia21.git
cd mia21/android/example-app

# 2. Open in Android Studio
# File → Open → Select `example-app` folder

# 3. Wait for Gradle sync
# 4. Build and run (▶️)
```

> **💡 Tip:** The example app demonstrates best practices for production apps including error handling, background sessions, and memory management.

---

## 📊 API Reference

### Mia21Client

| Method | Description | Returns |
|--------|-------------|---------|
| `initialize(options)` | Start chat session | `InitializeResponse` |
| `chat(message, options)` | Send message (non-streaming) | `ChatResponse` |
| `streamChat(messages, options)` | Send message (streaming) | `Flow<String>` |
| `streamChatWithVoice(messages, options, voiceConfig)` | Stream with voice output | `Flow<StreamEvent>` |
| `listSpaces()` | Get all spaces | `List<Space>` |
| `listBots()` | Get all bots | `List<Bot>` |
| `listConversations(spaceId, limit)` | Get conversation history | `List<ConversationSummary>` |
| `getConversation(conversationId)` | Get full conversation | `Conversation` |
| `deleteConversation(conversationId)` | Delete conversation | `DeleteConversationResponse` |
| `transcribeAudio(audioData, language)` | Speech-to-text | `TranscriptionResponse` |
| `close(spaceId)` | Close session | `Unit` |

### Configuration Types

**InitializeOptions:**
- `spaceId: String?` - Space identifier
- `botId: String?` - Bot identifier
- `llmType: LLMType?` - `OPENAI` or `GEMINI`
- `userName: String?` - User's display name
- `language: String?` - Language code (e.g., "en")
- `generateFirstMessage: Boolean` - Bot greets user
- `incognitoMode: Boolean` - Don't save conversation
- `spaceConfig: SpaceConfig?` - Custom space config

**ChatOptions:**
- `spaceId: String?` - Override space
- `botId: String?` - Override bot
- `conversationId: String?` - Continue conversation
- `temperature: Double?` - LLM temperature (0.0-2.0)
- `maxTokens: Int?` - Max response length
- `llmType: LLMType?` - Override LLM

---

## 🔍 Troubleshooting

### ❌ Error: "Chat not initialized"

**Problem:** Trying to send messages before initializing the session.

```kotlin
// ❌ Wrong
val client = Mia21Client(apiKey = "...")
client.chat("Hello")  // ❌ Throws exception!

// ✅ Correct
val client = Mia21Client(apiKey = "...")
client.initialize()  // ✅ Initialize first
client.chat("Hello")  // ✅ Now works
```

---

### ❌ Streaming Responses Not Appearing

**Problem:** UI not updating during streaming.

```kotlin
// ❌ Wrong - Updates happen on background thread
client.streamChat(messages).collect { chunk ->
    textView.text += chunk  // ❌ Crashes or doesn't update
}

// ✅ Correct - Update UI on main thread
client.streamChat(messages).collect { chunk ->
    withContext(Dispatchers.Main) {
        textView.text += chunk  // ✅ Works perfectly
    }
}
```

---

### ❌ Conversations Not Being Saved

**Problem:** Using incognito mode unintentionally.

```kotlin
// ❌ Wrong - Conversation won't be saved
client.initialize(
    options = InitializeOptions(incognitoMode = true)
)

// ✅ Correct - Conversations will be saved
client.initialize(
    options = InitializeOptions(incognitoMode = false)  // or omit it
)
```

---

### ❌ Voice Transcription Failing

**Problem:** Unsupported audio format or quality.

```kotlin
// ✅ Best Practice:
// - Format: WAV (lossless)
// - Sample rate: 16kHz
// - Channels: Mono
// - Bit depth: 16-bit

// Example: Configure MediaRecorder correctly
val recorder = MediaRecorder().apply {
    setAudioSource(MediaRecorder.AudioSource.MIC)
    setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
    setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
    setAudioSamplingRate(16000)
    setAudioChannels(1)
}
```

---

### ❌ Network Timeout Errors

**Problem:** Requests timing out on slow connections.

```kotlin
// ✅ Increase timeout for slow networks
val client = Mia21Client(
    apiKey = "...",
    timeout = 90_000L  // 90 seconds instead of default 60
)
```

---

## 📄 License

This SDK is released under the **MIT License**. See [LICENSE](../LICENSE) for full details.

```
Copyright (c) 2025 Mia21

Permission is hereby granted, free of charge, to use, copy, modify, and distribute
this software for any purpose with or without fee.
```

---

**Built with ❤️ by the Mia21 Team**
