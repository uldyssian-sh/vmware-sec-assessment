# Contributing to VMware Security Assessment Framework

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🤝 How to Contribute

### Reporting Issues

1. **Search existing issues** first to avoid duplicates
2. **Use issue templates** when available
3. **Provide detailed information**:
   - Environment details (PowerShell version, OS, VMware version)
   - Steps to reproduce
   - Expected vs actual behavior
   - Error messages and logs

### Suggesting Features

1. **Check the roadmap** in our Wiki
2. **Open a feature request** using the template
3. **Describe the use case** and business value
4. **Consider implementation complexity**

### Code Contributions

#### Prerequisites

- PowerShell 5.1 or later
- VMware PowerCLI 12.0+
- Git knowledge
- Understanding of VMware vSphere security

#### Development Setup

```powershell
# Clone the repository
git clone https://github.com/uldyssian-sh/vmware-sec-assessment.git
cd vmware-sec-assessment

# Install development dependencies
Install-Module -Name Pester -Force
Install-Module -Name PSScriptAnalyzer -Force
Install-Module -Name VMware.PowerCLI -Force

# Run tests to verify setup
.\tests\Run-Tests.ps1
```

#### Coding Standards

1. **PowerShell Best Practices**:
   - Use approved verbs for function names
   - Follow PascalCase for functions and parameters
   - Use camelCase for variables
   - Include comprehensive help documentation

2. **Code Style**:
   - 4-space indentation
   - Line length max 120 characters
   - Use meaningful variable names
   - Add comments for complex logic

3. **Function Structure**:
   ```powershell
   function Verb-Noun {
       <#
       .SYNOPSIS
           Brief description
       .DESCRIPTION
           Detailed description
       .PARAMETER ParameterName
           Parameter description
       .EXAMPLE
           Example usage
       .NOTES
           Additional notes
       #>

       [CmdletBinding()]
       param(
           [Parameter(Mandatory = $true)]
           [string]$RequiredParameter
       )

       begin {
           # Initialization
       }

       process {
           # Main logic
       }

       end {
           # Cleanup
       }
   }
   ```

#### Testing Requirements

1. **Unit Tests**: All functions must have unit tests
2. **Integration Tests**: Complex workflows need integration tests
3. **Code Coverage**: Minimum 80% code coverage
4. **PSScriptAnalyzer**: All code must pass static analysis

```powershell
# Run all tests
Invoke-Pester -Path .\tests -CodeCoverage .\src\*.ps1

# Run static analysis
Invoke-ScriptAnalyzer -Path .\src -Recurse
```

#### Pull Request Process

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Add tests** for new functionality
5. **Update documentation** if needed
6. **Run tests and linting**:
   ```powershell
   .\tests\Run-Tests.ps1
   Invoke-ScriptAnalyzer -Path . -Recurse
   ```
7. **Commit with clear messages**:
   ```bash
   git commit -m "feat: add CIS benchmark 1.2.3 check"
   ```
8. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
9. **Create pull request**

#### Commit Message Format

Use conventional commits format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

Examples:
```
feat(cis): add vCenter SSL certificate validation
fix(reports): resolve HTML report generation issue
docs(api): update function documentation
```

## 📋 Development Guidelines

### Security Considerations

1. **Never commit sensitive data**:
   - Credentials, API keys, certificates
   - Real server names or IP addresses
   - Personal information

2. **Use placeholder values**:
   ```powershell
   $VCenterServer = "vcenter.example.com"
   $Username = "<username>"
   $Password = "<password>"
   ```

3. **Validate all inputs**:
   ```powershell
   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [string]$VCenter
   ```

### Performance Guidelines

1. **Efficient PowerCLI usage**:
   - Minimize Get-View calls
   - Use bulk operations when possible
   - Implement proper error handling

2. **Memory management**:
   - Dispose of objects properly
   - Use streaming for large datasets
   - Avoid memory leaks

### Documentation Standards

1. **Function Documentation**:
   - Complete synopsis and description
   - All parameters documented
   - Multiple examples
   - Notes section with requirements

2. **Code Comments**:
   - Explain complex logic
   - Document assumptions
   - Reference standards/benchmarks

3. **README Updates**:
   - Update feature lists
   - Add new examples
   - Update compatibility matrix

## 🧪 Testing Strategy

### Test Categories

1. **Unit Tests** (`tests/unit/`):
   - Individual function testing
   - Mock external dependencies
   - Fast execution

2. **Integration Tests** (`tests/integration/`):
   - End-to-end workflows
   - Real vCenter connections (test environment)
   - Slower execution

3. **Performance Tests**:
   - Large environment testing
   - Memory usage validation
   - Execution time benchmarks

### Test Environment

For integration tests, you'll need:
- Test vCenter environment
- Test credentials (read-only recommended)
- Sample VMs and configurations

## 📚 Resources

### VMware Documentation
- [vSphere Security Guide](https://docs.vmware.com/en/VMware-vSphere/)
- [PowerCLI Documentation](https://developer.vmware.com/powercli)

### Security Standards
- [CIS VMware vSphere Benchmarks](https://www.cisecurity.org/)
- [DISA STIG for VMware](https://public.cyber.mil/stigs/)

### PowerShell Resources
- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations)
- [Pester Testing Framework](https://pester.dev/)

## 🏆 Recognition

Contributors will be recognized in:
- README.md acknowledgments
- Release notes
- Project documentation

## 📞 Getting Help

- **GitHub Discussions**: For questions and ideas
- **GitHub Issues**: For bugs and feature requests
- **Wiki**: For detailed documentation

---

**Thank you for contributing to the VMware Security Assessment Framework!**