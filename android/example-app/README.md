# 📱 Mia21 Android Example App

A clean, simple Android chat app demonstrating how to use the Mia21 SDK.

## ✨ Features Demonstrated

- ✅ **SDK Initialization** - Setting up the Mia21 client
- ✅ **Chat UI** - Message bubbles with user/bot styling
- ✅ **Send Messages** - Text-based chat
- ✅ **Streaming Responses** - Real-time word-by-word display
- ✅ **Typing Indicators** - Shows when bot is responding
- ✅ **Error Handling** - Proper error messages
- ✅ **Material Design** - Clean, modern UI

## 📋 Prerequisites

- **Android Studio** Hedgehog or later
- **JDK 17** or higher
- **Android SDK** with API 21+ (Android 5.0+)
- **Mia21 API Key** from [mia21.com](https://mia21.com)

## 🚀 How to Build and Run

### Option 1: Open in Android Studio (Recommended)

1. **Open the project:**
   ```bash
   # Navigate to the example app
   cd /Users/admin/mia-my-folder/android/example-app
   
   # Open in Android Studio
   open -a "Android Studio" .
   ```
   Or: File → Open → Select `example-app` folder

2. **Wait for Gradle sync** (first time takes a few minutes)

3. **Run the app:**
   - Click the green ▶️ "Run" button
   - Or press `Ctrl+R` (Mac: `⌘+R`)
   - Select an emulator or connected device

4. **Enter your API key** and start chatting!

### Option 2: Command Line Build

```bash
cd /Users/admin/mia-my-folder/android/example-app

# Build the app
./gradlew build

# Install on connected device/emulator
./gradlew installDebug

# Or build and install in one command
./gradlew installDebug
```

## 📖 How to Use the App

1. **Enter API Key**: Paste your Mia21 API key in the first field
2. **Initialize**: Click "Initialize Chat" button
3. **Send Message**: 
   - Type a message in the text field
   - Click "Send" for instant response
   - Click "Stream" for word-by-word response
4. **View Response**: See the bot's reply in the response area

## 🎯 Code Structure

```
example-app/
├── app/
│   ├── build.gradle.kts          # App dependencies
│   └── src/main/
│       ├── AndroidManifest.xml   # App configuration
│       ├── java/com/mia21/example/
│       │   └── MainActivity.kt   # Main app logic
│       └── res/
│           ├── layout/
│           │   └── activity_main.xml  # UI layout
│           └── values/
│               └── strings.xml   # App strings
├── build.gradle.kts              # Project-level config
└── settings.gradle.kts           # Module configuration
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

### Send Message
```kotlin
val response = client.chat("Hello!")
println(response.message)
```

### Stream Response
```kotlin
val messages = listOf(
    ChatMessage(role = MessageRole.USER, content = "Tell me a joke")
)

client.streamChat(messages).collect { chunk ->
    print(chunk)  // Display each word as it arrives
}
```

## 📱 Screenshots

The app provides a simple interface with:
- API key input field
- Message input area
- Send and Stream buttons
- Response display area
- Loading indicator

## 🐛 Troubleshooting

### Build Fails

**Issue**: Gradle sync fails
**Solution**: Make sure you have JDK 17 installed
```bash
java -version  # Should show version 17 or higher
```

**Issue**: SDK not found
**Solution**: The example uses the local SDK module. Make sure you're running from the `example-app` directory.

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
    implementation("com.github.nataliakozlovska:mia:v1.0.0")
}
```

And remove from `settings.gradle.kts`:
```kotlin
// Remove these lines:
// include(":mia21-sdk")
// project(":mia21-sdk").projectDir = file("../lib")
```

### Add More Features

Check the [Android SDK documentation](../README.md) for more features:
- Voice transcription
- Multi-bot support
- Conversation history
- Spaces management

## 📚 Learn More

- [Android SDK Documentation](../README.md)
- [Mia21 API Documentation](https://docs.mia21.com)
- [Full iOS & Android SDK](../../README.md)

## 📄 License

MIT License - Same as the parent SDK

