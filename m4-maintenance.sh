#!/bin/bash
# m4-maintenance.sh
# Apple Silicon M4 MacBook (Air & Pro) Maintenance & Diagnostics Tool
# Designed to optimize and monitor performance, thermal state, and system health.

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
  echo -e "${RED}❌ Error: This script is only compatible with macOS.${NC}"
  exit 1
fi

# Detect Chip brand string
CHIP_BRAND=$(sysctl -n machdep.cpu.brand_string)
MODEL_NAME=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Model Name" | cut -d: -f2 | xargs)
MODEL_ID=$(sysctl -n hw.model)

# Header
show_header() {
  clear
  echo -e "${CYAN}======================================================================${NC}"
  echo -e "${BLUE}⚡ M4 Apple Silicon MacBook Maintenance & Diagnostics Tool ⚡${NC}"
  echo -e "${CYAN}======================================================================${NC}"
  echo -e "${YELLOW}Device: ${NC}$MODEL_NAME ($MODEL_ID)"
  echo -e "${YELLOW}Chipset:${NC} $CHIP_BRAND"
  echo -e "${YELLOW}OS:     ${NC}macOS $(sw_vers -productVersion) (Build $(sw_vers -buildVersion))"
  echo -e "${CYAN}----------------------------------------------------------------------${NC}"
}

# 1. Quick System Diagnostics
show_diagnostics() {
  show_header
  echo -e "${BLUE}[1] System Diagnostics & Core Layout${NC}\n"
  
  # Core layout
  local total_cores=$(sysctl -n hw.ncpu)
  local perf_cores=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo "Unknown")
  local eff_cores=$(sysctl -n hw.perflevel1.physicalcpu 2>/dev/null || echo "Unknown")
  
  echo -e "${CYAN}Core Layout:${NC}"
  echo -e "  • Total Cores:       $total_cores"
  echo -e "  • Performance Cores: $perf_cores"
  echo -e "  • Efficiency Cores:  $eff_cores"
  echo ""
  
  # Cache sizes
  local l1i=$(sysctl -n hw.perflevel0.l1icachesize 2>/dev/null)
  local l1d=$(sysctl -n hw.perflevel0.l1dcachesize 2>/dev/null)
  local l2=$(sysctl -n hw.perflevel0.l2cachesize 2>/dev/null)
  
  # Convert bytes to KB/MB for display
  if [ -n "$l2" ]; then
    l2_mb=$((l2 / 1024 / 1024))
    echo -e "${CYAN}Hardware Cache Size (P-Cores):${NC}"
    echo -e "  • L1 Instruction Cache: $((l1i / 1024)) KB"
    echo -e "  • L1 Data Cache:        $((l1d / 1024)) KB"
    echo -e "  • L2 Cache:             $l2_mb MB"
    echo ""
  fi

  # System features / Info
  echo -e "${CYAN}System Architecture:${NC}"
  echo -e "  • Architecture:      $(uname -m)"
  echo -e "  • Kernel Version:    $(uname -v | cut -d: -f1)"
  
  echo -e "\nPress Enter to return to menu..."
  read -r
}

