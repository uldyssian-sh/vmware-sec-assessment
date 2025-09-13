# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability in this project, please report it responsibly.

### How to Report

1. **DO NOT** create a public GitHub issue for security vulnerabilities
2. Send an email to: security@example.com (replace with actual contact)
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt within 48 hours
- **Initial Assessment**: We will provide an initial assessment within 5 business days
- **Updates**: We will keep you informed of our progress
- **Resolution**: We aim to resolve critical vulnerabilities within 30 days

### Security Best Practices

When using this tool:

1. **Credentials**: Never hardcode credentials in scripts or configuration files
2. **Network Security**: Use encrypted connections (HTTPS/SSL) when possible
3. **Access Control**: Follow principle of least privilege for vCenter access
4. **Audit Logs**: Enable and monitor audit logging for assessment activities
5. **Data Handling**: Treat assessment reports as sensitive data

### Secure Configuration

#### Environment Variables
Use environment variables for sensitive configuration:

```powershell
$env:VCENTER_SERVER = "vcenter.example.com"
$env:VCENTER_USERNAME = "assessment-user"
# Never store passwords in environment variables in production
```

#### Configuration Files
Use secure configuration files with restricted permissions:

```json
{
  "vCenter": {
    "server": "vcenter.example.com",
    "port": 443,
    "protocol": "https"
  },
  "assessment": {
    "standards": ["CIS", "STIG"],
    "outputEncryption": true
  }
}
```

#### PowerShell Execution Policy
Set appropriate execution policy:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Known Security Considerations

1. **vCenter Permissions**: This tool requires read access to vCenter inventory
2. **Network Traffic**: Assessment generates network traffic to vCenter
3. **Report Data**: Reports may contain sensitive infrastructure information
4. **Logging**: Detailed logs may contain system information

### Security Features

- **Input Validation**: All user inputs are validated and sanitized
- **Secure Defaults**: Conservative security settings by default
- **Audit Trail**: Comprehensive logging of all assessment activities
- **Data Encryption**: Optional encryption for sensitive reports
- **Access Control**: Role-based access control integration

### Compliance

This tool is designed to help assess compliance with:

- CIS VMware vSphere Benchmarks
- DISA STIG for VMware vSphere
- NIST Cybersecurity Framework
- ISO 27001 controls

### Third-Party Dependencies

We regularly scan our dependencies for vulnerabilities:

- VMware PowerCLI (required)
- PowerShell modules (as specified in manifest)

### Security Testing

Our security testing includes:

- Static Application Security Testing (SAST)
- Dependency vulnerability scanning
- Code quality analysis
- Penetration testing (periodic)

---

**Remember**: Security is a shared responsibility. Please use this tool responsibly and in accordance with your organization's security policies.