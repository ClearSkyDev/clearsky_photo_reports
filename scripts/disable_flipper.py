import os

podfile_path = "ios/Podfile"

if not os.path.exists(podfile_path):
    print("\u274c Podfile not found. Run `npx expo prebuild --platform ios` first.")
else:
    with open(podfile_path, "r") as file:
        lines = file.readlines()

    new_lines = []
    for line in lines:
        if "FlipperConfiguration.enabled" in line or "FlipperConfiguration" in line:
            new_lines.append("  flipper_config = FlipperConfiguration.disabled\n")
        elif "use_flipper!" in line:
            new_lines.append("# " + line)
        else:
            new_lines.append(line)

    with open(podfile_path, "w") as file:
        file.writelines(new_lines)

    print("\u2705 Podfile updated: Flipper has been disabled.")
