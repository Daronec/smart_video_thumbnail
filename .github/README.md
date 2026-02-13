# GitHub Actions Workflows

This directory contains automated workflows for the smart_video_thumbnail plugin.

## 🔄 Workflows

### 1. CI (`ci.yml`)

- **Trigger:** Push/PR to main or develop
- **Purpose:** Continuous integration testing
- **Actions:** Format, analyze, test, build

### 2. Create Tag (`create-tag.yml`)

- **Trigger:** Version change in pubspec.yaml
- **Purpose:** Automatically create git tags
- **Actions:** Extract version, create tag, push

### 3. Publish (`publish.yml`)

- **Trigger:** Push tag matching v*.*.\*
- **Purpose:** Publish to pub.dev and create release
- **Actions:** Test, publish, create GitHub release

## 🚀 Quick Start

1. **Setup pub.dev credentials:**

   ```bash
   dart pub token add https://pub.dev
   cat ~/.pub-cache/credentials.json
   ```

   Add to GitHub Secrets as `PUB_CREDENTIALS`

2. **Release new version:**

   ```bash
   # Update version in pubspec.yaml
   vim pubspec.yaml

   # Commit and push
   git add pubspec.yaml CHANGELOG.md
   git commit -m "Release v0.2.0"
   git push origin main
   ```

3. **Workflows run automatically:**
   - Tag created
   - Tests run
   - Published to pub.dev
   - GitHub release created

## 📖 Full Documentation

See [SETUP_INSTRUCTIONS.md](./SETUP_INSTRUCTIONS.md) for detailed setup guide.

## 🔗 Links

- [Actions Dashboard](https://github.com/Daronec/smart_video_thumbnail/actions)
- [pub.dev Package](https://pub.dev/packages/smart_video_thumbnail)
- [Releases](https://github.com/Daronec/smart_video_thumbnail/releases)
