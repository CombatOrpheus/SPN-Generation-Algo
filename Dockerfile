FROM docker.io/gnuoctave/octave:latest

ENV DEBIAN_FRONTEND=noninteractive

# Build arguments for user and group IDs to match the host user
ARG USER_NAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

# Install common development utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    make \
    procps \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Clean up any existing default user/group with conflicting UID/GID (e.g. ubuntu:1000)
# and create developer user and group matching host UID/GID
RUN if id -u ${USER_UID} >/dev/null 2>&1; then \
        existing_user=$(id -un ${USER_UID}); \
        if [ "$existing_user" != "${USER_NAME}" ]; then \
            userdel -r "$existing_user" 2>/dev/null || true; \
        fi; \
    fi && \
    if getent group ${USER_GID} >/dev/null 2>&1; then \
        existing_group=$(getent group ${USER_GID} | cut -d: -f1); \
        if [ "$existing_group" != "${USER_NAME}" ]; then \
            groupdel "$existing_group" 2>/dev/null || true; \
        fi; \
    fi && \
    if ! getent group ${USER_GID} >/dev/null 2>&1; then \
        groupadd --gid ${USER_GID} ${USER_NAME}; \
    fi && \
    if ! id -u ${USER_UID} >/dev/null 2>&1; then \
        useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USER_NAME}; \
    fi && \
    mkdir -p /home/${USER_NAME} && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} && \
    chmod 0440 /etc/sudoers.d/${USER_NAME}

RUN mkdir -p /workspace && \
    chown -R ${USER_UID}:${USER_GID} /home/${USER_NAME} /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

USER ${USER_NAME}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
