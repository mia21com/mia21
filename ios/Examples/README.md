# Mia21 SDK Example Apps

Two complete example apps demonstrating how to integrate and use the Mia21 iOS SDK.

## 📱 Example Apps

### 1. SwiftUI Example (`MiaSwiftUIExample.xcodeproj`)

Modern chat interface built with SwiftUI featuring:
- ✅ Chat interface with message bubbles
- ✅ Real-time streaming responses
- ✅ Voice input (hands-free mode with VAD)
- ✅ Conversation history
- ✅ Space and bot switcher
- ✅ Side menu navigation
- ✅ MVVM architecture
- ✅ Dark mode support

**Key Files:**
- `MiaSwiftUIExample/MiaSwiftUIExampleApp.swift` - App entry point
- `MiaSwiftUIExample/Views/Chat/ChatView.swift` - Main chat interface
- `MiaSwiftUIExample/ViewModels/ChatViewModel/` - Chat logic

### 2. UIKit Example (`MiaUIKitExample.xcodeproj`)

Traditional chat interface built with UIKit featuring:
- ✅ UITableView with custom message cells
- ✅ Real-time streaming support
- ✅ Voice input and playback
- ✅ Conversation history
- ✅ Side menu navigation
- ✅ Programmatic UI (no storyboards)

**Key Files:**
- `MiaUIKitExample/App/SceneDelegate.swift` - App entry point
- `MiaUIKitExample/Screens/Chat/Controllers/ChatViewController.swift` - Main chat controller
- `MiaUIKitExample/Screens/Chat/ViewModels/ChatViewModel.swift` - Chat logic

## 🚀 How to Run

### SwiftUI Example:
```bash
cd Examples
open MiaSwiftUIExample.xcodeproj
```

Update the API key in `MiaSwiftUIExample/MiaSwiftUIExampleApp.swift`.

### UIKit Example:
```bash
cd Examples
open MiaUIKitExample.xcodeproj
```

Update the API key in `MiaUIKitExample/App/SceneDelegate.swift`.

Then select a simulator or device and press `Cmd + R` to run.

## ⚙️ Requirements

- Xcode 14.0+
- iOS 15.0+
- Mia21 API key (get one at https://mia21.com)

## 📦 SDK Integration

Both example apps import the Mia21 SDK via **local Swift Package Manager**:

1. File → Add Packages in Xcode
2. Click "Add Local..."
3. Select the SDK folder
4. Import with `import Mia21`

## 📖 Features Demonstrated

### Common Features (Both Apps)
- ✅ Initialize chat with `client.initialize()`
- ✅ Send messages with streaming responses
- ✅ Voice input (speech-to-text)
- ✅ Conversation management
- ✅ Space and bot switching
- ✅ Error handling

### SwiftUI-Specific
- `@StateObject` for view model management
- SwiftUI state management with `@State` and `@Binding`
- Declarative UI with smooth animations
- `Task` for async operations

### UIKit-Specific
- UITableView with custom cells
- Programmatic UI layout
- Combine for reactive updates
- Traditional delegate patterns

## 🔧 Customization

You can use these examples as templates for your own apps:

1. **Copy the relevant files** to your project
2. **Update the UI** to match your app's design
3. **Add your API key**
4. **Integrate** into your app's navigation

## 📚 Learn More

- [iOS SDK Documentation](../README.md)
- [Full SDK Documentation](../../README.md)

---

**Need help?** Open an issue or contact hello@mia21.com
