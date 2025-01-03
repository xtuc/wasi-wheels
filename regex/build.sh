#!/bin/bash

set -eou pipefail

if [ ! -e venv ]; then
  python3.11 -v -m venv venv
fi

which python3
. venv/bin/activate
pip install setuptools

ARCH_TRIPLET=_wasi_wasm32-wasi

export CC="${WASI_SDK_PATH}/bin/clang"
export CXX="${WASI_SDK_PATH}/bin/clang++"

export PYTHONPATH=$CROSS_PREFIX/lib/python3.11

export CFLAGS="-I${CROSS_PREFIX}/include/python3.11 -D__EMSCRIPTEN__=1"
export CXXFLAGS="-I${CROSS_PREFIX}/include/python3.11"
export LDSHARED=${CC}
export AR="${WASI_SDK_PATH}/bin/ar"
export RANLIB=true
export LDFLAGS="-flto=full -g -Wl,--stack-first -Wl,--import-memory -Wl,-shared -Wl,--import-table -Wl,--unresolved-symbols=import-dynamic"
export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata_${ARCH_TRIPLET}
(cd src && python3 setup.py build -j 4)
