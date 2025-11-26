# Mia21 SDK Example Apps

Two complete example apps demonstrating how to integrate and use the Mia21 iOS SDK.

## 📱 Example Apps

### 1. SwiftUI Example (`MiaSwiftUIExample.xcodeproj`)

Modern chat interface built with SwiftUI featuring:
- ✅ Chat interface with message bubbles
- ✅ Real-time streaming responses
- ✅ Loading states and error handling
- ✅ MVVM architecture
- ✅ Auto-scroll to latest message
- ✅ Imports SDK via local SPM

**Files:**
- `MiaSwiftUIExample/MiaSwiftUIExampleApp.swift` - App entry point
- `MiaSwiftUIExample/ChatView.swift` - Complete chat implementation

### 2. UIKit Example (`MiaUIKitExample.xcodeproj`)

Traditional chat interface built with UIKit featuring:
- ✅ UITableView with custom message cells
- ✅ Message bubbles with dynamic sizing
- ✅ Real-time streaming support
- ✅ Keyboard handling
- ✅ Activity indicators
- ✅ Imports SDK via local SPM

**Files:**
- `MiaUIKitExample/AppDelegate.swift` - App entry point
- `MiaUIKitExample/ChatViewController.swift` - Complete chat implementation

## 🚀 How to Run

### SwiftUI Example:
```bash
cd Examples
open MiaSwiftUIExample.xcodeproj
```

Update the API key in `MiaSwiftUIExample/ChatView.swift` (line 122):
```swift
private let client = Mia21Client(apiKey: "your-api-key-here")
```

### UIKit Example:
```bash
cd Examples
open MiaUIKitExample.xcodeproj
```

Update the API key in `MiaUIKitExample/ChatViewController.swift` (line 9):
```swift
private let client = Mia21Client(apiKey: "your-api-key-here")
```

Then select a simulator or device and press `Cmd + R` to run.

## ⚙️ Requirements

- Xcode 14.0+
- iOS 15.0+
- Mia21 API key (get one at https://mia21.com)

## 📦 SDK Integration

Both example apps import the Mia21 SDK via **local Swift Package Manager**:

```
Resolved source packages:
  Mia21: /Users/admin/Mia21SDK-iOS @ local
```

This demonstrates how to integrate the SDK into your own projects:
1. File → Add Packages in Xcode
2. Click "Add Local..."
3. Select the `Mia21SDK-iOS` folder
4. Import with `import Mia21`

## 📖 Features Demonstrated

### Common Features (Both Apps)
- ✅ Initialize chat with `client.initialize()`
- ✅ Send messages with streaming responses
- ✅ Handle errors gracefully
- ✅ Display loading states
- ✅ Message history with user/AI distinction

### SwiftUI-Specific
- `@StateObject` for view model management
- SwiftUI state management
- Declarative UI updates
- `Task` for async operations

### UIKit-Specific
- UITableView with custom cells
- Programmatic UI layout
- Keyboard notifications
- Traditional delegate patterns

## 🔧 Customization

You can use these examples as templates for your own apps:

1. **Copy the relevant files** (`ChatView.swift` or `ChatViewController.swift`)
2. **Update the UI** to match your app's design
3. **Add your API key**
4. **Integrate** into your app's navigation

## 📚 Learn More

- [SDK Documentation](../README.md)
- [Mia21 API Docs](https://docs.mia21.com)
- [Get API Key](https://mia21.com)

---

**Need help?** Open an issue or contact hello@mia21.com
