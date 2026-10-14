# Security Policy

## Reporting Security Issues

If you discover a security vulnerability in BlueShell, please report it responsibly:

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Use GitHub's private vulnerability reporting: navigate to the **Security** tab, then **Advisories**, and click **"Report a vulnerability"**
3. Or email maintainers with details including: affected versions, impact description, and if available, proof of concept

We take security seriously and will:
- Acknowledge receipt within 48 hours
- Provide updates every 7 days or when significant progress is made
- Work with you to understand and remediate the issue
- Credit you in security advisories (unless you prefer anonymity)

## Supported Versions

Security updates are applied to the current development branch (`ptyxis-port`). Users are encouraged to track the latest commits or tagged releases for security patches.

## Security Considerations

- **Rendering engine**: BlueShell uses Ghostty's rendering engine and inherits its security properties, including text rendering, graphics protocol handling, and GPU acceleration
- **Container integration**: Container support (Toolbox, Distrobox, Podman) delegates authentication and isolation to those tools' security models
- **UI interactions**: Interface design follows GNOME security guidelines and accessibility standards
- **Dependencies**: All upstream dependencies are regularly audited; refer to `build.zig.zon` for pinned versions
