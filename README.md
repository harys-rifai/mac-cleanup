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

To run:

```bash
chmod +x clean-cache.sh
./clean-cache.sh
```

### mac-cleanup.sh

This script provides an interactive menu to clean up specific areas:

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

To run:

```bash
chmod +x mac-cleanup.sh
./mac-cleanup.sh
```

Then follow the on-screen prompts.

## Notes

- Always review what you are deleting, especially when running scripts with sudo or removing system files.
- The scripts are provided as-is and you use them at your own risk.
- For system logs in `/var/log`, you need to run cleanup manually with sudo if required.

## Contributing

Feel free to fork this repository and submit pull requests for improvements.

## License

MIT