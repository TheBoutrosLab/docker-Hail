ARG MINIFORGE_VERSION=26.1.1-2
ARG UBUNTU_VERSION=24.04

FROM condaforge/miniforge3:${MINIFORGE_VERSION} AS builder

# Use mamba to install tools and dependencies into /opt/conda/envs
ARG TOOL_VERSION=X.X.X

RUN mamba create -qy -p /opt/conda/envs \
    -c bioconda \
    -c conda-forge \
    tool_name==${TOOL_VERSION}

# Deploy the target tools into a base image
FROM ubuntu:${UBUNTU_VERSION} AS final
RUN mkdir -p /opt/conda
COPY --from=builder /opt/conda/envs /opt/conda/envs
ENV PATH="/opt/conda/envs/bin:$PATH"

# Add a new user/group called bldocker
RUN groupadd -g 500001 bldocker && \
    useradd -r -u 500001 -g bldocker bldocker

# Change the default user to bldocker from root
USER bldocker

LABEL   maintainer="Your Name <YourName@sbpdiscovery.org>" \
        org.opencontainers.image.source=https://github.com/TheBoutrosLab/<REPO>
