#!/bin/bash

# Xcode Project Generator for Minima
# Run this script on macOS to generate the .xcodeproj

set -e

PROJECT_NAME="Minima"
BUNDLE_ID="com.minima.app"
TEAM_ID="YOUR_TEAM_ID"  # Replace with your Apple Developer Team ID

echo "🚀 Generating Xcode Project for $PROJECT_NAME..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must be run on macOS"
    exit 1
fi

# Create project.yml for XcodeGen
cat > project.yml << EOF
name: $PROJECT_NAME
options:
  bundleIdPrefix: com.minima
  deploymentTarget:
    iOS: "17.0"
    macOS: "14.0"
  xcodeVersion: "15.0"
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: "5.9"
    ENABLE_USER_SCRIPT_SANDBOXING: NO
    DEVELOPMENT_TEAM: $TEAM_ID

targets:
  # Main App
  Minima:
    type: application
    platform: [iOS, macOS]
    sources:
      - path: MinimaApp
        excludes:
          - "**/*.metal"
      - path: MinimaBrain
      - path: MinimaVision
    resources:
      - path: MinimaApp/Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID
        INFOPLIST_FILE: MinimaApp/Info.plist
        CODE_SIGN_ENTITLEMENTS: MinimaApp/Minima.entitlements
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    dependencies:
      - target: MinimaWidgets
        embed: true
    preBuildScripts:
      - name: Compile Metal Shaders
        script: |
          xcrun metal -c "\$SRCROOT/MinimaVision/Kernels/Shaders.metal" -o "\$BUILT_PRODUCTS_DIR/Shaders.air"
          xcrun metal -c "\$SRCROOT/MinimaVision/Kernels/VisualHash.metal" -o "\$BUILT_PRODUCTS_DIR/VisualHash.air"
          xcrun metal -c "\$SRCROOT/MinimaVision/Kernels/FlashAttention.metal" -o "\$BUILT_PRODUCTS_DIR/FlashAttention.air"
          xcrun metallib "\$BUILT_PRODUCTS_DIR/Shaders.air" "\$BUILT_PRODUCTS_DIR/VisualHash.air" "\$BUILT_PRODUCTS_DIR/FlashAttention.air" -o "\$BUILT_PRODUCTS_DIR/default.metallib"

  # Widget Extension
  MinimaWidgets:
    type: app-extension
    platform: iOS
    sources:
      - path: MinimaWidgets
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID.widgets
        INFOPLIST_FILE: MinimaWidgets/Info.plist

  # Safari Extension
  MinimaSafariExtension:
    type: app-extension
    platform: macOS
    sources:
      - path: MinimaSafariExtension
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID.safari
        INFOPLIST_FILE: MinimaSafariExtension/Info.plist

  # Unit Tests
  MinimaTests:
    type: bundle.unit-test
    platform: [iOS, macOS]
    sources:
      - path: MinimaTests
    dependencies:
      - target: Minima
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID.tests

  # UI Tests
  MinimaUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - path: MinimaUITests
    dependencies:
      - target: Minima
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID.uitests

schemes:
  Minima:
    build:
      targets:
        Minima: all
        MinimaWidgets: all
        MinimaTests: [test]
        MinimaUITests: [test]
    run:
      config: Debug
    test:
      config: Debug
      targets:
        - MinimaTests
        - MinimaUITests
    profile:
      config: Release
    archive:
      config: Release
EOF

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing XcodeGen..."
    brew install xcodegen
fi

# Generate Xcode project
echo "🔧 Running XcodeGen..."
xcodegen generate

# Create Info.plist if it doesn't exist
if [ ! -f "MinimaApp/Info.plist" ]; then
    cat > MinimaApp/Info.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Minima</string>
    <key>CFBundleDisplayName</key>
    <string>Minima</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSCameraUsageDescription</key>
    <string>Minima uses the camera for visual input.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Minima uses the microphone for voice input.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Minima uses speech recognition for voice commands.</string>
    <key>NSContactsUsageDescription</key>
    <string>Minima uses contacts to help you compose messages.</string>
    <key>NSCalendarsUsageDescription</key>
    <string>Minima uses your calendar to help with scheduling.</string>
    <key>NSRemindersUsageDescription</key>
    <string>Minima uses reminders to help manage your tasks.</string>
    <key>NSFaceIDUsageDescription</key>
    <string>Minima uses Face ID to protect your conversations.</string>
</dict>
</plist>
PLIST
fi

# Create entitlements file
cat > MinimaApp/Minima.entitlements << ENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.personal-information.addressbook</key>
    <true/>
    <key>com.apple.security.personal-information.calendars</key>
    <true/>
    <key>com.apple.developer.screen-capture-picker</key>
    <true/>
    <key>com.apple.security.temporary-exception.apple-events</key>
    <array>
        <string>com.apple.Notes</string>
    </array>
</dict>
</plist>
ENT

echo "✅ Xcode project generated successfully!"
echo ""
echo "Next steps:"
echo "  1. Open $PROJECT_NAME.xcodeproj in Xcode"
echo "  2. Set your Team ID in Signing & Capabilities"
echo "  3. Add llama.cpp as a submodule: git submodule add https://github.com/ggerganov/llama.cpp"
echo "  4. Build and run!"
