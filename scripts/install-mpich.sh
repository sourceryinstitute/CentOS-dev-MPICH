#!/usr/bin/env bash

# Variables required in the parent environment:
#   MPICH_VER:      version of MPICH to fetch & build
#   PACKAGES_DIR: where to install packages
#   PKG_SRC:      staging folder for downloading and building packages
#   MPICH_PREFIX:   where to install mpich

set -o verbose
set -o pipefail
set -o errexit
set -o errtrace

# See https://reproducible-builds.org/docs/source-date-epoch/
DATE_FMT="%Y-%m-%d"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-${GIT_SDE:-}}"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date +%s)}"
export SOURCE_DATE_EPOCH
BUILD_DATE=$(date -u -d "@$SOURCE_DATE_EPOCH" "+$DATE_FMT" 2>/dev/null || date -u -r "$SOURCE_DATE_EPOCH" "+$DATE_FMT" 2>/dev/null || date -u "+$DATE_FMT")
export BUILD_DATE

echo "Build date: ${BUILD_DATE:-}"
echo "Source Date Epoch: ${SOURCE_DATE_EPOCH:-}"

: "${PACKAGES_DIR:=/opt}"
export PACKAGES_DIR
: "${PKG_SRC:=/tmp/pkg_source}"
export PKG_SRC
: "${MPICH_PREFIX:=/${PACKAGES_DIR}/mpich-${MPICH_VER}/gcc-${GCC_VER}}"
export MPICH_PREFIX
umask 0022

if ! [ -d "${PKG_SRC}" ]; then
    mkdir -p "${PKG_SRC}"
fi
if [ "X$(pwd)" != "X${PKG_SRC}" ]; then
    cd "${PKG_SRC}" || exit 1
fi

curl -L -O "http://www.mpich.org/static/downloads/${MPICH_VER}/mpich-${MPICH_VER}.tar.gz"
if sha256sum -c ./"mpich-${MPICH_VER}.tar.gz.sha256" ; then
    tar -xf "mpich-${MPICH_VER}.tar.gz" -C . && rm "mpich-${MPICH_VER}.tar.gz" \
						   ./"mpich-${MPICH_VER}.tar.gz.sha256"
    cd "${PKG_SRC}/mpich-${MPICH_VER}"
else
    echo 'MPICH package SHA256 checksum did *NOT* match expected value!' >&2
    exit 1
fi

mkdir -p "${MPICH_PREFIX}"
mkdir -p build
cd build || exit 1
../configure --prefix="${MPICH_PREFIX}" \
             --disable-dependency-tracking \
             --enable-cxx \
             --enable-shared \
	     --enable-sharedlibs=gcc \
             --enable-fast=03,ndebug \
	     --enable-debuginfo \
	     --enable-two-level-namespace \
             CC=gcc \
             CXX=g++ \
             FC=gfortran \
             F77=gfortran \
             F90='' \
             CFLAGS='' \
             CXXFLAGS='' \
             FFLAGS='' \
             FCFLAGS='' \
             F90FLAGS='' \
             F77FLAGS=''
make -j "$(nproc)"
make install -j "$(nproc)" || exit 1
cd "${PKG_SRC}" || exit 1
rm -rf "${STACK_SRC}/mpich-${MPICH_VER}" || true

cat >> /etc/skel/.bashrc <<-EOF
export PATH="${MPICH_PREFIX}/bin:\${PATH}"
EOF

cat >> /etc/ld.so.conf.d/local.conf <<-EOF
${MPICH_PREFIX}/lib64
${MPICH_PREFIX}/lib
EOF
ldconfig
