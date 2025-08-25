################################################################################
# Compilers
################################################################################
FROM ubuntu:noble AS compilers

ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    TZ=Etc/UTC

ARG GCC_VERSION=15.2.0

RUN set -ex ;\
    apt-get update ;\
    apt-get upgrade -y ;\
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl ca-certificates tzdata build-essential libc6-dev-i386 \
        file flex bison texinfo xz-utils zlib1g-dev libgmp-dev libmpfr-dev libmpc-dev libisl-dev libzstd-dev \
        libc6-dev-amd64-cross libc6-dev-i386-amd64-cross \
        libc6-dev-arm64-cross binutils-aarch64-linux-gnu \
        libc6-dev-armhf-cross binutils-arm-linux-gnueabihf \
    ;\
    rm -rf /tmp/* /var/lib/apt/lists/* ;\
    \
    cd /tmp ;\
    curl -fL https://ftpmirror.gnu.org/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz -o gcc.tar.xz

# Command line arguments obtained from ubuntu:questing
#   $ apt-get install -y build-essential
#   $ /usr/bin/x86_64-linux-gnu-g++ -x c++ -E -v /dev/null
#
# added:
#   --disable-bootstrap        ~ not required
# removed:
#   --with-pkgversion          ~ we dont package this
#   --with-bugurl              ~ not an official distribution
#   --program-prefix           ~ to avoid this: 'x86_64-linux-gnu-x86_64-linux-gnu-g++-15' 
#   --enable-offload-targets   ~ not supported
#   --enable-offload-defaulted ~ not supported
# modified:
#   --enable-languages         ~ only c and c++
#   --with-multilib-list       ~ removed mx32
#   --enable-nls               ~ disabled because we only want English output diagnostics
#   --with-build-config        ~ LTO is not supported
# tips:
#   ~ disable --enable-checking and --enable-libphobos-checking for test builds
#
RUN set -ex ;\
    rm -rf /src ;\
    mkdir -p /src ;\
    tar -xf /tmp/gcc.tar.xz -C /src --strip-components=1 ;\
    echo $GCC_VERSION > /src/gcc/BASE-VER ;\
    \
    rm -rf /tmp/gcc-build ;\
    mkdir -p /tmp/gcc-build/amd64 ;\
    cd /tmp/gcc-build/amd64 ;\
    /src/configure \
        --enable-languages=c,c++ \
        --prefix=/usr \
        --with-gcc-major-version-only \
        --program-suffix=-15 \
        --enable-shared \
        --enable-linker-build-id \
        --libexecdir=/usr/libexec \
        --without-included-gettext \
        --enable-threads=posix \
        --libdir=/usr/lib \
        --disable-nls \
        --disable-bootstrap \
        --enable-clocale=gnu \
        --enable-libstdcxx-debug \
        --enable-libstdcxx-time=yes \
        --with-default-libstdcxx-abi=new \
        --enable-libstdcxx-backtrace \
        --enable-gnu-unique-object \
        --disable-vtable-verify \
        --enable-plugin \
        --enable-default-pie \
        --with-system-zlib \
        --with-target-system-zlib=auto \
        --enable-objc-gc=auto \
        --enable-multiarch \
        --disable-werror \
        --enable-cet \
        --with-arch-32=i686 \
        --with-abi=m64 \
        --with-multilib-list=m32,m64 \
        --enable-multilib \
        --with-tune=generic \
        --without-cuda-driver \
        --build=x86_64-linux-gnu \
        --host=x86_64-linux-gnu \
        --target=x86_64-linux-gnu \
        --enable-link-serialization=2 \
        --with-build-config=bootstrap-lean \
        --enable-checking=release \
        --enable-libphobos-checking=release \
    ;\
    make -j$(nproc) ;\
    make install-strip DESTDIR=/opt/gcc/x86_64-linux-gnu ;\
    rm /opt/gcc/x86_64-linux-gnu/usr/bin/*-tmp ;\
    rm -rf /tmp/gcc-build

RUN set -ex ;\
    cp -r /opt/gcc/x86_64-linux-gnu/usr / ;\
    update-alternatives --install /usr/bin/gcc-ranlib                  gcc-ranlib                  /usr/bin/gcc-ranlib-15                  100 ;\
    update-alternatives --install /usr/bin/gcc-ar                      gcc-ar                      /usr/bin/gcc-ar-15                      100 ;\
    update-alternatives --install /usr/bin/gcc-nm                      gcc-nm                      /usr/bin/gcc-nm-15                      100 ;\
    update-alternatives --install /usr/bin/gcov                        gcov                        /usr/bin/gcov-15                        100 ;\
    update-alternatives --install /usr/bin/gcov-dump                   gcov-dump                   /usr/bin/gcov-dump-15                   100 ;\
    update-alternatives --install /usr/bin/gcov-tool                   gcov-tool                   /usr/bin/gcov-tool-15                   100 ;\
    update-alternatives --install /usr/bin/lto-dump                    lto-dump                    /usr/bin/lto-dump-15                    100 ;\
    update-alternatives --install /usr/bin/gcc                         gcc                         /usr/bin/x86_64-linux-gnu-gcc-15        100 ;\
    update-alternatives --install /usr/bin/g++                         g++                         /usr/bin/x86_64-linux-gnu-g++-15        100 ;\
    update-alternatives --install /usr/bin/g++                         g++                         /usr/bin/x86_64-linux-gnu-g++-15        100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-g++        x86_64-linux-gnu-g++        /usr/bin/x86_64-linux-gnu-g++-15        100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-gcc        x86_64-linux-gnu-gcc        /usr/bin/x86_64-linux-gnu-gcc-15        100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-gcc-ar     x86_64-linux-gnu-gcc-ar     /usr/bin/x86_64-linux-gnu-gcc-ar-15     100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-gcc-nm     x86_64-linux-gnu-gcc-nm     /usr/bin/x86_64-linux-gnu-gcc-nm-15     100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-gcc-ranlib x86_64-linux-gnu-gcc-ranlib /usr/bin/x86_64-linux-gnu-gcc-ranlib-15 100

# Command line arguments obtained from ubuntu:questing
#   $ apt-get install -y g++-aarch64-linux-gnu
#   $ /usr/bin/aarch64-linux-gnu-g++ -x c++ -E -v /dev/null
#
# added:
#   --disable-bootstrap  ~ not required
# removed:
#   --with-pkgversion    ~ we dont package this
#   --with-bugurl        ~ not an official distribution
# modified:
#   --enable-languages   ~ only c and c++
#   --enable-nls         ~ disabled because we only want English output diagnostics
#   --with-build-config  ~ LTO is not supported
# tips:
#   ~ disable --enable-checking and --enable-libphobos-checking for test builds
#
RUN set -ex ;\
    rm -rf /src ;\
    mkdir -p /src ;\
    tar -xf /tmp/gcc.tar.xz -C /src --strip-components=1 ;\
    echo $GCC_VERSION > /src/gcc/BASE-VER ;\
    \
    rm -rf /tmp/gcc-build ;\
    mkdir -p /tmp/gcc-build/arm64 ;\
    cd /tmp/gcc-build/arm64 ;\
    /src/configure \
        --enable-languages=c,c++ \
        --prefix=/usr \
        --with-gcc-major-version-only \
        --program-suffix=-15 \
        --enable-shared \
        --enable-linker-build-id \
        --libexecdir=/usr/libexec \
        --without-included-gettext \
        --enable-threads=posix \
        --libdir=/usr/lib \
        --disable-nls \
        --disable-bootstrap \
        --with-sysroot=/ \
        --enable-clocale=gnu \
        --enable-libstdcxx-debug \
        --enable-libstdcxx-time=yes \
        --with-default-libstdcxx-abi=new \
        --enable-libstdcxx-backtrace \
        --enable-gnu-unique-object \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --enable-plugin \
        --enable-default-pie \
        --with-system-zlib \
        --without-target-system-zlib \
        --enable-multiarch \
        --enable-fix-cortex-a53-843419 \
        --disable-werror \
        --build=x86_64-linux-gnu \
        --host=x86_64-linux-gnu \
        --target=aarch64-linux-gnu \
        --program-prefix=aarch64-linux-gnu- \
        --includedir=/usr/aarch64-linux-gnu/include \
        --enable-link-serialization=2 \
        --with-build-config=bootstrap-lean \
        --enable-checking=release \
        --enable-libphobos-checking=release \
    ;\
    make -j$(nproc) ;\
    make install-strip DESTDIR=/opt/gcc/aarch64-linux-gnu ;\
    rm -rf /tmp/gcc-build

# Command line arguments obtained from ubuntu:questing
#   $ apt-get install -y g++-arm-linux-gnueabihf
#   $ /usr/bin/arm-linux-gnueabihf-g++ -x c++ -E -v /dev/null
#
# added:
#   --disable-bootstrap  ~ not required
# removed:
#   --with-pkgversion    ~ we dont package this
#   --with-bugurl        ~ not an official distribution
# modified:
#   --enable-languages   ~ only c and c++
#   --enable-nls         ~ disabled because we only want English output diagnostics
#   --with-build-config  ~ LTO is not supported
# tips:
#   ~ disable --enable-checking and --enable-libphobos-checking for test builds
#
RUN set -ex ;\
    rm -rf /src ;\
    mkdir -p /src ;\
    tar -xf /tmp/gcc.tar.xz -C /src --strip-components=1 ;\
    echo $GCC_VERSION > /src/gcc/BASE-VER ;\
    \
    rm -rf /tmp/gcc-build ;\
    mkdir -p /tmp/gcc-build/armhf ;\
    cd /tmp/gcc-build/armhf ;\
    /src/configure \
        --enable-languages=c,c++ \
        --prefix=/usr \
        --with-gcc-major-version-only \
        --program-suffix=-15 \
        --enable-shared \
        --enable-linker-build-id \
        --libexecdir=/usr/libexec \
        --without-included-gettext \
        --enable-threads=posix \
        --libdir=/usr/lib \
        --disable-nls \
        --disable-bootstrap \
        --with-sysroot=/ \
        --enable-clocale=gnu \
        --enable-libstdcxx-debug \
        --enable-libstdcxx-time=yes \
        --with-default-libstdcxx-abi=new \
        --enable-libstdcxx-backtrace \
        --enable-gnu-unique-object \
        --disable-libitm \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --enable-plugin \
        --enable-default-pie \
        --with-system-zlib \
        --without-target-system-zlib \
        --enable-multiarch \
        --disable-sjlj-exceptions \
        --with-arch=armv7-a+fp \
        --with-float=hard \
        --with-mode=thumb \
        --disable-werror \
        --build=x86_64-linux-gnu \
        --host=x86_64-linux-gnu \
        --target=arm-linux-gnueabihf \
        --program-prefix=arm-linux-gnueabihf- \
        --includedir=/usr/arm-linux-gnueabihf/include \
        --enable-link-serialization=2 \
        --with-build-config=bootstrap-lean \
        --enable-checking=release \
        --enable-libphobos-checking=release \
    ;\
    make -j$(nproc) ;\
    make install-strip DESTDIR=/opt/gcc/arm-linux-gnueabihf ;\
    rm -rf /tmp/gcc-build

################################################################################
# Output
################################################################################
FROM ubuntu:noble

ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8

RUN set -ex ;\
    apt-get update ;\
    apt-get upgrade -y ;\
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        zlib1g-dev libgmp-dev libmpfr-dev libmpc-dev libisl-dev libzstd-dev \
        libc6-dev libc6-dev-i386 libc6-dev-arm64-cross libc6-dev-armhf-cross \
        binutils binutils-aarch64-linux-gnu binutils-arm-linux-gnueabihf \
    ;\
    rm -rf /tmp/* /var/lib/apt/lists/*

COPY --from=compilers /opt/gcc/arm-linux-gnueabihf /opt/gcc/aarch64-linux-gnu /opt/gcc/x86_64-linux-gnu /

RUN set -ex ;\
    update-alternatives --install /usr/bin/gcc-ranlib                  gcc-ranlib                  /usr/bin/gcc-ranlib-15                  100 ;\
    update-alternatives --install /usr/bin/gcc-ar                      gcc-ar                      /usr/bin/gcc-ar-15                      100 ;\
    update-alternatives --install /usr/bin/gcc-nm                      gcc-nm                      /usr/bin/gcc-nm-15                      100 ;\
    update-alternatives --install /usr/bin/gcov                        gcov                        /usr/bin/gcov-15                        100 ;\
    update-alternatives --install /usr/bin/gcov-dump                   gcov-dump                   /usr/bin/gcov-dump-15                   100 ;\
    update-alternatives --install /usr/bin/gcov-tool                   gcov-tool                   /usr/bin/gcov-tool-15                   100 ;\
    update-alternatives --install /usr/bin/lto-dump                    lto-dump                    /usr/bin/lto-dump-15                    100 ;\
    update-alternatives --install /usr/bin/gcc                         gcc                         /usr/bin/x86_64-linux-gnu-gcc-15        100 ;\
    update-alternatives --install /usr/bin/g++                         g++                         /usr/bin/x86_64-linux-gnu-g++-15        100 ;\
    update-alternatives --install /usr/bin/g++                         g++                         /usr/bin/x86_64-linux-gnu-g++-15        100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-g++        x86_64-linux-gnu-g++        /usr/bin/x86_64-linux-gnu-g++-15        100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-gcc        x86_64-linux-gnu-gcc        /usr/bin/x86_64-linux-gnu-gcc-15        100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-gcc-ar     x86_64-linux-gnu-gcc-ar     /usr/bin/x86_64-linux-gnu-gcc-ar-15     100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-gcc-nm     x86_64-linux-gnu-gcc-nm     /usr/bin/x86_64-linux-gnu-gcc-nm-15     100 ;\
    update-alternatives --install /usr/bin/x86_64-linux-gnu-gcc-ranlib x86_64-linux-gnu-gcc-ranlib /usr/bin/x86_64-linux-gnu-gcc-ranlib-15 100

ENTRYPOINT ["/bin/bash"]
