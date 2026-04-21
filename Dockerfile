ARG MINIFORGE_VERSION=22.9.0-2
ARG UBUNTU_VERSION=24.04

FROM condaforge/mambaforge:${MINIFORGE_VERSION} AS builder

RUN mamba create -qy -p /usr/local \
    -c conda-forge \
    openjdk=11 \
    python=3.10

FROM ubuntu:${UBUNTU_VERSION} AS final
COPY --from=builder /usr/local /usr/local

# Install system dependencies including libnss-wrapper
RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss-wrapper \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
ARG HAIL_VERSION=0.2.133
RUN pip install --no-cache-dir \
    hail==${HAIL_VERSION}

# Set up environment variables and a custom home directory for libnss-wrapper
ENV NSS_WRAPPER_PASSWD=/tmp/passwd
ENV NSS_WRAPPER_GROUP=/tmp/group

RUN mkdir -p /tmp/bldocker && \
    chmod 777 /tmp/bldocker && \
    echo '#!/bin/bash\n\
        # Set up NSS Wrapper\n\
        echo "bldocker:x:$(id -u):$(id -g):Custom User:/tmp/bldocker:/bin/bash" > "$NSS_WRAPPER_PASSWD"\n\
        echo "bldocker:x:$(id -g):" > "$NSS_WRAPPER_GROUP"\n\
        \n\
        export LD_PRELOAD=libnss_wrapper.so\n\
        \n\
        exec "$@"\n' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Add a new user/group called bldocker
RUN groupadd -g 500001 bldocker && \
    useradd -r -u 500001 -g bldocker bldocker

#Change the default user to bldocker
USER bldocker

LABEL   maintainer="Yash Patel <ypatel@sbpdiscovery.org>" \
        org.opencontainers.image.source=https://github.com/uclahs-cds/docker-Hail

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]
