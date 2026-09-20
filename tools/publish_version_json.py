import os
import re
import json
import datetime
import subprocess

def main():
    pubspec_path = 'pubspec.yaml'
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()

    match = re.search(r'version:\s*([0-9\.]+)\+([0-9]+)', content)
    if not match:
        print("Error: Could not find version in pubspec.yaml")
        return

    version = match.group(1)
    build_number = int(match.group(2))
    today = datetime.date.today().isoformat()

    version_data = {
        "latest_version": version,
        "latest_build_number": build_number,
        "min_required_version": version,
        "min_required_build_number": build_number,
        "force_update": True,
        "release_date": today,
        "title": f"Pembaruan Resmi v{version} Tersedia! 🐼🚀",
        "title_en": f"Official Update v{version} Available! 🐼🚀",
        "message": f"Pembaruan v{version} telah dirilis dan siap dipasang langsung di dalam aplikasi.",
        "message_en": f"Version v{version} is available and ready to update directly inside the app.",
        "apk_download_url": "https://github.com/tomztansen/nihao_kids/releases/latest/download/app-release.apk",
        "web_download_page": "https://tomztansen.github.io/nihao_kids/download.html"
    }

    # Write root version.json
    with open('version.json', 'w', encoding='utf-8') as f:
        json.dump(version_data, f, indent=2)
        f.write('\n')

    # Write preview/version.json
    os.makedirs('preview', exist_ok=True)
    with open(os.path.join('preview', 'version.json'), 'w', encoding='utf-8') as f:
        json.dump(version_data, f, indent=2)
        f.write('\n')

    print(f"✅ Generated version.json for v{version}+{build_number}")

    # Commit and push via git
    subprocess.run(['git', 'config', 'user.name', 'github-actions[bot]'], check=True)
    subprocess.run(['git', 'config', 'user.email', 'github-actions[bot]@users.noreply.github.com'], check=True)
    subprocess.run(['git', 'add', 'version.json', 'preview/version.json'], check=True)

    status = subprocess.run(['git', 'diff', '--staged', '--quiet'])
    if status.returncode != 0:
        subprocess.run(['git', 'commit', '-m', f"chore(release): publish version.json v{version}+{build_number} [skip ci]"], check=True)
        subprocess.run(['git', 'push', 'origin', 'main'], check=True)
        print("✅ Committed and pushed version.json to main!")
    else:
        print("ℹ️ No changes in version.json.")

if __name__ == '__main__':
    main()
