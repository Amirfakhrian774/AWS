# Dockerfile for a Custom AWX Image

# Define arguments that can be passed during build time.
# These need to be re-declared in each stage where they are used.
ARG BASE_IMAGE=quay.io/centos/centos:stream9
ARG PYTHON_VERSION=3.11
ARG AWX_VERSION=24.5.0
# The corresponding ansible-core version for AWX 24.5.0 is 2.16.7
ARG ANSIBLE_CORE_VERSION=2.16.7


# =============================================================================
# Stage 1: Builder
# This stage fetches and builds all Python dependencies, including AWX and its requirements.
# =============================================================================
FROM ${BASE_IMAGE} AS builder

# Re-declare ARGs needed in this stage
ARG PYTHON_VERSION
ARG AWX_VERSION
ARG ANSIBLE_CORE_VERSION

# --- Environment Setup ---
ENV LANG='en_US.UTF-8' \
    LC_ALL='en_US.UTF-8' \
    VENV_PATH=/opt/venv \
    PATH="/opt/venv/bin:$PATH" \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on

# --- System Dependencies (for CentOS) ---
RUN dnf install -y --nodocs git gcc gettext make python${PYTHON_VERSION} python${PYTHON_VERSION}-devel openssl-devel libffi-devel && \
    dnf clean all

# --- Python Virtual Environment ---
RUN python${PYTHON_VERSION} -m venv $VENV_PATH
RUN python${PYTHON_VERSION} -m pip install --upgrade pip setuptools wheel

# --- Fetch and Install AWX Source & Dependencies ---
WORKDIR /usr/src/awx
# This command will now work because AWX_VERSION is correctly scoped.
RUN git clone --depth 1 https://github.com/ansible/awx.git . --branch ${AWX_VERSION}
# Install AWX python requirements
RUN pip install -r requirements/requirements.txt

# --- Ansible-Core Installation ---
WORKDIR /usr/src/ansible
RUN git clone --depth 1 https://github.com/ansible/ansible.git . --branch v${ANSIBLE_CORE_VERSION}
RUN pip install -r requirements.txt
# Perform a STANDARD install to make it relocatable for the final stage.
RUN pip install .

# --- Final Sanity Check in Builder ---
RUN python -c "from ansible_base.lib import dynamic_config; print('✅ ansible_base successfully imported in builder stage.')"

# =============================================================================
# Stage 2: Final Runtime Image
# =============================================================================
FROM ${BASE_IMAGE} AS final

# Re-declare ARGs needed in this stage
ARG PYTHON_VERSION

# --- Environment Setup ---
ENV LANG='en_US.UTF-8' \
    LC_ALL='en_US.UTF-8' \
    VENV_PATH=/opt/venv \
    PATH="/opt/venv/bin:$PATH" \
    # The DJANGO_SETTINGS_MODULE should be configured via runtime environment variables
    # (e.g., in a .env file or docker run -e), not hardcoded to development.
    # We default it to production.
    DJANGO_SETTINGS_MODULE=awx.settings.production

# --- System Dependencies for Runtime (for CentOS) ---
RUN dnf install -y --nodocs gettext python${PYTHON_VERSION} findutils git && \
    dnf clean all

# --- Application Setup ---
RUN useradd -m -d /var/lib/awx -s /bin/bash awx
WORKDIR /var/lib/awx

# --- Copy Artifacts from Builder Stage ---
COPY --from=builder --chown=awx:awx ${VENV_PATH} ${VENV_PATH}
COPY --from=builder --chown=awx:awx /usr/src/awx /var/lib/awx/

USER awx

# --- Expose Port and Define Entrypoint ---
EXPOSE 8052
ENTRYPOINT ["/var/lib/awx/tools/docker-compose/entrypoint.sh"]
CMD ["awx-web"]

