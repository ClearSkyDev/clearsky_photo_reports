import os
from pathlib import Path

# Support running the script from either the repository root or the
# `react_native` directory by checking common Podfile locations.
PODFILE_CANDIDATES = [
    Path("react_native/ios/Podfile"),
    Path("ios/Podfile"),
]

podfile_path = next((p for p in PODFILE_CANDIDATES if p.exists()), None)

if podfile_path is None:
    print("\u274c Podfile not found. Run `npx expo prebuild --platform ios` first.")
else:
    with podfile_path.open("r") as file:
        lines = file.readlines()

    new_lines = []
    for line in lines:
        # Replace any Flipper configuration with an empty hash to fully disable
        # it while avoiding undefined constant errors.
        if "FlipperConfiguration" in line or "flipper_config" in line:
            new_lines.append("flipper_config = {}\n")
        # Comment out any call to `use_flipper!` so CocoaPods skips Flipper
        # integration entirely.
        elif "use_flipper!" in line:
            new_lines.append("# " + line)
        else:
            new_lines.append(line)

    with podfile_path.open("w") as file:
        file.writelines(new_lines)

    print(f"\u2705 Podfile updated at {podfile_path}: Flipper has been disabled.")
