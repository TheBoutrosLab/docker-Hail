ARG MINIFORGE_VERSION=26.1.1-2
ARG UBUNTU_VERSION=24.04
ARG CONDA_ENV_PATH=/opt/conda/envs/hail

FROM condaforge/miniforge3:${MINIFORGE_VERSION} AS builder

ARG CONDA_ENV_PATH
ARG HAIL_VERSION=0.2.139
ARG PYTHON_VERSION=3.10
ARG OPENJDK_VERSION=11

RUN mamba create -qy -p ${CONDA_ENV_PATH} \
    -c conda-forge \
    openjdk=${OPENJDK_VERSION} \
    pip \
    python=${PYTHON_VERSION} && \
    ${CONDA_ENV_PATH}/bin/pip install --no-cache-dir "hail==${HAIL_VERSION}" && \
    mamba clean -afy

FROM ubuntu:${UBUNTU_VERSION} AS final

ARG CONDA_ENV_PATH

COPY --from=builder ${CONDA_ENV_PATH} ${CONDA_ENV_PATH}

ENV CONDA_ENV_PATH="${CONDA_ENV_PATH}" \
    PATH="${CONDA_ENV_PATH}/bin:${PATH}" \
    NSS_WRAPPER_PASSWD=/tmp/passwd \
    NSS_WRAPPER_GROUP=/tmp/group

RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss-wrapper \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/bldocker && \
    chmod 777 /tmp/bldocker && \
    printf '%s\n' \
    '#!/bin/bash' \
    'echo "bldocker:x:$(id -u):$(id -g):Custom User:/tmp/bldocker:/bin/bash" > "${NSS_WRAPPER_PASSWD}"' \
    'echo "bldocker:x:$(id -g):" > "${NSS_WRAPPER_GROUP}"' \
    'export LD_PRELOAD=libnss_wrapper.so' \
    'exec "$@"' \
    > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

RUN groupadd -g 500001 bldocker && \
    useradd -m -r -u 500001 -g bldocker bldocker

USER bldocker

LABEL maintainer="Yash Patel <ypatel@sbpdiscovery.org>" \
      org.opencontainers.image.source=https://github.com/TheBoutrosLab/docker-Hail \
      org.opencontainers.image.description="Dockerfile for Hail"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]