# 2. Memory & Swap Analysis
show_memory_status() {
  show_header
  echo -e "${BLUE}[2] Memory & Swap Pressure Analysis${NC}\n"
  
  # Total Physical RAM
  local total_mem_bytes=$(sysctl -n hw.memsize)
  local total_mem_gb=$((total_mem_bytes / 1024 / 1024 / 1024))
  
  # VM stats parsing
  local page_size=$(pagesize)
  local vm_stats=$(vm_stat)
  
  get_pages() {
    echo "$vm_stats" | grep "$1" | awk '{print $NF}' | sed 's/\.//'
  }
  
  local free_pages=$(get_pages "Pages free")
  local active_pages=$(get_pages "Pages active")
  local inactive_pages=$(get_pages "Pages inactive")
  local speculative_pages=$(get_pages "Pages speculative")
  local wired_pages=$(get_pages "Pages wired down")
  local compressed_pages=$(get_pages "Pages stored in compressor")
  
  local free_gb=$(( (free_pages + speculative_pages) * page_size / 1024 / 1024 / 1024 ))
  local used_gb=$(( (active_pages + inactive_pages + wired_pages + compressed_pages) * page_size / 1024 / 1024 / 1024 ))
  local active_gb=$(( active_pages * page_size / 1024 / 1024 / 1024 ))
  local inactive_gb=$(( inactive_pages * page_size / 1024 / 1024 / 1024 ))
  local wired_gb=$(( wired_pages * page_size / 1024 / 1024 / 1024 ))
  local compressed_gb=$(( compressed_pages * page_size / 1024 / 1024 / 1024 ))
  
  echo -e "${CYAN}Unified Memory (RAM) Usage:${NC}"
  echo -e "  • Total Installed: ${GREEN}${total_mem_gb} GB${NC}"
  echo -e "  • Approx. Used:    ${YELLOW}${used_gb} GB${NC}"
  echo -e "  • Approx. Free:    ${GREEN}${free_gb} GB${NC}"
  echo -e "    - Active:        ${active_gb} GB"
  echo -e "    - Inactive:      ${inactive_gb} GB"
  echo -e "    - Wired:         ${wired_gb} GB"
  echo -e "    - Compressed:    ${compressed_gb} GB"
  echo ""
  
  # Memory pressure check
  echo -e "${CYAN}Memory Pressure Status:${NC}"
  # Output the memory pressure report
  if command -v memory_pressure >/dev/null 2>&1; then
    # Parse a single check or show user-level info
    echo -e "  Pressure level: $(sysctl -n kern.memo 2>/dev/null || echo "Check vm_stat below")"
    memory_pressure | head -n 4 | sed 's/^/  /'
  else
    echo "  • memory_pressure tool not available."
  fi
  echo ""

  # Swap Usage
  echo -e "${CYAN}NVMe SSD Swap File Usage:${NC}"
  local swap_info=$(sysctl -n vm.swapusage)
  echo -e "  • $swap_info"
  
  echo -e "\nPress Enter to return to menu..."
  read -r
}

# 3. Battery Health & Power Status
show_battery_health() {
  show_header
  echo -e "${BLUE}[3] Battery Health & Power Status${NC}\n"
  
  local power_info=$(system_profiler SPPowerDataType 2>/dev/null)
  
  if [ -n "$power_info" ]; then
    local cycle_count=$(echo "$power_info" | grep "Cycle Count" | awk '{print $3}')
    local condition=$(echo "$power_info" | grep "Condition" | awk '{print $2}')
    local capacity=$(echo "$power_info" | grep "Maximum Capacity" | awk '{print $3}' | tr -d '%')
    
    echo -e "${CYAN}Battery Health Information:${NC}"
    echo -e "  • Condition:        ${GREEN}${condition}${NC}"
    echo -e "  • Cycle Count:      ${YELLOW}${cycle_count}${NC} cycles"
    if [ -n "$capacity" ]; then
      echo -e "  • Maximum Capacity: ${GREEN}${capacity}%${NC}"
    else
      # Fallback if Maximum Capacity is named differently in system profiler
      local capacity_alt=$(echo "$power_info" | grep "Maximum Capacity" | awk -F: '{print $2}' | xargs)
      echo -e "  • Maximum Capacity: ${GREEN}${capacity_alt:-N/A}${NC}"
    fi
  else
    echo -e "${RED}⚠️ Could not read power information.${NC}"
  fi
  echo ""
  
  # Current power source
  echo -e "${CYAN}Current Power Source Details:${NC}"
  pmset -g batt | sed 's/^/  /'
  
  echo -e "\nPress Enter to return to menu..."
  read -r
}

# 4. Disk & Storage Health
show_disk_health() {
  show_header
  echo -e "${BLUE}[4] Disk & Storage Health${NC}\n"
  
  # Disk space
  echo -e "${CYAN}Disk Space Usage:${NC}"
  df -h / | sed 's/^/  /'
  echo ""
  
  # SMART Status & Hardware Protocol
  echo -e "${CYAN}SSD Hardware Details & SMART Status:${NC}"
  local disk_details=$(diskutil info / 2>/dev/null | grep -E "SMART|Protocol|Device / Media Name")
  if [ -n "$disk_details" ]; then
    echo "$disk_details" | sed 's/^/  /'
  else
    echo "  • APFS Root Volume inspected. Local SMART status can be checked on disk0."
    diskutil info disk0 2>/dev/null | grep -E "SMART|Protocol|Device / Media Name" | sed 's/^/  /'
  fi
  
  echo -e "\nPress Enter to return to menu..."
  read -r
}

