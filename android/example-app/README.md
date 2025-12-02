# 📱 Mia21 Android Example App

A production-ready Jetpack Compose chat app demonstrating how to use the Mia21 SDK.

## ✨ Features Demonstrated

- ✅ **SDK Initialization** - Setting up the Mia21 client
- ✅ **Chat UI** - Modern message bubbles with Jetpack Compose
- ✅ **Real-time Streaming** - Word-by-word response display
- ✅ **Voice Input** - Speech-to-text transcription
- ✅ **Voice Output** - Text-to-speech with ElevenLabs
- ✅ **Conversation History** - Load and continue past chats
- ✅ **Multi-Space/Bot** - Switch between spaces and bots
- ✅ **Side Menu** - Navigation with swipe-to-delete
- ✅ **Error Handling** - Proper error messages and states
- ✅ **Material Design 3** - Modern, clean UI

## 📋 Prerequisites

- **Android Studio** Hedgehog or later
- **JDK 17** or higher
- **Android SDK** with API 21+ (Android 5.0+)
- **Mia21 API Key** from [mia21.com](https://mia21.com)

## 🚀 How to Build and Run

### Option 1: Open in Android Studio (Recommended)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/mia21com/mia21.git
   cd mia21/android/example-app
   ```

2. **Open in Android Studio:**
   - File → Open → Select `example-app` folder
   - Or run: `open -a "Android Studio" .`

3. **Wait for Gradle sync** (first time takes a few minutes)

4. **Run the app:**
   - Click the green ▶️ "Run" button
   - Or press `Ctrl+R` (Mac: `⌘+R`)
   - Select an emulator or connected device

5. **Enter your API key** and start chatting!

### Option 2: Command Line Build

```bash
cd mia21/android/example-app

# Build the app
./gradlew build

# Install on connected device/emulator
./gradlew installDebug
```

## 📖 How to Use the App

1. **Launch**: The app initializes automatically with a welcome message
2. **Chat**: Type a message and tap send
3. **Voice Input**: Tap the microphone to record, tap again to transcribe
4. **Voice Output**: Enable voice mode for spoken responses
5. **Side Menu**: Swipe from left or tap menu icon
   - Switch spaces and bots
   - View conversation history
   - Start new chats
   - Swipe left on conversations to delete

## 🎯 Code Structure

```
example-app/
├── app/
│   ├── build.gradle.kts
│   └── src/main/
│       ├── AndroidManifest.xml
│       └── java/com/mia21/example/
│           ├── MainActivity.kt           # Entry point
│           ├── theme/
│           │   └── Theme.kt              # Material 3 theming
│           ├── ui/
│           │   ├── MiaApp.kt             # Main app composable
│           │   ├── ChatView.kt           # Chat screen
│           │   ├── ChatInputView.kt      # Input field + buttons
│           │   ├── MessageBubble.kt      # Message display
│           │   ├── SideMenuView.kt       # Navigation drawer
│           │   ├── LoadingView.kt        # Loading screen
│           │   └── TypewriterText.kt     # Animated text
│           ├── viewmodels/
│           │   ├── ChatViewModel.kt      # Chat logic
│           │   ├── LoadingViewModel.kt   # Init logic
│           │   └── SideMenuViewModel.kt  # Menu logic
│           └── utils/
│               ├── AudioPlaybackManager.kt   # Voice output
│               ├── AudioRecorderManager.kt   # Voice input
│               ├── HandsFreeAudioManager.kt  # Hands-free mode
│               ├── Constants.kt              # App constants
│               └── UserPreferences.kt        # Settings storage
├── build.gradle.kts
└── settings.gradle.kts
```

## 🔧 Key Code Examples

### Initialize SDK
```kotlin
val client = Mia21Client(
    apiKey = "your-api-key",
    userId = "android-example-user"
)

val response = client.initialize(
    options = InitializeOptions(
        generateFirstMessage = true,
        language = "en"
    )
)
```

### Send Message with Streaming
```kotlin
val messages = listOf(
    ChatMessage(role = MessageRole.USER, content = "Tell me a joke")
)

client.streamChat(messages).collect { chunk ->
    // Update UI with each word
    botResponse += chunk
}
```

### Voice Output with ElevenLabs
```kotlin
val voiceConfig = VoiceConfig(
    enabled = true,
    voiceId = "21m00Tcm4TlvDq8ikWAM",
    stability = 0.5,
    similarityBoost = 0.75
)

client.streamChatWithVoice(messages, options, voiceConfig).collect { event ->
    when (event) {
        is StreamEvent.Text -> updateText(event.content)
        is StreamEvent.Audio -> playAudio(event.audioData)
        is StreamEvent.Done -> onComplete()
    }
}
```

## 🐛 Troubleshooting

### Build Fails

**Issue**: Gradle sync fails
**Solution**: Make sure you have JDK 17 installed
```bash
java -version  # Should show version 17 or higher
```

**Issue**: SDK not found
**Solution**: The example uses the local SDK module. Make sure you're running from the correct directory.

### Runtime Issues

**Issue**: Network error
**Solution**: 
- Check internet connection
- Verify API key is correct
- Make sure `INTERNET` permission is in AndroidManifest.xml

**Issue**: App crashes on launch
**Solution**: Check logcat in Android Studio for error messages

## 📝 Modifying the Example

### Use JitPack Instead of Local SDK

Edit `app/build.gradle.kts`:
```kotlin
dependencies {
    // Comment out local module:
    // implementation(project(":mia21-sdk"))
    
    // Use JitPack instead:
    implementation("com.github.mia21com:mia21:1.0.0")
}
```

And remove from `settings.gradle.kts`:
```kotlin
// Remove these lines:
// include(":mia21-sdk")
// project(":mia21-sdk").projectDir = file("../lib")
```

## 📚 Learn More

- [Android SDK Documentation](../README.md)
- [Mia21 API Documentation](https://docs.mia21.com)
- [Full iOS & Android SDK](../../README.md)

## 📄 License

MIT License - Same as the parent SDK
