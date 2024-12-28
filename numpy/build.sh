#!/bin/bash

set -eou pipefail

ARCH_TRIPLET=_wasi_wasm32-wasi

if [ ! -e venv ]; then
  python3.11 -m venv venv
fi

. venv/bin/activate

export CC="${WASI_SDK_PATH}/bin/clang"
export CXX="${WASI_SDK_PATH}/bin/clang++"

export PYTHONPATH=$CROSS_PREFIX/lib/python3.11

export CFLAGS="-I${CROSS_PREFIX}/include/python3.11 -D__EMSCRIPTEN__=1 -DNPY_NO_SIGNAL -fPIC"
export CXXFLAGS="-I${CROSS_PREFIX}/include/python3.11"
export LDSHARED=${CC}
export AR="${WASI_SDK_PATH}/bin/ar"
export RANLIB=true
export LDFLAGS="-flto=full -g -Wl,--stack-first -Wl,--import-memory -Wl,-shared -Wl,--import-table -Wl,--unresolved-symbols=import-dynamic -Wl,--no-entry -nostdlib -L${WASI_SDK_PATH}/lib/clang/19/lib/wasip1/ -lclang_rt.builtins-wasm32"
export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata_${ARCH_TRIPLET}
export NPY_DISABLE_SVML=1
export NPY_BLAS_ORDER=
export NPY_LAPACK_ORDER=

pip install cython setuptools
(cd src && python3.11 setup.py build --disable-optimization -j$(nproc))

cp -a src/build/lib.*/numpy build/
