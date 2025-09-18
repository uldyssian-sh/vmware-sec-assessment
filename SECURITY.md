# Security Policy

## Supported Versions

We actively support the following versions of VMware Security Assessment with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability in this project, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Send an email to the maintainers through GitHub's private vulnerability reporting feature
3. Include as much information as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 48 hours
- **Initial Assessment**: We will provide an initial assessment within 5 business days
- **Updates**: We will keep you informed of our progress throughout the investigation
- **Resolution**: We aim to resolve critical vulnerabilities within 30 days

### Security Best Practices

When using this tool:

1. **Credentials**: Never hardcode credentials in scripts or configuration files
2. **Network Security**: Use secure connections (HTTPS/TLS) when connecting to vCenter
3. **Access Control**: Run assessments with minimal required privileges
4. **Data Handling**: Ensure assessment reports are stored securely and access is restricted
5. **Updates**: Keep the tool and its dependencies updated to the latest versions

### Scope

This security policy applies to:
- The main VMware Security Assessment PowerShell module
- Associated scripts and configuration files
- Docker containers and deployment configurations
- CI/CD pipelines and workflows

### Out of Scope

The following are considered out of scope:
- Vulnerabilities in third-party dependencies (report to respective maintainers)
- Issues in VMware vSphere itself (report to VMware)
- Social engineering attacks
- Physical security issues

### Security Features

This project implements several security measures:

- **Input Validation**: All user inputs are validated and sanitized
- **Secure Defaults**: Default configurations follow security best practices
- **Minimal Privileges**: Operations use least-privilege principles
- **Audit Logging**: All assessment activities are logged for audit purposes
- **Encrypted Communications**: All network communications use encryption
- **Container Security**: Docker images are scanned for vulnerabilities

### Compliance

This tool is designed to help assess compliance with various security standards:
- CIS (Center for Internet Security) Benchmarks
- DISA STIG (Security Technical Implementation Guides)
- NIST Cybersecurity Framework
- Custom organizational security policies

### Contact

For security-related questions or concerns:
- Use GitHub's private vulnerability reporting feature
- Create a discussion in the GitHub repository for general security questions
- Review existing security advisories in the repository

---

**Note**: This security policy is subject to change. Please check back regularly for updates.