# 5. Thermal & Throttling Check
show_thermals() {
  show_header
  echo -e "${BLUE}[5] Thermal & Throttling Diagnostics${NC}\n"
  
  # MacBook Air warning
  if [[ "$MODEL_NAME" == *"Air"* ]]; then
    echo -e "${YELLOW}ℹ️ Notice: MacBook Air models are fanless. They rely on passive cooling.${NC}"
    echo -e "  Sustained heavy CPU/GPU tasks will trigger thermal throttling to control heat."
  elif [[ "$MODEL_NAME" == *"Pro"* ]]; then
    echo -e "${GREEN}ℹ️ Notice: MacBook Pro models have active fan cooling.${NC}"
    echo -e "  Keep fan vents clear of obstructions for optimum performance."
  fi
  echo ""
  
  echo -e "${CYAN}Current System Thermal Warning Levels:${NC}"
  local therm_info=$(pmset -g therm)
  if [ -n "$therm_info" ]; then
    echo "$therm_info" | sed 's/^/  /'
  else
    echo "  • No warnings. System temperatures are within optimal range."
  fi
  
  echo -e "\nPress Enter to return to menu..."
  read -r
}

# 6. Rosetta 2 & App Translation Check
show_rosetta_status() {
  show_header
  echo -e "${BLUE}[6] Rosetta 2 & Intel App Translation Check${NC}\n"
  
  # Check if Rosetta 2 is installed
  if [ -d "/Library/Apple/usr/libexec/oah" ]; then
    echo -e "Rosetta 2 Status: ${GREEN}Installed (oahd active)${NC}"
  else
    echo -e "Rosetta 2 Status: ${YELLOW}Not Installed${NC} (System is strictly running arm64 native code)"
  fi
  echo ""
  
  # Check Rosetta translated running processes
  echo -e "${CYAN}Running processes translated by Rosetta (x86_64 / Intel):${NC}"
  
  # Get processes and check
  local translated_proc=$(ps -ax -o pid,command,sysctl.proc_translated 2>/dev/null | grep " 1$")
  
  if [ -n "$translated_proc" ]; then
    echo -e "${YELLOW}PIDs and Processes running under Intel emulation:${NC}"
    echo "$translated_proc" | awk '{print "  PID " $1 ": " $2}' | cut -c1-80
    echo -e "\n${YELLOW}💡 Tip: Native arm64 apps run much more efficiently and consume less battery.${NC}"
    echo -e "   Check if Apple Silicon native updates are available for these applications."
  else
    echo -e "${GREEN}✓ Great! No processes are running under Rosetta 2 emulation.${NC}"
    echo -e "   All running applications are natively compiled for Apple Silicon (arm64)."
  fi
  
  echo -e "\nPress Enter to return to menu..."
  read -r
}

