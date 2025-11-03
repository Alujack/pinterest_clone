# Setup Instructions

## Adding GRDB Dependency

Since this project uses Xcode project format, follow these steps to add GRDB:

### Option 1: Swift Package Manager (Recommended)

1. Open `pinterest_clone.xcodeproj` in Xcode
2. Select your project in the navigator
3. Select the "pinterest_clone" target
4. Go to "Package Dependencies" tab
5. Click the "+" button
6. Enter: `https://github.com/groue/GRDB.swift.git`
7. Select version: `6.24.0` or later
8. Click "Add Package"
9. Select "GRDB" library
10. Click "Add Package"

### Option 2: Manual Installation

If Swift Package Manager doesn't work:

1. Download GRDB from: https://github.com/groue/GRDB.swift
2. Drag `GRDB.xcodeproj` into your project
3. Add GRDB framework to "Frameworks, Libraries, and Embedded Content"

---

## Build Configuration

### Minimum Requirements

- **Xcode**: 15.0 or later
- **macOS**: 14.0 (Sonoma) or later
- **Swift**: 5.9 or later

### Build Settings

Ensure these settings in your target:

**General Tab:**

- Minimum Deployments: macOS 14.0
- Swift Language Version: Swift 5

**Signing & Capabilities:**

- Enable App Sandbox (already configured)
- File Access: User Selected Files (Read/Write)
- Network: Outgoing Connections (for future API features)

---

## First Build

### Step 1: Add GRDB Package

Follow instructions above to add GRDB dependency.

### Step 2: Build Project

1. Open project: `open pinterest_clone.xcodeproj`
2. Select "pinterest_clone" scheme
3. Press ⌘B to build
4. Fix any compiler errors (see troubleshooting below)

### Step 3: Run Application

1. Press ⌘R to run
2. Check Console for initialization messages
3. View sample data in the UI

---

## Troubleshooting

### Common Issues

#### 1. "Module 'GRDB' not found"

**Solution:** Ensure GRDB package is added correctly

```
File > Add Package Dependencies >
https://github.com/groue/GRDB.swift.git
```

#### 2. Build Errors in Generated Files

**Solution:** Clean build folder

```
Shift + ⌘K (Clean Build Folder)
Then ⌘B (Build)
```

#### 3. Database File Not Found

**Solution:** App will create database automatically on first run. Check:

```
~/Library/Application Support/PinterestClone/pinterest.sqlite
```

#### 4. Missing Import Statements

The following imports are required in files using GRDB:

```swift
import GRDB
import Foundation
```

---

## Project Structure After Setup

```
pinterest_clone/
├── pinterest_clone.xcodeproj/
├── pinterest_clone/
│   ├── Database/              ✅ GRDB models
│   ├── Models/                ✅ Data models
│   ├── Repositories/          ✅ Data access
│   ├── Services/              ✅ Business logic
│   ├── Modules/               ✅ Feature modules
│   ├── Core/                  ✅ Core systems
│   └── Plugins/               ✅ Plugin system
├── docs/                      ✅ Documentation
├── README.md                  ✅ Main guide
└── LEARNING_GUIDE.md          ✅ Learning path
```

---

## Verification

### Check Installation

Run these in Xcode console after app launches:

```swift
// Should print: "✅ Database initialized"
// Should print: "✅ Sample data seeded"
// Should print: "✅ Built-in plugins registered"
```

### Test Database

Menu Bar → Help → Database Statistics

Should show:

```
📊 Database Statistics:
=====================
Users: 3
Boards: 3
Pins: 4
Comments: 3
=====================
```

---

## Next Steps

1. ✅ Complete setup above
2. 📖 Read [README.md](../README.md)
3. 📚 Follow [LEARNING_GUIDE.md](../LEARNING_GUIDE.md)
4. 🧪 Experiment with code
5. 🚀 Build your own features!

---

## Additional Resources

- [GRDB Documentation](https://github.com/groue/GRDB.swift)
- [Swift Package Manager](https://swift.org/package-manager/)
- [Xcode Help](https://developer.apple.com/xcode/)

---

**Having Issues?** Open an issue on GitHub with:

- Xcode version
- macOS version
- Error message
- Steps to reproduce
