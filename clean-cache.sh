#!/bin/bash
# cleanup-webdev.sh
# Script untuk bersihin cache web development di macOS

echo "🧹 Starting cleanup..."

# 1. Bersihkan cache sistem & aplikasi
echo "🗑 Clearing ~/Library/Caches..."
rm -rf ~/Library/Caches/*

# 2. Bersihkan npm & yarn cache
if command -v npm >/dev/null 2>&1; then
  echo "🗑 Clearing npm cache..."
  npm cache clean --force
fi

if command -v yarn >/dev/null 2>&1; then
  echo "🗑 Clearing yarn cache..."
  yarn cache clean
fi

# 3. Bersihkan folder build tools
echo "🗑 Removing build caches (.next, vite, angular)..."
rm -rf .next node_modules/.vite .angular/cache dist

# 4. Bersihkan Xcode DerivedData
echo "🗑 Clearing Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 5. Bersihkan Gradle cache (Android Studio)
echo "🗑 Clearing Gradle cache..."
rm -rf ~/.gradle/caches/

# 6. Bersihkan Homebrew cache
if command -v brew >/dev/null 2>&1; then
  echo "🗑 Running brew cleanup..."
  brew cleanup
fi

# 7. Jalankan periodic maintenance
echo "🗑 Running macOS periodic maintenance..."
sudo periodic daily weekly monthly

echo "✅ Cleanup finished!"
