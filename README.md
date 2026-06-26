# Mac Cleanup Scripts

This repository contains two bash scripts to help clean up your macOS system:

1. `clean-cache.sh` - A simple script to clear various caches (system, npm, yarn, build tools, Xcode, Gradle, Homebrew) and run periodic maintenance.
2. `mac-cleanup.sh` - An interactive script that allows you to clean up specific categories or run an all-in-one cleanup.

## Usage

### Prerequisites

- macOS
- Bash shell
- Some operations may require sudo (for system logs and periodic maintenance)

### clean-cache.sh

This script performs a cleanup without user interaction. It will:

- Clear system and application caches (`~/Library/Caches`)
- Clear npm and yarn caches (if installed)
- Remove build tool caches (`.next`, `node_modules/.vite`, `.angular/cache`, `dist`)
- Clear Xcode DerivedData
- Clear Gradle cache
- Run Homebrew cleanup (if installed)
- Run macOS periodic maintenance (requires sudo)

Script content:
```bash
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
```

To run:

```bash
chmod +x clean-cache.sh
./clean-cache.sh
```

### mac-cleanup.sh

This script provides an interactive menu to clean up specific areas:

![Mac Cleanup Options Menu](Screenshot%202026-06-26%20at%2011.32.55.png)

1. System Cache (`~/Library/Caches`)
2. Downloads Folder
3. Trash
4. Xcode DerivedData
5. Android Studio / Gradle Cache
6. Docker Images & Containers
7. Homebrew Cache
8. Log Files (user logs only)
9. Node Modules (current project)
A. All-in-One Cleanup
0. Exit

Script content:
```bash
#!/bin/bash
# mac-cleanup.sh
# Housekeeping script untuk macOS dengan opsi per kategori
# by Harys & Copilot

# Fungsi untuk hitung size folder
check_size() {
  local path=$1
  if [ -d "$path" ]; then
    du -sh "$path" 2>/dev/null
  else
    echo "No directory: $path"
  fi
}

# Fungsi untuk hapus cache user apps (skip protected)
clean_user_cache() {
  echo "🗑 Cleaning ~/Library/Caches (skip protected)..."
  for dir in ~/Library/Caches/*; do
    case "$dir" in
      *CloudKit*|*FamilyCircle*|*Safari*|*com.apple*)
        echo "⏩ Skip protected: $dir"
        ;;
      *)
        echo "🗑 Removing: $dir"
        rm -rf "$dir"
        ;;
    esac
  done
}

# Menu opsi
while true; do
  echo "=============================="
  echo "🧹 Mac Cleanup Options"
  echo "=============================="
  echo "1. System Cache (~Library/Caches)"
  echo "2. Downloads Folder"
  echo "3. Trash"
  echo "4. Xcode DerivedData"
  echo "5. Android Studio / Gradle Cache"
  echo "6. Docker Images & Containers"
  echo "7. Homebrew Cache"
  echo "8. Log Files"
  echo "9. Node Modules (current project)"
  echo "A. All-in-One Cleanup"
  echo "0. Exit"
  echo "=============================="

  read -p "Pilih kategori: " choice

  case $choice in
    1)
      echo "📦 Size System Cache:"
      check_size ~/Library/Caches
      read -p "Hapus cache user apps? (y/n): " ans
      [ "$ans" = "y" ] && clean_user_cache
      ;;
    2)
      echo "📦 Size Downloads:"
      check_size ~/Downloads
      read -p "Hapus Downloads? (y/n): " ans
      [ "$ans" = "y" ] && rm -rf ~/Downloads/*
      ;;
    3)
      echo "📦 Size Trash:"
      check_size ~/.Trash
      read -p "Empty Trash? (y/n): " ans
      [ "$ans" = "y" ] && rm -rf ~/.Trash/*
      ;;
    4)
      echo "📦 Size Xcode DerivedData:"
      check_size ~/Library/Developer/Xcode/DerivedData
      read -p "Hapus DerivedData? (y/n): " ans
      [ "$ans" = "y" ] && rm -rf ~/Library/Developer/Xcode/DerivedData/*
      ;;
    5)
      echo "📦 Size Gradle Cache:"
      check_size ~/.gradle/caches
      read -p "Hapus Gradle cache? (y/n): " ans
      [ "$ans" = "y" ] && rm -rf ~/.gradle/caches/*
      ;;
    6)
      echo "📦 Docker Disk Usage:"
      docker system df
      read -p "Prune Docker (hapus semua unused)? (y/n): " ans
      [ "$ans" = "y" ] && docker system prune -a -f
      ;;
    7)
      echo "📦 Homebrew Cache Size:"
      brew cleanup -n
      read -p "Cleanup Homebrew? (y/n): " ans
      [ "$ans" = "y" ] && brew cleanup --prune=all
      ;;
    8)
      echo "📦 Log Files Size:"
      check_size /var/log
      check_size ~/Library/Logs
      read -p "Hapus log files (user logs only)? (y/n): " ans
      if [ "$ans" = "y" ]; then
        echo "🗑 Removing ~/Library/Logs/* (user logs)..."
        rm -rf ~/Library/Logs/*
        echo "⚠️ System logs in /var/log require sudo. Jalankan manual jika perlu:"
        echo "   sudo rm -rf /var/log/*"
      fi
      ;;
    9)
      echo "📦 Node Modules Size (current project):"
      if [ -d "./node_modules" ]; then
        check_size ./node_modules
        read -p "Hapus node_modules? (y/n): " ans
        [ "$ans" = "y" ] && rm -rf ./node_modules
      else
        echo "⏩ Tidak ada folder node_modules di project ini."
      fi
      ;;
    A|a)
      echo "🚀 All-in-One Cleanup running..."
      clean_user_cache
      rm -rf ~/Downloads/* ~/.Trash/* ~/Library/Developer/Xcode/DerivedData/* ~/.gradle/caches/*
      docker system prune -a -f
      brew cleanup --prune=all
      rm -rf ~/Library/Logs/*
      [ -d "./node_modules" ] && rm -rf ./node_modules
      echo "⚠️ System logs in /var/log require sudo manual cleanup."
      echo "✅ All-in-One Cleanup finished!"
      ;;
    0)
      echo "❌ Exit"
      break
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
done

echo "✅ Done!"
```

