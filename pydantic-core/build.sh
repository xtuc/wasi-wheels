#!/bin/bash

set -eou pipefail

if [ ! -e venv ]; then
  echo 'creating venv'
  python3.11 -m venv venv
fi

. venv/bin/activate
pip install typing-extensions wheel maturin setuptools

ARCH_TRIPLET=_wasi_wasm32-wasi

export CC="${WASI_SDK_PATH}/bin/clang"
export CXX="${WASI_SDK_PATH}/bin/clang++"

export PYTHONPATH=$CROSS_PREFIX/lib/python3.11

RUSTFLAGS="${RUSTFLAGS:-} -C link-args=-L${WASI_SDK_PATH}/share/wasi-sysroot/lib/wasm32-wasi/"
RUSTFLAGS="${RUSTFLAGS} -C linker=${WASI_SDK_PATH}/bin/wasm-ld"
RUSTFLAGS="${RUSTFLAGS} -C link-self-contained=no"
RUSTFLAGS="${RUSTFLAGS} -C link-args=--experimental-pic"
RUSTFLAGS="${RUSTFLAGS} -C link-args=--shared"
RUSTFLAGS="${RUSTFLAGS} -C relocation-model=pic"
RUSTFLAGS="${RUSTFLAGS} -C linker-plugin-lto=yes"
export RUSTFLAGS="$RUSTFLAGS"

export CFLAGS="-I${CROSS_PREFIX}/include/python3.11 -D__EMSCRIPTEN__=1"
export CXXFLAGS="-I${CROSS_PREFIX}/include/python3.11"
export LDSHARED=${CC}
export AR="${WASI_SDK_PATH}/bin/ar"
export RANLIB=true
export LDFLAGS="-flto=full -g -Wl,--stack-first -Wl,--import-memory -Wl,-shared -Wl,--import-table -Wl,--unresolved-symbols=import-dynamic"
export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata_${ARCH_TRIPLET}
export CARGO_BUILD_TARGET=wasm32-wasi
cd src
rm -rf build
mkdir build
maturin build --release --target wasm32-wasi --out dist -i python3.11 -vvv
wheel unpack --dest build dist/*.whl 
