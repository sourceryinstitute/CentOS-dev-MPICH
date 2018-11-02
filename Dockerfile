# Set an empty SDE, scripts should detect and populate with
# the last commit date or current unix epoch.
ARG SOURCE_DATE_EPOCH=

# Define a image to build gcc to avoid having to
# do a bootstrap build
FROM sourceryinstitute/centos-dev-env:latest

ARG SOURCE_DATE_EPOCH

ENV PACKAGES_DIR /opt
ENV MPICH_VER 3.2.1
ENV GCC_VER ${GCC_VER:-8.2.0}
ENV MPICH_PREFIX ${PACKAGES_DIR}/mpich-${MPICH_VER}/gcc-${GCC_VER}
ENV PKG_SRC /tmp/pkg_source

WORKDIR ${PKG_SRC}

COPY ./scripts/mpich-${MPICH_VER}.tar.gz.sha256 \
     ./scripts/install-mpich.sh ./
RUN ./install-mpich.sh && rm ./install-mpich.sh
ENV PATH ${MPICH_PREFIX}/bin:${PATH}

RUN echo 'int main(){return 0;};' > smoke.c && \
    mpicc -o smoke smoke.c && \
    mpiexec -np 1 ./smoke && rm smoke smoke.c && \
    echo 'print*, "Hello"; end' > smoke.f90 && \
    mpif90 -o smoke smoke.f90 && \
    mpiexec -np 2 ./smoke && rm smoke smoke.f90

# Build-time metadata as defined at http://label-schema.org
    ARG BUILD_DATE
    ARG VCS_REF
    ARG VCS_URL
    ARG VCS_VERSION=latest
    LABEL org.label-schema.schema-version="1.0" \
          org.label-schema.build-date="$BUILD_DATE" \
          org.label-schema.version="$VCS_VERSION" \
          org.label-schema.name="centos-dev-env" \
          org.lavel-schema.source-date-epoch="$SOURCE_DATE_EPOCH" \
          org.label-schema.description="CentOS 7 base image for gcc, git, and CMake" \
          org.label-schema.url="https://github.com/sourceryinstitute/CentOS-dev-env/" \
          org.label-schema.vcs-ref="$VCS_REF" \
          org.label-schema.vcs-url="$VCS_URL" \
          org.label-schema.vendor="Sourcery Institute" \
          org.label-schema.license="MIT" \
          org.label-schema.docker.cmd="docker run -v $(pwd):/workdir -i -t sourceryinstitute/centos-dev-env:latest"
