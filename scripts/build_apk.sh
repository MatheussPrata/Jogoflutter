#!/bin/bash
# Install gradle wrapper if not present
if [ ! -f ./android/gradlew ]; then
    cd android && gradle wrapper --gradle-version 8.9 && cd ..
fi

# Build with verbose output to see where APK ends up
flutter build apk --release --verbose

# List all APKs found
find . -name "*.apk" -type f 2>/dev/null | head -20