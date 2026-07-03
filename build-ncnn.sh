#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NCNN_SRC="${NCNN_SRC:-$ROOT_DIR/ncnn}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build-ncnn}"
INSTALL_DIR="${INSTALL_DIR:-$ROOT_DIR/dist/ncnn}"
JOBS="${JOBS:-$(nproc)}"
WITH_VULKAN="${WITH_VULKAN:-ON}"
NCNN_SHARED_LIB="${NCNN_SHARED_LIB:-ON}"
NCNN_OPENMP="${NCNN_OPENMP:-ON}"

if [[ ! -f "$NCNN_SRC/CMakeLists.txt" ]]; then
  echo "ncnn source not found: $NCNN_SRC" >&2
  echo "ROOT_DIR=$ROOT_DIR" >&2
  echo "BUILD_DIR=$BUILD_DIR" >&2
  find "$ROOT_DIR" -maxdepth 2 -name CMakeLists.txt -print >&2 || true
  exit 1
fi

if [[ "$WITH_VULKAN" == "ON" && ! -f "$NCNN_SRC/glslang/CMakeLists.txt" ]]; then
  echo "ncnn Vulkan build requires the glslang submodule." >&2
  echo "Run: git submodule update --init --recursive ncnn" >&2
  exit 1
fi

printf 'ncnn source: %s\n' "$NCNN_SRC"
printf 'Build dir:   %s\n' "$BUILD_DIR"
printf 'Install dir: %s\n' "$INSTALL_DIR"
printf 'Vulkan:      %s\n' "$WITH_VULKAN"
printf 'Shared lib:  %s\n' "$NCNN_SHARED_LIB"
printf 'OpenMP:      %s\n' "$NCNN_OPENMP"

mkdir -p "$BUILD_DIR"
cmake_args=(
  -G Ninja
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  -DNCNN_SHARED_LIB="$NCNN_SHARED_LIB"
  -DNCNN_INSTALL_SDK=ON
  -DNCNN_VULKAN="$WITH_VULKAN"
  -DNCNN_SYSTEM_GLSLANG=OFF
  -DNCNN_OPENMP="$NCNN_OPENMP"
  -DNCNN_BUILD_TOOLS=OFF
  -DNCNN_BUILD_EXAMPLES=OFF
  -DNCNN_BUILD_BENCHMARK=OFF
  -DNCNN_BUILD_TESTS=OFF
  -DNCNN_PYTHON=OFF
)

(cd "$BUILD_DIR" && cmake "${cmake_args[@]}" "$NCNN_SRC")
cmake --build "$BUILD_DIR" -- -j "$JOBS"
cmake --build "$BUILD_DIR" --target install
