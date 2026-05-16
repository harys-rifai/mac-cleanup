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
