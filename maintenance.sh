#!/bin/bash
# maintenance.sh
# Additional MacBook maintenance tasks
# by Harys & Copilot

echo "🔧 Starting additional MacBook maintenance..."

# 1. Clear DNS cache
echo "🗑 Clearing DNS cache..."
if command -v dscacheutil >/dev/null 2>&1; then
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
  echo "✅ DNS cache cleared"
else
  echo "⚠️ dscacheutil not found, skipping DNS cache clear"
fi

# 2. Check for software updates
echo "🔍 Checking for software updates..."
if command -v softwareupdate >/dev/null 2>&1; then
  softwareupdate --list
else
  echo "⚠️ softwareupdate command not found"
fi

# 3. Clear Adobe cache (if Adobe apps installed)
echo "🗑 Checking for Adobe cache..."
if [ -d "~/Library/Application Support/Adobe" ]; then
  echo "📦 Adobe Application Support size:"
  du -sh ~/Library/Application Support/Adobe 2>/dev/null
  read -p "Clear Adobe cache? (y/n): " ans
  [ "$ans" = "y" ] && rm -rf ~/Library/Application Support/Adobe/* && echo "✅ Adobe cache cleared"
else
  echo "⏩ No Adobe Application Support folder found"
fi

# 4. Clear Microsoft cache (if Microsoft apps installed)
echo "🗑 Checking for Microsoft cache..."
if [ -d "~/Library/Application Support/Microsoft" ]; then
  echo "📦 Microsoft Application Support size:"
  du -sh ~/Library/Application Support/Microsoft 2>/dev/null
  read -p "Clear Microsoft cache? (y/n): " ans
  [ "$ans" = "y" ] && rm -rf ~/Library/Application Support/Microsoft/* && echo "✅ Microsoft cache cleared"
else
  echo "⏩ No Microsoft Application Support folder found"
fi

# 5. Check for large files (>1GB) in home directory
echo "🔍 Checking for large files (>1GB) in home directory..."
find ~ -type f -size +1G 2>/dev/null | head -10

# 6. Check disk usage
echo "💾 Disk usage:"
df -h

echo "✅ Additional maintenance finished!"