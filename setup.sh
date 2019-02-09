
git clone https://github.com/facebook/xcbuild.git xcbuild-src \
  && cd xcbuild-src \
  && git submodule sync \
  && git submodule update --init \
  && cd .. \
  && mkdir xcbuild-build \
  && cd xcbuild-build \
  && cmake -DCMAKE_INSTALL_PREFIX=/opt/xcbuild -DCMAKE_BUILD_TYPE=Release ../xcbuild-src \
  && make -j$(nproc) \
  && make -j$(nproc) install \
  && cd .. \
  && rm -rf xcbuild-build xcbuild-src

git clone https://github.com/tpoechtrager/apple-libtapi.git \
  && cd apple-libtapi \
  && cd .. \
  && mkdir apple-libtapi-build \
  && cd apple-libtapi-build \
  && cmake -DCMAKE_INSTALL_PREFIX=/opt/cctools -DCMAKE_BUILD_TYPE=Release -DLLVM_INCLUDE_TESTS=OFF ../apple-libtapi/src/apple-llvm/src \
  && make -j$(nproc) libtapi \
  && make -j$(nproc) install-libtapi \
  && mkdir -p /opt/cctools/include \
  && cp -a ../apple-libtapi/src/apple-llvm/src/projects/libtapi/include/tapi /opt/cctools/include \
  && cp projects/libtapi/include/tapi/Version.inc /opt/cctools/include/tapi \
  && cd .. \
  && rm -rf apple-libtapi apple-libtapi-build

# -D_FORTIFY_SOURCE=0, since cctools/misc/libtool.c:2070 gets an incorrect
# guard. Alternatively, the code could be changed to use snprintf instead.
git clone https://github.com/tpoechtrager/cctools-port.git \
  && cd cctools-port \
  && cd cctools \
  && CFLAGS="-D_FORTIFY_SOURCE=0 -O3" ./configure --prefix=/opt/cctools --with-libtapi=/opt/cctools \
  && make -j$(nproc) \
  && make -j$(nproc) install \
  && cd ../.. \
  && rm -rf cctools-port

XCODE_CROSS_SRC_DIR=/opt/xcode-cross/

cd Xcode.app \
  && /opt/xcode-cross/setup-toolchain.sh /opt/cctools /opt/clang

DEVELOPER_DIR=/opt/Xcode.app
echo export DEVELOPER_DIR=/opt/Xcode.app >> ~/.bashrc

/opt/xcode-cross/setup-symlinks.sh /opt/xcode-cross $DEVELOPER_DIR /opt/cctools

# Add the Xcode toolchain to the path, but after the normal path directories,
# to allow using the host compiler as usual (for cases that require compilation
# both for host and target at the same time).
ENV PATH=/opt/xcode-cross/bin:$PATH:$DEVELOPER_DIR/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin:/opt/cctools/bin
