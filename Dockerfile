# Minimal VMware Security Assessment container
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Install VMware PowerCLI only
RUN pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name VMware.PowerCLI -Force -AllowClobber -Scope AllUsers"

# Create application directory
WORKDIR /app

# Copy application files
COPY . .

# Set permissions
RUN chmod +x *.ps1

# Create non-root user for security
RUN useradd -m -s /bin/bash vmware && \
    chown -R vmware:vmware /app

USER vmware

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pwsh -Command "Get-Module -ListAvailable VMware.PowerCLI | Select-Object -First 1" || exit 1

# Default command
CMD ["pwsh", "-Command", "Get-Help Start-VMwareSecurityAssessment"]

# Labels for metadata
LABEL maintainer="uldyssian-sh" \
      version="1.0.0" \
      description="VMware Security Assessment Framework" \
      org.opencontainers.image.licenses="MIT"