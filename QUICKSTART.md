# ⚡ QUICK START - Get Running in 10 Minutes!

Follow these steps exactly to get the Pinterest Clone running.

---

## Step 1: Add GRDB Dependency (3 minutes)

### In Xcode:

1. **Open the project**

   ```bash
   cd /Users/realwat2007/Introduction-To-Swift/pinterest_clone
   open pinterest_clone.xcodeproj
   ```

2. **Add GRDB package:**

   - Click on `pinterest_clone` project in navigator (top blue icon)
   - Select `pinterest_clone` target
   - Click on **"Package Dependencies"** tab at the top
   - Click the **"+"** button at the bottom
   - In the search field, enter:
     ```
     https://github.com/groue/GRDB.swift.git
     ```
   - Click **"Add Package"**
   - Select version **"6.24.0 or later"**
   - Click **"Add Package"** again
   - Select **"GRDB"** library
   - Click **"Add Package"** one more time

3. **Verify:**
   - You should see "GRDB" in the Package Dependencies list

---

## Step 2: Add Import Statements (2 minutes)

The code files need GRDB imported. Add `import GRDB` to these files:

```swift
// Add at top of these files after "import Foundation":
import GRDB
```

**Files that need it:**

1. `pinterest_clone/Database/DatabaseManager.swift`
2. `pinterest_clone/Models/Database/User.swift`
3. `pinterest_clone/Models/Database/Board.swift`
4. `pinterest_clone/Models/Database/Pin.swift`
5. `pinterest_clone/Models/Database/Comment.swift`
6. `pinterest_clone/Repositories/PinRepository.swift`
7. `pinterest_clone/Repositories/BoardRepository.swift`

---

## Step 3: Fix Compilation Errors (2 minutes)

### Add missing imports:

1. **In `pinterest_cloneApp.swift`**, add at top:

   ```swift
   import Foundation
   ```

2. **In `PinGridView.swift`**, ensure imports:

   ```swift
   import SwiftUI
   import Combine
   ```

3. **In all files**, make sure `NSImage` is imported from AppKit:
   ```swift
   import AppKit
   ```

---

## Step 4: Update ContentView (1 minute)

The old `ContentView.swift` references `HomeView()` which we replaced. Update it:

```swift
//
//  ContentView.swift
//  pinterest_clone
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainView()
            .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
```

---

## Step 5: Build Project (1 minute)

1. Press **⌘B** (Command + B) to build
2. Fix any remaining errors (see Troubleshooting below)
3. Build should succeed

---

## Step 6: Run Project (1 minute)

1. Press **⌘R** (Command + R) to run
2. App window should open
3. Check Xcode Console for initialization messages:

```
🚀 Pinterest Clone Starting...
📦 Registered: DatabaseManager [singleton]
✅ Database initialized at: ~/Library/Application Support/PinterestClone/pinterest.sqlite
✅ Sample data seeded successfully
✅ Built-in plugins registered
✅ Pinterest Clone Initialized
```

---

## Step 7: Verify It Works

### Check the UI:

- ✅ Sidebar with navigation
- ✅ Pin grid showing sample pins
- ✅ Search bar at top
- ✅ Click on pin to see details

### Try Features:

1. **Search**: Type "design" in search bar
2. **Click Pin**: Click any pin card to see details
3. **Navigate**: Click sidebar items

---

## 🐛 Troubleshooting

### Problem 1: "Module 'GRDB' not found"

**Solution:**

```bash
1. File > Add Package Dependencies
2. Enter: https://github.com/groue/GRDB.swift.git
3. Add package and select GRDB library
```

### Problem 2: Compilation Errors

**Solution:**

```bash
1. Clean build folder: Shift + ⌘K
2. Quit Xcode completely
3. Reopen project
4. Build again: ⌘B
```

### Problem 3: Missing Type Errors

**Common Missing Types:**

```swift
// Add these imports as needed:
import Foundation  // For Data, Date, etc.
import SwiftUI     // For View, etc.
import GRDB        // For database
import AppKit      // For NSImage, NSColor
import Combine     // For @Published
```

### Problem 4: Database Not Creating

**Check:**

```bash
# Database should be at:
~/Library/Application Support/PinterestClone/pinterest.sqlite

# If missing, app will create it on first run
```

### Problem 5: Plugins Not Loading

**Check Console:**

```
Should see:
✅ Built-in plugins registered
✅ Plugin enabled: Vintage Filter
```

---

## 📋 Quick Fixes for Common Errors

### Error: "Cannot find type 'Pin' in scope"

**Fix:** Ensure all model files are in target:

1. Select file in navigator
2. Check "Target Membership" in File Inspector
3. Ensure "pinterest_clone" is checked

### Error: "Use of unresolved identifier 'Container'"

**Fix:** Add to file:

```swift
// Make sure Container.swift is in target
// And file imports Foundation
```

### Error: "Value of type 'Pin' has no member 'samples'"

**Fix:** Ensure the extension in `Pin.swift` is present:

```swift
extension Pin {
    static var samples: [Pin] { [...] }
}
```

---

## ✅ Success Checklist

- [ ] GRDB package added
- [ ] Project builds without errors (⌘B)
- [ ] App runs and window opens (⌘R)
- [ ] Console shows initialization messages
- [ ] UI shows pin grid
- [ ] Search works
- [ ] Clicking pins shows details

---

## 🎉 You're Done!

If all checklist items are ✅, you're ready to learn!

**Next Steps:**

1. Read [LEARNING_GUIDE.md](LEARNING_GUIDE.md)
2. Explore the code
3. Try the exercises
4. Build new features!

---

## 💡 Pro Tips

### Xcode Shortcuts:

- **⌘B** - Build
- **⌘R** - Run
- **Shift+⌘K** - Clean Build Folder
- **⌘/** - Comment/Uncomment
- **⌥ Click** - Show Quick Help

### Debugging:

- **⌘\\** - Add/Remove Breakpoint
- **⌘Y** - Toggle Breakpoints
- **F6** - Step Over
- **F7** - Step Into

### Console:

- View → Debug Area → Show Debug Area
- Watch for our custom log messages (emoji prefixes)

---

## 📞 Still Having Issues?

1. Check [SETUP.md](SETUP.md) for detailed instructions
2. Review error messages carefully
3. Ensure Xcode 15.0+ and macOS 14.0+
4. Try creating a new clean build

---

<div align="center">

**Ready to learn advanced Swift?**

[Start with the Learning Guide →](LEARNING_GUIDE.md)

</div>
