import json
from pathlib import Path

# Determine repo root and app.json path
ROOT = Path(__file__).resolve().parent.parent
APP_JSON = ROOT / "react_native" / "app.json"

# Load existing app.json
with APP_JSON.open('r+', encoding='utf-8') as f:
    data = json.load(f)
    expo = data.setdefault('expo', {})

    # Increment Expo version (patch only)
    version = expo.get('version', '0.0.0')
    parts = version.split('.')
    if len(parts) < 3:
        parts += ['0'] * (3 - len(parts))
    major, minor, patch = [int(p) for p in parts[:3]]
    patch += 1
    new_version = f"{major}.{minor}.{patch}"
    expo['version'] = new_version

    # Increment iOS build number
    ios = expo.setdefault('ios', {})
    build_str = ios.get('buildNumber', '0')
    try:
        build_num = int(build_str)
    except ValueError:
        # Fall back to numeric last segment if not purely numeric
        try:
            build_num = int(str(build_str).split('.')[-1])
        except Exception:
            build_num = 0
    build_num += 1
    ios['buildNumber'] = str(build_num)
    expo['ios'] = ios

    # Write changes back to file
    f.seek(0)
    json.dump(data, f, indent=2)
    f.truncate()

print(f"✅ Bumped to version {new_version} (iOS build {build_num})")