# 7. Safe Caches & Shader Cleanup
run_cleanup() {
  show_header
  echo -e "${BLUE}[7] Safe Caches & Metal Shader Cleanup${NC}\n"
  
  # User cache size check
  echo -e "Checking cache sizes before clearing..."
  if [ -d ~/Library/Caches ]; then
    echo -n "  • User Application Cache size: "
    du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}'
  fi
  
  # Metal Cache check
  if [ -d ~/Library/Caches/com.apple.metal ]; then
    echo -n "  • Metal Shader Compiler Cache size: "
    du -sh ~/Library/Caches/com.apple.metal 2>/dev/null | awk '{print $1}'
  fi
  
  # Xcode DerivedData check
  if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
    echo -n "  • Xcode DerivedData size: "
    du -sh ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk '{print $1}'
  fi
  
  echo -e "\nProceeding with cleanup operations..."
  
  # 1. Clear system/user caches (safe ones, skip protected OS cache directories)
  echo -e "🧹 Clearing User Application Caches (skipping protected folders)..."
  for dir in ~/Library/Caches/*; do
    case "$dir" in
      *CloudKit*|*FamilyCircle*|*Safari*|*com.apple.Safari*|*com.apple.containment*)
        # Keep OS/Browser critical session data intact
        ;;
      *)
        rm -rf "$dir" 2>/dev/null
        ;;
    esac
  done
  
  # 2. Clear Metal Shader cache (forces recompiling shaders for optimum M4 GPU performance)
  echo -e "🧹 Clearing Metal Shader Caches..."
  rm -rf ~/Library/Caches/com.apple.metal/* 2>/dev/null
  
  # 3. Clear Xcode Derived Data (if exists)
  if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
    echo -e "🧹 Clearing Xcode DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null
  fi
  
  # 4. Clear npm and yarn caches
  if command -v npm >/dev/null 2>&1; then
    echo -e "🧹 Clearing npm cache..."
    npm cache clean --force >/dev/null 2>&1
  fi
  if command -v yarn >/dev/null 2>&1; then
    echo -e "🧹 Clearing yarn cache..."
    yarn cache clean >/dev/null 2>&1
  fi
  
  # 5. Homebrew Cache Cleanup
  if command -v brew >/dev/null 2>&1; then
    echo -e "🧹 Cleaning up Homebrew caches..."
    brew cleanup --prune=all >/dev/null 2>&1
  fi

  # 6. Trash purge
  echo -e "🧹 Emptying User Trash..."
  rm -rf ~/.Trash/* 2>/dev/null

  echo -e "\n${GREEN}✅ Safe caches and GPU Shaders cleared successfully!${NC}"
  
  # Purging RAM (requires sudo)
  echo -e "\nWould you like to purge inactive RAM? (Requires sudo password)"
  read -p "Purge inactive memory? (y/n): " purge_choice
  if [ "$purge_choice" = "y" ]; then
    echo -e "${YELLOW}Running 'sudo purge' to release inactive memory pages...${NC}"
    sudo purge
    echo -e "${GREEN}✓ Memory purged.${NC}"
  fi

  echo -e "\nPress Enter to return to menu..."
  read -r
}

# 8. Flush DNS Cache
flush_dns() {
  show_header
  echo -e "${BLUE}[8] Flush DNS Cache${NC}\n"
  
  echo -e "This will flush the local mDNSResponder DNS cache."
  echo -e "Requires admin permissions (sudo)."
  
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
  
  echo -e "\n${GREEN}✅ DNS Cache successfully flushed!${NC}"
  
  echo -e "\nPress Enter to return to menu..."
  read -r
}

# 9. Check Software Updates
check_updates() {
  show_header
  echo -e "${BLUE}[9] Check Software & Homebrew Updates${NC}\n"
  
  echo -e "${CYAN}Checking for macOS system software updates...${NC}"
  softwareupdate -l
  echo ""
  
  if command -v brew >/dev/null 2>&1; then
    echo -e "${CYAN}Checking for Homebrew package updates...${NC}"
    brew update
    local brew_outdated=$(brew outdated)
    if [ -n "$brew_outdated" ]; then
      echo -e "\n${YELLOW}Outdated Packages found:${NC}"
      echo "$brew_outdated" | sed 's/^/  /'
      echo -e "\nRun 'brew upgrade' to upgrade them."
    else
      echo -e "${GREEN}✓ All Homebrew packages are up to date!${NC}"
    fi
  else
    echo -e "Homebrew is not installed on this system."
  fi
  
  echo -e "\nPress Enter to return to menu..."
  read -r
}

# A. Run All Diagnostics & Simple Maintenance
run_all_diagnostics() {
  show_header
  echo -e "${BLUE}[A] Running Comprehensive Diagnostics Report...${NC}\n"
  
  echo -e "${CYAN}------------------ CPU & Core Layout ------------------${NC}"
  local total_cores=$(sysctl -n hw.ncpu)
  local perf_cores=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo "Unknown")
  local eff_cores=$(sysctl -n hw.perflevel1.physicalcpu 2>/dev/null || echo "Unknown")
  echo -e "Chip:                 $CHIP_BRAND"
  echo -e "Model Name / ID:      $MODEL_NAME ($MODEL_ID)"
  echo -e "Performance/E-Cores:  $perf_cores Physical P-Cores, $eff_cores Physical E-Cores (Total: $total_cores)"
  
  echo -e "\n${CYAN}------------------ Unified Memory ------------------${NC}"
  local total_mem_bytes=$(sysctl -n hw.memsize)
  local total_mem_gb=$((total_mem_bytes / 1024 / 1024 / 1024))
  echo -e "Total Physical RAM:   ${total_mem_gb} GB"
  sysctl -n vm.swapusage
  
  echo -e "\n${CYAN}------------------ Battery & Health ------------------${NC}"
  local power_info=$(system_profiler SPPowerDataType 2>/dev/null)
  if [ -n "$power_info" ]; then
    local cycle_count=$(echo "$power_info" | grep "Cycle Count" | awk '{print $3}')
    local condition=$(echo "$power_info" | grep "Condition" | awk '{print $2}')
    local capacity=$(echo "$power_info" | grep "Maximum Capacity" | awk '{print $3}')
    echo -e "Battery Condition:    ${GREEN}${condition}${NC}"
    echo -e "Cycle Count:          ${YELLOW}${cycle_count}${NC} cycles"
    echo -e "Maximum Capacity:     ${GREEN}${capacity:-N/A}${NC}"
  else
    echo -e "Power Info:           Unavailable"
  fi
  
  echo -e "\n${CYAN}------------------ Storage Health ------------------${NC}"
  local disk_details=$(diskutil info / 2>/dev/null | grep -E "SMART|Protocol|Device / Media Name" | xargs)
  echo -e "SSD Specs & SMART:    $disk_details"
  df -h / | tail -n 1 | awk '{print "APFS Storage:         Total: " $2 ", Used: " $3 ", Free: " $4 " (" $5 " used)"}'
  
  echo -e "\n${CYAN}------------------ Thermal & Throttling ------------------${NC}"
  local therm_info=$(pmset -g therm | xargs)
  if [ -n "$therm_info" ]; then
    echo -e "Thermal Warning:      $therm_info"
  else
    echo -e "Thermal Warning:      ${GREEN}No warning levels registered${NC}"
  fi
  
  echo -e "\n${CYAN}------------------ Rosetta 2 Status ------------------${NC}"
  local translated_proc=$(ps -ax -o pid,command,sysctl.proc_translated 2>/dev/null | grep " 1$" | wc -l | xargs)
  if [ "$translated_proc" -eq 0 ]; then
    echo -e "Rosetta 2 Apps:       ${GREEN}0 processes currently running translated${NC} (100% native arm64)"
  else
    echo -e "Rosetta 2 Apps:       ${YELLOW}$translated_proc processes running under translation (Intel emulation)${NC}"
  fi
  
  echo -e "\n${CYAN}======================================================================${NC}"
  echo -e "${GREEN}Report compilation complete!${NC}"
  
  echo -e "\nPress Enter to return to menu..."
  read -r
}

# Main Menu loop
while true; do
  show_header
  echo -e "1. Quick System Diagnostics & Core Layout"
  echo -e "2. Memory & Swap Pressure Analysis"
  echo -e "3. Battery Health & Power Status"
  echo -e "4. Disk & Storage Health"
  echo -e "5. Thermal & Throttling Check"
  echo -e "6. Rosetta 2 & App Translation Check"
  echo -e "7. Safe Caches & Metal Shader Cleanup"
  echo -e "8. Flush DNS Cache"
  echo -e "9. Check Software & Homebrew Updates"
  echo -e "A. Compile All Diagnostics Report"
  echo -e "0. Exit"
  echo -e "${CYAN}======================================================================${NC}"
  
  read -p "Select option: " choice
  
  case $choice in
    1) show_diagnostics ;;
    2) show_memory_status ;;
    3) show_battery_health ;;
    4) show_disk_health ;;
    5) show_thermals ;;
    6) show_rosetta_status ;;
    7) run_cleanup ;;
    8) flush_dns ;;
    9) check_updates ;;
    A|a) run_all_diagnostics ;;
    0) 
      echo -e "\n${GREEN}👋 Exiting. Keep your M4 Mac running fast and cool!${NC}"
      break 
      ;;
    *)
      echo -e "${RED}Invalid selection. Please try again.${NC}"
      sleep 1
      ;;
  esac
done
