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
  exit 1
fi

cmake -S "$OPENCV_SRC" -B "$BUILD_DIR" -G Ninja \
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

if [[ "$WITH_VULKAN" == "ON" ]] && ! grep -q '^HAVE_VULKAN=1$' "$BUILD_DIR/CMakeVars.txt"; then
  echo "Vulkan support is required but OpenCV did not enable it." >&2
  exit 1
fi

cmake --build "$BUILD_DIR" --parallel "$JOBS"
cmake --install "$BUILD_DIR"
