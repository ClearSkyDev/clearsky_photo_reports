import json
import shutil
from pathlib import Path

# Assume script lives in scripts/ within repo root
ROOT = Path(__file__).resolve().parent.parent
EXPO_DIR = ROOT / "react_native"
IOS_DIR = EXPO_DIR / "ios"
APP_JSON = EXPO_DIR / "app.json"

# Step 1: Remove native iOS folder so EAS reads app.json
if IOS_DIR.exists():
    shutil.rmtree(IOS_DIR)
    print("\u2705 Removed native iOS folder (react_native/ios) to allow EAS to use app.json settings.")
else:
    print("\u2139\ufe0f No react_native/ios folder found — nothing to remove.")

# Step 2: Ensure app.json has required iOS config
if APP_JSON.exists():
    with APP_JSON.open("r+") as f:
        data = json.load(f)
        expo = data.setdefault("expo", {})
        ios = expo.get("ios", {})
        ios["bundleIdentifier"] = "com.clearsky.photo"
        ios["buildNumber"] = "1.0.0"
        expo["ios"] = ios
        f.seek(0)
        json.dump(data, f, indent=2)
        f.truncate()
    print("\u2705 Updated app.json with correct iOS build settings.")
else:
    print("\u274c Could not find react_native/app.json. Ensure you are in the repo root.")

print("\n\ud83d\ude80 Now run:\n   cd react_native && eas build -p ios --profile production")
