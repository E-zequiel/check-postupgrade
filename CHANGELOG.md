# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]
### 🚧 Pending
- Planned improvements or features not yet released.

---

## [v1.1.0] - 2025-10-01
### 🚨 Breaking Changes
- Script output and comments translated from Spanish to English (may affect users or tooling relying on the previous Spanish output format).

### ✨ Added
- Optional kernelstub check with user notification if not installed (improves portability beyond Pop!_OS).

### 🔄 Changed
- Enhanced portability to support multiple distros (Ubuntu, Debian, Arch, Fedora, etc.).
- Improved logging with clearer `[OK]` / `[FAIL]` / `[WARN]` status messages.
- Documentation (`README.md`) rewritten in English for broader accessibility.

### 📦 Archived
- Previous script version moved to `archive/check-postupgrade.v.1.0.0.sh` for reference.

...
[View release on GitHub](https://github.com/E-zequiel/check-postupgrade/releases/tag/v1.1.0)

---

## [v1.0.0] - 2025-09-XX
### ✨ Added
- Initial release of `check-postupgrade.sh` in Spanish.
- Verification of kernel parameters, initramfs contents, ESP sync, and fstab/crypttab consistency.
- Logging of results in `~/postupgrade-logs/`.

...
[View release on GitHub](https://github.com/E-zequiel/check-postupgrade/releases/tag/v1.0.0)
