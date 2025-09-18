# Multi-stage build for VMware Security Assessment
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04 AS powershell-base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install VMware PowerCLI
RUN pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name VMware.PowerCLI -Force -AllowClobber"

# Python stage for additional tools
FROM python:3.11-slim AS python-base

# Install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Final stage
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Copy PowerShell modules from powershell-base
COPY --from=powershell-base /root/.local/share/powershell/Modules /root/.local/share/powershell/Modules

# Copy Python and its packages from python-base
COPY --from=python-base /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=python-base /usr/local/bin/python* /usr/local/bin/

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    ca-certificates \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Copy application files
COPY . .

# Set permissions
RUN chmod +x vmware-sec-assessment.ps1

# Create non-root user for security
RUN useradd -m -s /bin/bash vmware && \
    chown -R vmware:vmware /app

USER vmware

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pwsh -Command "Get-Module -ListAvailable VMware.PowerCLI | Select-Object -First 1" || exit 1

# Default command
CMD ["pwsh", "-File", "vmware-sec-assessment.ps1", "-Help"]

# Labels for metadata
LABEL maintainer="uldyssian-sh" \
      version="1.0.0" \
      description="VMware Security Assessment Framework" \
      org.opencontainers.image.source="https://github.com/uldyssian-sh/vmware-sec-assessment" \
      org.opencontainers.image.documentation="https://github.com/uldyssian-sh/vmware-sec-assessment/blob/main/README.md" \
      org.opencontainers.image.licenses="MIT"