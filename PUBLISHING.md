# Publishing to pub.dev

This guide explains how to publish the `smart_video_thumbnail` plugin to pub.dev.

## Prerequisites

### 1. pub.dev Account

- Create an account at [pub.dev](https://pub.dev/)
- Verify your email address
- Set up two-factor authentication (recommended)

### 2. Verified Publisher (Optional but Recommended)

Create a verified publisher for better trust:

1. Go to [pub.dev/create-publisher](https://pub.dev/create-publisher)
2. Enter your domain (e.g., `pathcreator.ru`)
3. Verify domain ownership via DNS TXT record
4. Transfer package to publisher

### 3. Tools

Install required tools:

```bash
# Dart SDK (comes with Flutter)
flutter --version

# pub tool
dart pub --version
```

## Pre-Publication Checklist

### ✅ 1. Version and Metadata

Check `pubspec.yaml`:

```yaml
name: smart_video_thumbnail
version: 0.1.0 # Follow semantic versioning
description: High-performance Flutter plugin for extracting video thumbnails...
homepage: https://github.com/Daronec/smart_video_thumbnail
repository: https://github.com/Daronec/smart_video_thumbnail
issue_tracker: https://github.com/Daronec/smart_video_thumbnail/issues
documentation: https://github.com/Daronec/smart_video_thumbnail#readme
```

### ✅ 2. Documentation

Ensure these files are complete:

- [x] `README.md` - Main documentation with examples
- [x] `CHANGELOG.md` - Version history
- [x] `LICENSE` - MIT License
- [x] `example/README.md` - Example app documentation
- [x] `pubspec.yaml` - Package metadata

### ✅ 3. Code Quality

Run analysis and tests:

```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Run tests (if any)
flutter test
```

### ✅ 4. Example App

Verify example app works:

```bash
cd example
flutter pub get
flutter build apk
flutter run
```

### ✅ 5. Assets

Ensure screenshot is included:

```
assets/
└── screenshot.jpg  # Example app screenshot
```

Update `pubspec.yaml`:

```yaml
screenshots:
  - description: "Example app showing video thumbnails in a grid layout"
    path: assets/screenshot.jpg
```

## Dry Run

Test the publication process without actually publishing:

```bash
# From plugin root directory
dart pub publish --dry-run
```

This will:

- Validate `pubspec.yaml`
- Check for required files
- Analyze code
- Show what will be published
- Report any issues

### Common Issues

**Issue:** "Package validation failed"

- **Fix:** Run `flutter analyze` and fix all issues

**Issue:** "README.md is too long"

- **Fix:** Keep README under 128KB

**Issue:** "Missing LICENSE file"

- **Fix:** Ensure LICENSE file exists in root

**Issue:** "Invalid version format"

- **Fix:** Use semantic versioning (e.g., 0.1.0, 1.0.0)

## Publishing

### Step 1: Final Checks

```bash
# Clean build
flutter clean
flutter pub get

# Verify everything works
cd example
flutter clean
flutter pub get
flutter build apk
cd ..

# Dry run
dart pub publish --dry-run
```

### Step 2: Publish

```bash
# Publish to pub.dev
dart pub publish
```

You'll be prompted to:

1. Review the package contents
2. Confirm publication
3. Authenticate via browser (first time only)

### Step 3: Verify

After publishing:

1. Visit [pub.dev/packages/smart_video_thumbnail](https://pub.dev/packages/smart_video_thumbnail)
2. Check that:
   - README displays correctly
   - Screenshot is visible
   - Example tab shows example code
   - Changelog is present
   - Score is good (aim for 130+)

## Post-Publication

### 1. Tag Release on GitHub

```bash
git tag v0.1.0
git push origin v0.1.0
```

### 2. Create GitHub Release

1. Go to [GitHub Releases](https://github.com/Daronec/smart_video_thumbnail/releases)
2. Click "Create a new release"
3. Select tag `v0.1.0`
4. Title: "v0.1.0 - Initial Release"
5. Copy content from CHANGELOG.md
6. Publish release

### 3. Update Documentation

Add pub.dev badge to README.md (already done):

```markdown
[![pub package](https://img.shields.io/pub/v/smart_video_thumbnail.svg)](https://pub.dev/packages/smart_video_thumbnail)
```

### 4. Monitor

- Check pub.dev score and address any issues
- Monitor [GitHub Issues](https://github.com/Daronec/smart_video_thumbnail/issues)
- Respond to questions and feedback

## Updating the Package

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.1.0): New features, backward compatible
- **PATCH** (0.1.1): Bug fixes, backward compatible

### Update Process

1. Make changes
2. Update version in `pubspec.yaml`
3. Update `CHANGELOG.md`
4. Test thoroughly
5. Run `dart pub publish --dry-run`
6. Publish: `dart pub publish`
7. Tag release on GitHub

### Example Update

```bash
# Update version in pubspec.yaml to 0.1.1
# Add entry to CHANGELOG.md

# Test
flutter analyze
cd example && flutter build apk && cd ..

# Publish
dart pub publish --dry-run
dart pub publish

# Tag
git tag v0.1.1
git push origin v0.1.1
```

## Troubleshooting

### Authentication Issues

If authentication fails:

```bash
# Clear pub credentials
rm ~/.pub-cache/credentials.json

# Try publishing again
dart pub publish
```

### Package Score

Improve your pub.dev score:

1. **Follow Dart conventions** - Run `dart format` and `flutter analyze`
2. **Add documentation** - Document all public APIs
3. **Add example** - Include working example app
4. **Support platforms** - Add iOS support (future)
5. **Add tests** - Write unit and integration tests
6. **Keep dependencies updated** - Regular maintenance

### Validation Errors

Common validation errors and fixes:

| Error                    | Fix                              |
| ------------------------ | -------------------------------- |
| "Invalid pubspec.yaml"   | Validate YAML syntax             |
| "Missing required field" | Add homepage, description, etc.  |
| "Invalid version"        | Use semantic versioning          |
| "Analysis errors"        | Fix all `flutter analyze` issues |
| "README too large"       | Reduce README size (<128KB)      |

## Best Practices

1. **Test Before Publishing** - Always run dry-run first
2. **Semantic Versioning** - Follow semver strictly
3. **Changelog** - Keep detailed changelog
4. **Breaking Changes** - Document clearly in CHANGELOG
5. **Deprecation** - Mark deprecated APIs with `@deprecated`
6. **Examples** - Keep examples up-to-date
7. **Documentation** - Document all public APIs
8. **Respond Quickly** - Address issues and PRs promptly

## Resources

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Package Layout Conventions](https://dart.dev/tools/pub/package-layout)
- [Semantic Versioning](https://semver.org/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Plugin Development](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)

## Support

If you encounter issues:

1. Check [pub.dev help](https://pub.dev/help)
2. Ask on [Flutter Discord](https://discord.gg/flutter)
3. Post on [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
4. Open issue on [GitHub](https://github.com/Daronec/smart_video_thumbnail/issues)

---

**Ready to publish?** Run `dart pub publish --dry-run` to get started! 🚀
