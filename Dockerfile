FROM ubuntu:noble AS compilers

ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    TZ=Etc/UTC

ARG GCC_VERSION=15.2.0 \
    BINUTILS_VERSION=2.42 \
    GBLIC_VERSION=2.39

RUN set -ex ;\
    apt update ;\
    apt upgrade -y ;\
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        curl ca-certificates tzdata build-essential gcc-multilib \
        file flex bison texinfo libc6-dev-i386 debootstrap \
    ;\
    cd /tmp ;\
    curl -fL https://ftpmirror.gnu.org/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz -o gcc.tar.xz ;\
    curl -fL https://ftpmirror.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz -o binutils.tar.xz

# RUN set -ex ;\
#     mkdir -p /usr/src/gcc/build ;\
#     tar -xf /tmp/gcc.tar.xz -C /usr/src/gcc --strip-components=1 ;\
#     cd /usr/src/gcc ;\
#     ./contrib/download_prerequisites ;\
#     cd build ;\
#     ../configure \
#         --build=x86_64-linux-gnu \
#         --prefix=/opt/x86_64-linux-gnu \
#         --with-glibc-version=$GBLIC_VERSION \
#         --enable-multilib \
#         --enable-languages=c,c++ \
#         --with-gcc-major-version-only \
#         --disable-nls \
#         --disable-bootstrap \
#         --enable-default-pie \
#         --enable-default-ssp \
#     ;\
#     make -j$(nproc) ;\
#     make install-strip ;\
#     update-alternatives --install /usr/bin/gcc gcc /opt/x86_64-linux-gnu/bin/x86_64-linux-gnu-gcc 100 ;\
#     update-alternatives --install /usr/bin/g++ g++ /opt/x86_64-linux-gnu/bin/x86_64-linux-gnu-g++ 100

RUN set -ex ;\
    debootstrap --include libc6-dev --arch arm64 --variant minbase --no-check-gpg noble /opt/arm64-sysroot ;\
    mkdir -p /usr/src/binutils/build ;\
    tar -xf /tmp/binutils.tar.xz -C /usr/src/binutils --strip-components=1 ;\
    cd /usr/src/binutils/build ;\
    ../configure \
        --target=aarch64-linux-gnu \
        --prefix=/opt/aarch64-linux-gnu \
        --with-sysroot=/opt/arm64-sysroot \
        --disable-nls \
        --enable-gprofng=no \
        --disable-werror \
        --enable-new-dtags \
        --enable-default-hash-style=gnu \
    ;\
    make -j$(nproc) ;\
    make install-strip ;\
    rm -rf /usr/src/gcc ;\
    mkdir -p /usr/src/gcc/build ;\
    tar -xf /tmp/gcc.tar.xz -C /usr/src/gcc --strip-components=1 ;\
    cd /usr/src/gcc ;\
    ./contrib/download_prerequisites ;\
    cd build ;\
    ../configure \
        --target=aarch64-linux-gnu \
        --prefix=/opt/aarch64-linux-gnu \
        --with-sysroot=/opt/arm64-sysroot \
        --with-glibc-version=$GBLIC_VERSION \
        --disable-multilib \
        --enable-languages=c,c++ \
        --with-gcc-major-version-only \
        --disable-nls \
        --disable-bootstrap \
        --enable-default-pie \
        --enable-default-ssp \
    ;\
    make -j$(nproc) ;\
    make install-strip

RUN set -ex ;\
    debootstrap --include libc6-dev --arch armhf --variant minbase --no-check-gpg noble /opt/armhf-sysroot ;\
    rm -rf /usr/src/binutils ;\
    mkdir -p /usr/src/binutils/build ;\
    tar -xf /tmp/binutils.tar.xz -C /usr/src/binutils --strip-components=1 ;\
    cd /usr/src/binutils/build ;\
    ../configure \
        --target=arm-linux-gnueabihf \
        --prefix=/opt/arm-linux-gnueabihf \
        --with-sysroot=/opt/armhf-sysroot \
        --disable-nls \
        --enable-gprofng=no \
        --disable-werror \
        --enable-new-dtags \
        --enable-default-hash-style=gnu \
    ;\
    make -j$(nproc) ;\
    make install-strip ;\
    rm -rf /usr/src/gcc ;\
    mkdir -p /usr/src/gcc/build ;\
    tar -xf /tmp/gcc.tar.xz -C /usr/src/gcc --strip-components=1 ;\
    cd /usr/src/gcc ;\
    ./contrib/download_prerequisites ;\
    cd build ;\
    ../configure \
        --target=arm-linux-gnueabihf \
        --prefix=/opt/arm-linux-gnueabihf \
        --with-sysroot=/opt/armhf-sysroot \
        --with-glibc-version=$GBLIC_VERSION \
        --disable-multilib \
        --enable-languages=c,c++ \
        --with-gcc-major-version-only \
        --disable-nls \
        --disable-bootstrap \
        --enable-default-pie \
        --enable-default-ssp \
        --with-arch=armv7-a+fp \
        --with-float=hard \
        --with-mode=thumb \
    ;\
    make -j$(nproc) ;\
    make install-strip

FROM ubuntu:noble

COPY --from=compilers /opt/x86_64-linux-gnu /opt/x86_64-linux-gnu
COPY --from=compilers /opt/aarch64-linux-gnu /opt/aarch64-linux-gnu
COPY --from=compilers /opt/arm-linux-gnueabihf /opt/arm-linux-gnueabihf

ENTRYPOINT ["/bin/bash"]
