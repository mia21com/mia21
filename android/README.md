# 🤖 Mia21 Android SDK

**Build powerful AI chat experiences in your Android apps with just a few lines of code.**

The official Kotlin SDK for Mia21 AI Chat API - designed for modern Android development with Kotlin coroutines and Flow.

[![Platform](https://img.shields.io/badge/platform-Android%205.0+-green.svg)](https://developer.android.com)
[![Kotlin](https://img.shields.io/badge/Kotlin-1.9+-purple.svg)](https://kotlinlang.org)
[![JitPack](https://img.shields.io/badge/JitPack-ready-brightgreen.svg)](https://jitpack.io)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](../LICENSE)

---

## ⚡ Quick Start

### 1️⃣: Add JitPack Repository

**In settings.gradle.kts (or project-level build.gradle.kts):**
```kotlin
repositories {
    maven { url = uri("https://jitpack.io") }
}
```

### 2️⃣: Add Dependency

**In app/build.gradle.kts:**
```kotlin
dependencies {
    implementation("com.github.nataliakozlovska:mia:1.0.0")
}
```

### 3️⃣: Get Your API Key

Sign up at [mia21.com](https://mia21.com/signup) to get your free API key.

### 4️⃣: Initialize and Send a Message

```kotlin
import com.mia21.Mia21Client
import com.mia21.models.*

// Initialize the client
val client = Mia21Client(apiKey = "YOUR_API_KEY")

// Start a chat session
val initResponse = client.initialize()

// Send a message
val response = client.chat("Hello! How can you help me?")
println(response.message)
```

That's it! You're ready to build.

---

## ✨ Features

### 🚀 Core Features
- ✅ **Real-time Streaming** - Word-by-word responses with Kotlin Flow
- ✅ **Kotlin Coroutines** - Modern async/await patterns
- ✅ **Conversation History** - Persistent chat storage
- ✅ **Voice Input** - Speech-to-text built-in
- ✅ **Multi-Bot** - Switch AI personalities
- ✅ **Spaces** - Organize by context/topic
- ✅ **BYOK** - Use your own LLM keys

### 📱 Platform Support
- **Android** 5.0+ (API level 21+)
- **JVM** compatible for backend use

### 🎨 Framework Support
- **Jetpack Compose** - Modern declarative UI (examples coming soon)
- **XML Views** - Traditional Android UI
- **Kotlin Flow** - Reactive streaming

---

## 📖 Basic Usage

### 1️⃣ Initialize the Client

```kotlin
import com.mia21.Mia21Client
import com.mia21.models.Mia21Environment

val client = Mia21Client(
    apiKey = "your-api-key",
    userId = "user-123",       // Unique user identifier
    environment = Mia21Environment.PRODUCTION
)
```

> **💡 Pro Tip:** Always use a persistent `userId` in production to maintain conversation history across app sessions.

### 2️⃣ Configure Logging (Optional but Recommended)

```kotlin
// Enable detailed logs during development
Mia21Client.setLogLevel(LogLevel.DEBUG)  // See all SDK activity

// Production: only errors
Mia21Client.setLogLevel(LogLevel.ERROR)
```

**Log Levels:**
- `DEBUG` - Verbose (all operations, requests, responses)
- `INFO` - Important events only
- `ERROR` - Errors only (recommended for production)
- `NONE` - No logging

### 3️⃣ Initialize Chat Session

```kotlin
import com.mia21.models.InitializeOptions

// Simple - Start chatting immediately
val response = client.initialize()

// With welcome message
val response = client.initialize(
    options = InitializeOptions(
        generateFirstMessage = true  // Bot greets the user
    )
)

response.message?.let { welcome ->
    println("Bot: $welcome")
}

// Full Configuration
val response = client.initialize(
    options = InitializeOptions(
        spaceId = "customer_support",
        botId = "helpful_assistant",
        generateFirstMessage = true,
        incognitoMode = false,
        language = "en",
        userName = "Alex"
    )
)
```

### 4️⃣ Send Messages

**Option A: Non-Streaming (All at once)**
```kotlin
// Simple - Wait for complete response
val response = client.chat("Tell me a joke")
println(response.message)
```

**Option B: Streaming (Real-time, word-by-word)**
```kotlin
import kotlinx.coroutines.flow.collect

// See responses as they're typed
val messages = listOf(
    ChatMessage(role = MessageRole.USER, content = "Write a haiku about coding")
)

var botResponse = ""

client.streamChat(messages).collect { chunk ->
    botResponse += chunk
    // Update UI with botResponse
    println(chunk, terminator = "")
}
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
    spaceId = null,  // null = all spaces
    limit = 50       // Default: 50
)

conversations.forEach { conv ->
    println("${conv.displayTitle("Space Name", "Bot Name")} - ${conv.messageCount} messages")
}
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

**🗑️ Delete a Conversation:**
```kotlin
val response = client.deleteConversation(conversationId = "conv-123")
println(response.message)
```

### 6️⃣ Close Session

```kotlin
// Close when activity is destroyed
override fun onDestroy() {
    super.onDestroy()
    lifecycleScope.launch {
        client.close()
    }
}
```

---

## 🚀 Advanced Features

### 🎤 Voice Input (Speech-to-Text)

```kotlin
// 1. Record audio (use MediaRecorder or similar)
val audioFile = File("recording.wav")
val audioData = audioFile.readBytes()

// 2. Transcribe
val result = client.transcribeAudio(
    audioData = audioData,
    language = "en"  // Auto-detects if omitted
)

println("User said: ${result.text}")

// 3. Send transcribed text to chat
val response = client.chat(result.text)
```

### 🏠 Spaces - Organize Conversations by Context

```kotlin
// List available spaces
val spaces = client.listSpaces()

spaces.forEach { space ->
    println("${space.name} - ${space.spaceId}")
}

// Start chat in specific space
client.initialize(
    options = InitializeOptions(spaceId = "support_space")
)
```

### 🤖 Multi-Bot Support - Different AI Personalities

```kotlin
// List available bots
val bots = client.listBots()

bots.forEach { bot ->
    println("${bot.name} - ${bot.llmIdentifier}")
    if (bot.isDefault) println("  ⭐ Default bot")
}

// Use specific bot
client.streamChat(
    messages = messages,
    options = ChatOptions(botId = "technical_expert")
).collect { chunk -> print(chunk) }
```

### 🔑 BYOK (Bring Your Own Key)

```kotlin
// Initialize with your LLM key
val client = Mia21Client(
    customerLlmKey = "sk-proj-..."  // Your OpenAI or Gemini key
)

// Specify which LLM to use
client.initialize(
    options = InitializeOptions(
        llmType = LLMType.OPENAI,
        generateFirstMessage = true
    )
)

// All requests now bill directly to YOUR account
```

---

## 🛡️ Error Handling

```kotlin
import com.mia21.models.Mia21Exception

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

## 📊 API Reference

### Mia21Client

| Method | Description | Returns |
|--------|-------------|---------|
| `initialize(options)` | Start chat session | `InitializeResponse` |
| `chat(message, options)` | Send message (non-streaming) | `ChatResponse` |
| `streamChat(messages, options)` | Send message (streaming) | `Flow<String>` |
| `listSpaces()` | Get all spaces | `List<Space>` |
| `listBots()` | Get all bots | `List<Bot>` |
| `listConversations(spaceId, limit)` | Get conversation history | `List<ConversationSummary>` |
| `getConversation(conversationId)` | Get full conversation | `ConversationDetail` |
| `deleteConversation(conversationId)` | Delete conversation | `DeleteConversationResponse` |
| `transcribeAudio(audioData, language)` | Speech-to-text | `TranscriptionResponse` |
| `close(spaceId)` | Close session | `Unit` |

---

## 🔨 Building from Source

```bash
cd android
./gradlew build
./gradlew test
```

---

## 📄 License

This SDK is released under the **MIT License**. See [LICENSE](../LICENSE) for full details.

---

**Built with ❤️ by the Mia21 Team**
