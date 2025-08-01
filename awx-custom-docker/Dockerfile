# =========================================================================
# Dockerfile for a Custom AWX Image
# Version: 5.0 (Final)
# Base: Debian 12 (Bookworm) Slim
# Author: Gemini & Amirfakhrian774
# =========================================================================

# -------------------------------------------------------------------------
# Stage 1: Base Image and System Dependencies
# -------------------------------------------------------------------------
# Start with a slim, modern Debian base image.
FROM debian:12-slim

# Set build-time arguments with defaults for easy version management.
# You can override this during the build: --build-arg AWX_VERSION=24.4.0
ARG AWX_VERSION=24.5.0

# Set environment variables for consistent behavior throughout the build.
ENV DEBIAN_FRONTEND=noninteractive \
    AWX_VERSION=${AWX_VERSION} \
    # Ensure all subsequent Python commands run inside our virtual environment.
    PATH="/opt/venv/bin:$PATH"

# Install essential system dependencies required for building and running AWX.
# This single, optimized layer includes all necessary build-time tools.
# - build-essential: For compiling C extensions (gcc, make, etc.).
# - python3-dev, python3-venv, python3-pip: For Python environment and bootstrapping.
# - libpq-dev: For compiling psycopg2 (PostgreSQL C driver).
# - libldap2-dev: For compiling python-ldap (OpenLDAP headers).
# - libsasl2-dev: For compiling python-ldap with SASL authentication support.
# - pkg-config, libxml2-dev, libxmlsec1-dev: For compiling the 'xmlsec' Python package.
# - git, curl, gettext, pwgen: Standard utilities for AWX and its setup.
RUN \
    echo "----> Installing System Dependencies..." && \
    # Enable contrib and non-free repositories for broader package availability if needed.
    sed -i 's/ main/ main contrib non-free/g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        gettext \
        libpq-dev \
        postgresql-client \
        pwgen \
        python3-dev \
        python3-venv \
        python3-pip \
        libldap2-dev \
        libsasl2-dev \
        pkg-config \
        libxml2-dev \
        libxmlsec1-dev \
    && \
    # Clean up apt caches to reduce image size.
    echo "----> Cleaning up apt cache..." && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------------------------
# Stage 2: Robust Python Virtual Environment Setup
# -------------------------------------------------------------------------
# This section creates a Python virtual environment with a guaranteed latest pip.
# This avoids issues with outdated pip versions from the base OS.

# Create and switch to a temporary directory for downloading pip wheels.
WORKDIR /tmp/pip_wheels

# Use the system's python3-pip to download the latest wheels for pip, setuptools, and wheel.
RUN echo "----> Downloading latest pip, setuptools, and wheel..." && \
    python3 -m pip download --no-cache-dir "pip" "setuptools" "wheel"

# Create the virtual environment. --copies ensures it works well in containers.
# --upgrade-deps automatically installs the latest pip/setuptools from the wheels
# in the current directory, which we just downloaded.
RUN echo "----> Creating Python virtual environment at /opt/venv..." && \
    python3 -m venv --copies /opt/venv --upgrade-deps

# Verify the pip version inside the venv to confirm the upgrade was successful.
RUN echo "--- Verifying pip version inside the venv ---" && \
    pip --version && \
    echo "---------------------------------------------"

# -------------------------------------------------------------------------
# Stage 3: AWX Application Setup
# -------------------------------------------------------------------------

# Switch to the directory where AWX source code will be cloned.
WORKDIR /awx_install

# Clone the specific version of the AWX repository. --depth 1 creates a shallow clone.
RUN echo "----> Cloning AWX version ${AWX_VERSION}..." && \
    git clone --depth 1 --branch ${AWX_VERSION} https://github.com/ansible/awx.git .

# Install AWX's Python dependencies into our isolated virtual environment.
# This is the step where all our previously installed dev libraries are used.
RUN echo "----> Installing AWX Python dependencies from requirements.txt..." && \
    pip install --no-cache-dir -r /awx_install/requirements/requirements.txt

# Clean up the temporary pip wheels directory to keep the final image lean.
RUN echo "----> Cleaning up temporary wheel files..." && \
    rm -rf /tmp/pip_wheels

# -------------------------------------------------------------------------
# Stage 4: User and Permissions Setup
# -------------------------------------------------------------------------
# Running as a non-root user is a critical security best practice.

# Create a dedicated, non-root user 'awx' to run the application.
RUN echo "----> Creating non-root user 'awx'..." && \
    useradd --create-home --shell /bin/bash awx

# Grant the 'awx' user ownership of the installation directory.
RUN echo "----> Setting permissions for /awx_install..." && \
    chown -R awx:awx /awx_install

# Switch the context of the Dockerfile to the 'awx' user for subsequent commands.
USER awx

# Set the working directory to the user's home directory for a clean start.
WORKDIR /home/awx

# -------------------------------------------------------------------------
# Stage 5: Final Configuration and Execution
# -------------------------------------------------------------------------

# Expose the default AWX web server port.
EXPOSE 8052

# The default command to run when the container starts.
# For now, it starts a bash shell to allow for interactive inspection and debugging.
# In a production setup, this would be replaced with the command to start the AWX service.
# Example: CMD ["/opt/venv/bin/daphne", "-b", "0.0.0.0", "-p", "8052", "awx.asgi:application"]
CMD ["bash"]
