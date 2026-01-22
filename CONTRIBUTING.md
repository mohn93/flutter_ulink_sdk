# Contributing to Flutter ULink SDK

Thank you for your interest in contributing to the Flutter ULink SDK!

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/mohn93/flutter_ulink_sdk.git
   cd flutter_ulink_sdk
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run tests:
   ```bash
   flutter test
   ```

4. Run analysis:
   ```bash
   flutter analyze
   ```

## Code Style

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format .` before committing
- Ensure `flutter analyze` passes with no errors

## Pull Request Process

1. Create a feature branch from `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit with clear messages

3. Ensure all tests pass and code is formatted:
   ```bash
   flutter test
   flutter analyze
   dart format .
   ```

4. Push and create a pull request to `develop`

5. Wait for CI checks to pass and code review

---

## Releasing a New Version

This project uses **automated publishing** to pub.dev via GitHub Actions with OIDC authentication.

### Release Process

1. **Ensure `develop` branch is ready for release**
   - All features merged and tested
   - CI passing on develop branch

2. **Merge to `main`**
   ```bash
   git checkout main
   git pull origin main
   git merge develop
   git push origin main
   ```

3. **Create and push a version tag**
   ```bash
   # Create tag (format: v<major>.<minor>.<patch>)
   git tag v0.2.6

   # Push the tag to trigger release
   git push origin v0.2.6
   ```

4. **Monitor the release**
   - Go to [GitHub Actions](https://github.com/mohn93/flutter_ulink_sdk/actions)
   - Watch the "Release" workflow
   - The workflow will:
     1. Update `pubspec.yaml` with the version from the tag
     2. Update `CHANGELOG.md` with the new version
     3. Run tests and analysis
     4. Create a GitHub Release
     5. Publish to pub.dev using OIDC authentication

5. **Verify the release**
   - Check [pub.dev/packages/flutter_ulink_sdk](https://pub.dev/packages/flutter_ulink_sdk)
   - Check GitHub Releases page

### Version Format

Use [Semantic Versioning](https://semver.org/):
- `v0.2.6` - Patch release (bug fixes)
- `v0.3.0` - Minor release (new features, backwards compatible)
- `v1.0.0` - Major release (breaking changes)

### What the Release Workflow Does

The release workflow (`.github/workflows/release.yml`) automatically:

| Step | Description |
|------|-------------|
| Extract version | Gets version number from tag (e.g., `v0.2.6` → `0.2.6`) |
| Update pubspec.yaml | Sets the version in pubspec.yaml |
| Update CHANGELOG.md | Adds version entry if not present |
| Commit changes | Commits version updates back to main |
| Run tests | Ensures all tests pass |
| Verify package | Runs `dart pub publish --dry-run` |
| Publish to pub.dev | Uses official Dart OIDC workflow |
| Create GitHub Release | Creates release with installation instructions |

### Troubleshooting Releases

**Release workflow failed?**
1. Check the GitHub Actions logs for the error
2. Fix the issue in a new commit to `main`
3. Delete and recreate the tag:
   ```bash
   git tag -d v0.2.6
   git push origin :refs/tags/v0.2.6
   git tag v0.2.6
   git push origin v0.2.6
   ```

**pub.dev publishing failed?**
- Ensure OIDC is configured in [pub.dev admin](https://pub.dev/packages/flutter_ulink_sdk/admin)
- Repository: `mohn93/flutter_ulink_sdk`
- Tag pattern: `v{{version}}`
- Enable "publishing from push events"

### CI/CD Overview

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| CI (`.github/workflows/ci.yml`) | Push/PR to main, develop | Run tests, analysis, formatting checks |
| Release (`.github/workflows/release.yml`) | Push tag `v*` | Publish to pub.dev, create GitHub release |

---

## Questions?

Open an issue on GitHub if you have questions about contributing or the release process.
