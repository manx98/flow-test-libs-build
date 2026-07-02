#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCV_SRC="${OPENCV_SRC:-$ROOT_DIR/opencv}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build-opencv}"
INSTALL_DIR="${INSTALL_DIR:-$ROOT_DIR/dist/opencv}"
JOBS="${JOBS:-$(nproc)}"
WITH_VULKAN="${WITH_VULKAN:-ON}"

# Required by:
# - PaddleOCR-ncnn-CPP: core/imgproc/imgcodecs via opencv.hpp, imread/imwrite, geometry and image ops
# - flow-test: core/imgproc via cgo pkg-config opencv4
MODULES="${MODULES:-core,imgproc,imgcodecs}"

if [[ ! -f "$OPENCV_SRC/CMakeLists.txt" ]]; then
  echo "OpenCV source not found: $OPENCV_SRC" >&2
  echo "ROOT_DIR=$ROOT_DIR" >&2
  echo "BUILD_DIR=$BUILD_DIR" >&2
  find "$ROOT_DIR" -maxdepth 2 -name CMakeLists.txt -print >&2 || true
  exit 1
fi

printf 'OpenCV source: %s\n' "$OPENCV_SRC"
printf 'Build dir:     %s\n' "$BUILD_DIR"
printf 'Install dir:   %s\n' "$INSTALL_DIR"
printf 'Modules:       %s\n' "$MODULES"
printf 'Vulkan:        %s\n' "$WITH_VULKAN"

mkdir -p "$BUILD_DIR"
cmake_args=(
  -G Ninja
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_LIST="$MODULES" \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_ZLIB=ON \
  -DBUILD_JPEG=ON \
  -DBUILD_PNG=ON \
  -DENABLE_CCACHE=OFF \
  -DOPENCV_GENERATE_PKGCONFIG=ON \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTS=OFF \
  -DBUILD_PERF_TESTS=OFF \
  -DBUILD_opencv_apps=OFF \
  -DBUILD_opencv_gapi=OFF \
  -DBUILD_JAVA=OFF \
  -DBUILD_opencv_python2=OFF \
  -DBUILD_opencv_python3=OFF \
  -DWITH_IPP=OFF \
  -DWITH_OPENCL=OFF \
  -DWITH_ADE=OFF \
  -DWITH_AVIF=OFF \
  -DWITH_OPENEXR=OFF \
  -DWITH_OPENJPEG=OFF \
  -DWITH_JASPER=OFF \
  -DWITH_TIFF=OFF \
  -DWITH_WEBP=OFF \
  -DWITH_FFMPEG=OFF \
  -DWITH_GSTREAMER=OFF \
  -DWITH_GTK=OFF \
  -DWITH_VULKAN="$WITH_VULKAN" \
  -DWITH_V4L=OFF
)

(cd "$BUILD_DIR" && cmake "${cmake_args[@]}" "$OPENCV_SRC")

if [[ "$WITH_VULKAN" == "ON" ]] && ! grep -q '^HAVE_VULKAN=1$' "$BUILD_DIR/CMakeVars.txt"; then
  echo "Vulkan support is required but OpenCV did not enable it." >&2
  exit 1
fi

cmake --build "$BUILD_DIR" -- -j "$JOBS"
cmake --build "$BUILD_DIR" --target install
