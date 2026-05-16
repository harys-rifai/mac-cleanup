#!/bin/bash
git remote add origin https://github.com/harys-rifai/mac-cleanup.git 2>/dev/null || true
git branch -M main
git add .
git commit -m "Update" || echo "No changes to commit"
git push -u origin main