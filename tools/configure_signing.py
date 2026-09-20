import os
import sys

def configure_signing():
    gradle_path = os.path.join('android', 'app', 'build.gradle')
    if not os.path.exists(gradle_path):
        print(f"Error: {gradle_path} not found.")
        sys.exit(1)

    with open(gradle_path, 'r', encoding='utf-8') as f:
        content = f.read()

    signing_block = """
    signingConfigs {
        release {
            keyAlias 'nihaokids'
            keyPassword 'nihaokids2026'
            storeFile file('../upload-keystore.jks')
            storePassword 'nihaokids2026'
        }
    }
"""

    if 'signingConfigs {' in content:
        # If signingConfigs already exists, inject release inside or before
        if 'release {' not in content:
            content = content.replace('signingConfigs {', signing_block)
    else:
        content = content.replace('buildTypes {', signing_block + '\n    buildTypes {')

    # Ensure release build uses signingConfigs.release
    content = content.replace('signingConfig = signingConfigs.debug', 'signingConfig = signingConfigs.release')
    content = content.replace('signingConfig signingConfigs.debug', 'signingConfig = signingConfigs.release')

    with open(gradle_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("✅ Successfully configured release signing in android/app/build.gradle!")

if __name__ == '__main__':
    configure_signing()
