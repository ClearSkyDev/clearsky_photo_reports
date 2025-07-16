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
        # Comment out any Flipper-related lines entirely to avoid referencing
        # the FlipperConfiguration constant which may not be defined.
        if "FlipperConfiguration" in line or "use_flipper!" in line:
            new_lines.append("# " + line)
        else:
            new_lines.append(line)

    with podfile_path.open("w") as file:
        file.writelines(new_lines)

    print(f"\u2705 Podfile updated at {podfile_path}: Flipper has been disabled.")
