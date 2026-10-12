#!/usr/bin/env bash
# Generates the Android platform folder and applies all required patches.
set -euo pipefail
flutter create --platforms=android --org com.homegardening --project-name home_gardening .
rm -rf test
python3 tool/patch_android.py