To run:

```bash
chmod +x mac-cleanup.sh
./mac-cleanup.sh
```

Then follow the on-screen prompts.

![Homebrew Cleanup Output Example](Screenshot%202026-06-26%20at%2011.33.14.png)

## Notes

- Always review what you are deleting, especially when running scripts with sudo or removing system files.
- The scripts are provided as-is and you use them at your own risk.
- For system logs in `/var/log`, you need to run cleanup manually with sudo if required.

## Using push.sh

The `push.sh` script is provided to easily push updates to the GitHub repository. It will:

1. Add the remote origin (if not already added)
2. Set the main branch
3. Add all changes
4. Commit with message "Update"
5. Push to origin main

Script content:
```bash
#!/bin/bash
git remote add origin https://github.com/harys-rifai/mac-cleanup.git 2>/dev/null || true
git branch -M main
git add .
git commit -m "Update" || echo "No changes to commit"
git push -u origin main
```

To use it after making changes:

```bash
chmod +x push.sh
./push.sh
```

### maintenance.sh

This script performs additional MacBook maintenance tasks:

- Clear DNS cache
- Check for software updates
- Clear Adobe cache (if installed)
- Clear Microsoft cache (if installed)
- Check for large files (>1GB) in home directory
- Check disk usage

Script content:
```bash
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
```

To run:

```bash
chmod +x maintenance.sh
./maintenance.sh
```

### m4-maintenance.sh

This script is specifically designed for Apple Silicon M4 series MacBooks (Air and Pro). It provides advanced hardware diagnostics, thermal monitoring, battery health metrics, SSD SMART status, Rosetta 2 process detection, and performance optimization.

Key Features:
- **Processor & Core Layout:** Displays M4 core structures (Performance vs. Efficiency cores).
- **Unified Memory Analysis:** Analyzes current active, inactive, wired, compressed memory, and SSD swap file usage.
- **Battery & Power Health:** Reports cycle count, condition, and maximum capacity percentage.
- **Disk & SMART Health:** Verifies the hardware protocol and built-in SSD S.M.A.R.T. status.
- **Thermal Diagnostic:** Checks thermal warning levels (particularly crucial for fanless MacBook Air M4 models).
- **Rosetta 2 Process Finder:** Identifies running x86_64/Intel apps that may be impacting performance and battery efficiency.
- **GPU Metal Shader & Cache Cleanup:** Clears macOS system caches, user app caches, and Metal shader caches (forcing recompiles for optimum M4 GPU performance).
- **DNS Cache & Software Updates:** Flushes mDNSResponder cache and checks for macOS/Homebrew updates.

To run:

```bash
chmod +x m4-maintenance.sh
./m4-maintenance.sh
```

## Contributing

Feel free to fork this repository and submit pull requests for improvements.

## License

MIT